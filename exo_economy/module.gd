extends RefCounted
## EXO Core C3 Work Candidate 01 service contract inspected. Native engine QA still NOT_RUN.
const Currency = preload("res://exo_economy/currency.gd")
const State = preload("res://exo_economy/state.gd")
const Market = preload("res://exo_economy/market.gd")
const WorldCity = preload("res://exo_economy/adapters/worldgen_city_adapter.gd")
const Crowd = preload("res://exo_economy/adapters/crowd_illusion_adapter.gd")
const Items = preload("res://exo_economy/adapters/items_adapter.gd")
const TradeNetwork = preload("res://exo_economy/adapters/trade_network_adapter.gd")
const TradeGoods = preload("res://exo_economy/trade_goods.gd")
const TradeShop = preload("res://exo_economy/trade_shop.gd")
const Narrative = preload("res://exo_economy/adapters/narrative_adapter.gd")
var core: RefCounted = null
var event_verifier: Callable = Callable()
var trade_verifier: Callable = Callable()
var item_stager: Callable = Callable()
var restock_verifier: Callable = Callable()
var trade_busy: bool = false
var initialized: bool = false
# BOUND ONLY inside trusted Core startup by the authoritative city owner; no public service registration.
var approved_city_provider: Callable = Callable()

func initialize(host: RefCounted) -> bool:
    if initialized or host == null: return false
    if not host.services.has_method("register_service"): return false
    if not host.world.journey.save_coordinator.register_domain("exo_economy", "exo_economy", Callable(State, "valid")):
        return false
    if not State.ensure(host.world.journey.data): return false
    var exposed: Array = ["status", "currency_format", "wallet_snapshot", "region_profile", "market_snapshot", "market_preview",
        "quote_request", "trade_links", "crowd_zones", "item_preview", "apply_market_event",
        "shop_quote", "shop_snapshot", "execute_trade", "restock_shop"]
    if not host.services.register_service("economy", "exo_economy", self, exposed, "1.5.0"): return false
    core = host
    initialized = true
    return true

func status() -> Dictionary:
    return {"module": "exo_economy", "version": "1.5.0", "initialized": initialized,
        "wallet_owner": "living_world.balances.bronze", "save_owner": "SaveCoordinator",
        "price_owner": "exo_economy", "npc_owner": "living_world", "city_owner": "worldgen/city_forge",
        "crowd_owner": "crowd_illusion", "events_write_enabled": event_verifier.is_valid(),
        "trade_write_enabled": trade_verifier.is_valid() and item_stager.is_valid(),
        "restock_write_enabled": restock_verifier.is_valid(), "catalog_goods": Market.goods().size(),
        "tradeable_goods": TradeGoods.TRADABLE.size(), "receipt_policy": "append_only_fail_closed",
        "city_plan_write_authority": approved_city_provider.is_valid(),
        "engine_qa": "NOT_RUN", "integration_mode": "read_first_fail_closed"}

func currency_format(wen: int) -> Dictionary:
    return Currency.breakdown(wen)

func wallet_snapshot() -> Dictionary:
    if not initialized: return {"ok": false, "reason": "not_initialized"}
    var living: Variant = core.world.journey.data.get("living_world", {})
    if not living is Dictionary: return {"ok": false, "reason": "living_world_unavailable"}
    var balances: Variant = living.get("balances", {})
    if not balances is Dictionary or not Currency.valid_amount(balances.get("bronze", -1)):
        return {"ok": false, "reason": "bronze_wallet_invalid"}
    var wen: int = int(balances.bronze)
    return {"ok": true, "total_wen": wen, "denominations": Currency.breakdown(wen),
        "authority": "living_world.balances.bronze", "legacy_coins_modified": false}

func _atlas_spec(region_id: int) -> Dictionary:
    if not initialized: return {}
    var atlas: Variant = core.world.get("atlas")
    if not atlas is Dictionary: return {}
    return WorldCity.region_from_atlas(atlas, region_id)

func _city_plan_for(spec: Dictionary, input_plan: Dictionary) -> Dictionary:
    return WorldCity.export_city(input_plan, spec)

func bind_approved_city_provider(callback: Callable) -> bool:
    # This privileged method is deliberately absent from the public service allowlist.
    if not initialized or approved_city_provider.is_valid() or not callback.is_valid(): return false
    approved_city_provider = callback
    return true

func _trusted_city_plan(spec: Dictionary) -> Dictionary:
    if not approved_city_provider.is_valid(): return {}
    var received: Variant = approved_city_provider.call(int(spec.get("id", -1)))
    if not received is Dictionary: return {}
    return WorldCity.export_city(received, spec)

func _day() -> int:
    if not initialized: return 0
    # R13 crowd interprets clock in 90-unit hours. Keep same convention.
    return clampi(int(floor(float(core.clock()) / 2160.0)), 0, 10000000)

func region_profile(region_id: int, city_plan: Dictionary = {}) -> Dictionary:
    var spec: Dictionary = _atlas_spec(region_id)
    if spec.is_empty(): return {"ok": false, "reason": "official_worldgen_region_unavailable"}
    return Market.profile(spec, _city_plan_for(spec, city_plan))

func market_snapshot(region_id: int, city_plan: Dictionary = {}) -> Dictionary:
    var spec: Dictionary = _atlas_spec(region_id)
    if spec.is_empty(): return {"ok": false, "reason": "official_worldgen_region_unavailable"}
    var data: Dictionary = core.world.journey.data.exo_economy
    # Explicit caller plans are informational only. Live prices need trusted ownership.
    return Market.list_prices(spec, _trusted_city_plan(spec), data, _day())

func market_preview(region_id: int, city_plan: Dictionary) -> Dictionary:
    # A simulated plan from City Forge is NOT a trusted market and cannot be traded.
    var spec: Dictionary = _atlas_spec(region_id)
    if spec.is_empty(): return {"ok": false, "reason": "official_worldgen_region_unavailable"}
    var projected: Dictionary = Market.list_prices(spec, _city_plan_for(spec, city_plan),
        core.world.journey.data.exo_economy, _day())
    projected["preview_only"] = true
    projected["trade_authorized"] = false
    return projected

func quote_request(request: Dictionary) -> Dictionary:
    if not State._integer_between(request.get("region_id", -1), 0, 87) or not State._integer_between(request.get("quantity", 0), 1, 99):
        return {"ok": false, "reason": "invalid_quote_request"}
    var region_id: int = int(request.region_id)
    var spec: Dictionary = _atlas_spec(region_id)
    if spec.is_empty(): return {"ok": false, "reason": "official_worldgen_region_unavailable"}
    # A supplied city_plan can be forged: never let it affect authoritative trading.
    return Market.quote(spec, _trusted_city_plan(spec), core.world.journey.data.exo_economy,
        str(request.get("good_id", "")), str(request.get("side", "")),
        int(request.quantity), _day())

func trade_links(region_id: int) -> Dictionary:
    if not initialized: return {"ok": false, "reason": "not_initialized"}
    var atlas: Variant = core.world.get("atlas")
    if not atlas is Dictionary: return {"ok": false, "reason": "official_worldgen_atlas_unavailable"}
    return TradeNetwork.links(atlas, region_id, core.world.journey.data.exo_economy, _day())

func crowd_zones(region_id: int, zones: Array, area_index: Dictionary = {}, time_hour: int = 12, city_plan: Dictionary = {}) -> Dictionary:
    var spec: Dictionary = _atlas_spec(region_id)
    if spec.is_empty(): return {"ok": false, "reason": "official_worldgen_region_unavailable"}
    return Crowd.adjust_zones(spec, _trusted_city_plan(spec), core.world.journey.data.exo_economy,
        zones, area_index, _day(), posmod(time_hour, 24))

func item_preview(item_description: Dictionary) -> Dictionary:
    var descriptor: Dictionary = Items.readonly_preview(item_description)
    return descriptor

func bind_event_verifier(proof: Callable) -> bool:
    if not initialized or event_verifier.is_valid() or not proof.is_valid(): return false
    event_verifier = proof
    return true

func apply_market_event(request: Dictionary) -> Dictionary:
    if not initialized or not event_verifier.is_valid(): return {"ok": false, "reason": "trusted_narrative_event_unbound"}
    var canonical: Dictionary = Narrative.canonical(request, _day())
    if not bool(canonical.get("ok", false)): return canonical
    if not bool(event_verifier.call(request, canonical)): return {"ok": false, "reason": "narrative_proof_rejected"}
    var save: RefCounted = core.world.journey
    var before: Dictionary = save.data.duplicate(true)
    State.prune_expired(save.data.exo_economy, _day())
    # Once applied, an identical event ID cannot be reapplied on the following day.
    var existing: Variant = save.data.exo_economy.events.get(str(canonical.id), null)
    if existing is Dictionary:
        if str(existing.get("kind", "")) == str(canonical.kind) and int(existing.get("region_id", -1)) == int(canonical.region_id):
            return {"ok": true, "duplicate": true, "committed": false}
        return {"ok": false, "reason": "receipt_collision"}
    var stage: Dictionary = State.stage_event(save.data.exo_economy, canonical)
    if not bool(stage.get("ok", false)): return stage
    if bool(stage.get("duplicate", false)): return {"ok": true, "duplicate": true, "committed": false}
    if not save.save_coordinator.commit(save):
        save.data = before
        return {"ok": false, "reason": "save_commit_failed"}
    return {"ok": true, "duplicate": false, "committed": true}

func bind_trade_authority(proof: Callable, stage_items: Callable) -> bool:
    if not initialized or trade_verifier.is_valid() or item_stager.is_valid(): return false
    if not proof.is_valid() or not stage_items.is_valid(): return false
    trade_verifier = proof
    item_stager = stage_items
    return true

func bind_restock_authority(verify: Callable) -> bool:
    # Privileged, not on Core service allowlist: requires actual NPC production/merchant owner.
    if not initialized or restock_verifier.is_valid() or not verify.is_valid(): return false
    restock_verifier = verify
    return true

func _trusted_shop(request: Dictionary) -> Dictionary:
    if not initialized or not trade_verifier.is_valid(): return {"ok":false,"reason":"trusted_merchant_proof_unbound"}
    if not State._integer_between(request.get("region_id", -1), 0, 87): return {"ok":false,"reason":"invalid_trade_region"}
    var region_id: int = int(request.region_id)
    if int(core.world.get("current_region")) != region_id:
        return {"ok":false,"reason":"merchant_not_in_active_region"}
    if not core.world.journey.data.get("living_world") is Dictionary:
        return {"ok":false,"reason":"living_world_unavailable"}
    var npc_list: Variant = core.world.journey.data.living_world.get("npcs", {})
    if not npc_list is Dictionary or not npc_list.has(str(request.get("vendor_id", ""))):
        return {"ok":false,"reason":"seller_not_in_official_npc_roster"}
    var proof: Variant = trade_verifier.call(request)
    return TradeShop.validated_context(request, proof, region_id)

func _shop_offer(request: Dictionary, proof: Dictionary) -> Dictionary:
    var region_id: int = int(request.region_id)
    if not State._integer_between(request.get("quantity", 0), 1, 99):
        return {"ok":false,"reason":"invalid_quantity"}
    var spec: Dictionary = _atlas_spec(region_id)
    if spec.is_empty(): return {"ok":false,"reason":"official_region_unavailable"}
    var shop: Dictionary = core.world.journey.data.exo_economy.shops.get(str(proof.vendor_id), {})
    if shop.is_empty(): shop = TradeShop.shop_from_context(proof)
    if int(shop.get("region_id", -1)) != region_id:
        return {"ok":false,"reason":"seller_region_drift"}
    var base: Dictionary = Market.quote(spec, _trusted_city_plan(spec), core.world.journey.data.exo_economy,
        str(request.get("good_id", "")), str(request.get("side", "")), int(request.quantity), _day())
    if not bool(base.get("ok", false)): return base
    return TradeShop.quote(base, shop, request, proof)

func shop_quote(request: Dictionary) -> Dictionary:
    var proof: Dictionary = _trusted_shop(request)
    if not bool(proof.get("ok", false)): return proof
    var result: Dictionary = _shop_offer(request, proof)
    if bool(result.get("ok", false)):
        result["trade_authorized"] = trade_verifier.is_valid() and item_stager.is_valid()
    return result

func shop_snapshot(vendor_id: String) -> Dictionary:
    if not initialized: return {"ok":false,"reason":"not_initialized"}
    # Pure read-only: stock already saved by merchant-approved trade; no creation.
    var state: Dictionary = core.world.journey.data.exo_economy
    if not state.shops.has(vendor_id): return {"ok":false,"reason":"shop_not_yet_authorized"}
    return {"ok":true,"shop":state.shops[vendor_id].duplicate(true),"read_only":true}

func execute_trade(intent: Dictionary) -> Dictionary:
    if trade_busy: return {"ok":false,"reason":"trade_busy"}
    trade_busy = true
    var result: Dictionary = _execute_trade_locked(intent)
    trade_busy = false
    return result

func _execute_trade_locked(intent: Dictionary) -> Dictionary:
    if not initialized or not trade_verifier.is_valid() or not item_stager.is_valid():
        return {"ok":false,"reason":"trusted_inventory_transaction_unbound"}
    var receipt: String = str(intent.get("receipt", ""))
    if receipt.is_empty() or receipt.length() > 115 or not receipt.is_valid_identifier():
        return {"ok":false,"reason":"invalid_receipt"}
    var save: RefCounted = core.world.journey
    if not State.ensure(save.data): return {"ok":false,"reason":"economy_state_invalid"}
    var receipt_key: String = "trade/" + receipt
    # An old receipt is checked *before* a mutable new quote, so legitimate retries stay idempotent.
    var canonical: Dictionary = {"receipt":receipt, "vendor_id":str(intent.get("vendor_id", "")),
        "region_id":intent.get("region_id"), "good_id":str(intent.get("good_id", "")),
        "side":str(intent.get("side", "")), "quantity":intent.get("quantity"),
        "item_uid":str(intent.get("item_uid", "")), "quote_fingerprint":str(intent.get("quote_fingerprint", ""))}
    var fingerprint: String = JSON.stringify(canonical).sha256_text()
    var receipts: Dictionary = save.data.exo_economy.receipts
    if receipts.has(receipt_key):
        if str(receipts[receipt_key]) == fingerprint: return {"ok":true,"duplicate":true,"committed":false}
        return {"ok":false,"reason":"receipt_collision"}
    if receipts.size() >= State.MAX_RECEIPTS: return {"ok":false,"reason":"receipt_limit"}
    var proof: Dictionary = _trusted_shop(intent)
    if not bool(proof.get("ok", false)): return proof
    var quote: Dictionary = _shop_offer(intent, proof)
    if not bool(quote.get("ok", false)): return quote
    if str(intent.get("quote_fingerprint", "")) != str(quote.quote_fingerprint):
        return {"ok":false,"reason":"stale_or_invalid_shop_quote"}
    var desc: Dictionary = TradeGoods.mapping(str(quote.good_id))
    if not bool(desc.get("ok", false)): return desc
    var preflight: Dictionary = TradeGoods.preview(save.data, intent, desc, str(quote.side), int(quote.quantity))
    if not bool(preflight.get("ok", false)): return preflight
    var wallet: Dictionary = wallet_snapshot()
    if not bool(wallet.get("ok", false)): return wallet
    var balance: int = int(wallet.total_wen)
    var total: int = int(quote.total_wen)
    var next_balance: int = balance - total if str(quote.side) == "buy" else balance + total
    if next_balance < 0 or next_balance > Currency.MAX_WEN:
        return {"ok":false,"reason":"insufficient_funds_or_wallet_limit"}
    var before: Dictionary = save.data.duplicate(true)
    var shop: Dictionary = save.data.exo_economy.shops.get(str(proof.vendor_id), {}).duplicate(true)
    if shop.is_empty(): shop = TradeShop.shop_from_context(proof)
    if not TradeShop.stage(shop, quote): return {"ok":false,"reason":"stock_or_treasury_limit"}
    # Authorized inventory owner's callback stages only: never writes or saves independently.
    var result: Variant = item_stager.call(save.data, intent, quote)
    if not result is Dictionary or not bool(result.get("ok", false)):
        save.data = before
        return {"ok":false,"reason":"inventory_owner_rejected_stage"}
    if save.data.get("items") != preflight.items or save.data.get("next_item") != preflight.next_item or save.data.get("equipped") != preflight.equipped:
        save.data = before
        return {"ok":false,"reason":"inventory_delta_mismatch"}
    # Any other unauthorized mutation by the callback aborts the operation.
    var expected_before: Dictionary = before.duplicate(true)
    expected_before.items = preflight.items.duplicate(true)
    expected_before.next_item = preflight.next_item
    if save.data != expected_before:
        save.data = before
        return {"ok":false,"reason":"inventory_stager_modified_unowned_fields"}
    save.data.living_world.balances.bronze = next_balance
    save.data.exo_economy.shops[str(proof.vendor_id)] = shop
    save.data.exo_economy.receipts[receipt_key] = fingerprint
    if not State.valid(save.data.exo_economy) or not save.valid(save.data) or not save.save_coordinator.commit(save):
        save.data = before
        return {"ok":false,"reason":"save_validation_or_commit_failed"}
    return {"ok":true,"duplicate":false,"committed":true,"receipt":receipt_key,
        "wallet_after":next_balance,"total_wen":total,"vendor_revision":int(shop.revision)}

func restock_shop(request: Dictionary) -> Dictionary:
    if trade_busy: return {"ok":false,"reason":"trade_busy"}
    trade_busy = true
    var result: Dictionary = _restock_locked(request)
    trade_busy = false
    return result

func _restock_locked(request: Dictionary) -> Dictionary:
    if not initialized or not restock_verifier.is_valid(): return {"ok":false,"reason":"npc_restock_authority_unbound"}
    var receipt: String = str(request.get("receipt", ""))
    if not receipt.is_valid_identifier() or receipt.length() > 115: return {"ok":false,"reason":"invalid_receipt"}
    var key: String = "restock/" + receipt
    var save: RefCounted = core.world.journey
    var fp: String = JSON.stringify(request).sha256_text()
    if save.data.exo_economy.receipts.has(key):
        if str(save.data.exo_economy.receipts[key]) == fp: return {"ok":true,"duplicate":true,"committed":false}
        return {"ok":false,"reason":"receipt_collision"}
    var verified: Variant = restock_verifier.call(request)
    if not verified is Dictionary or verified.get("authorized") != true:
        return {"ok":false,"reason":"trusted_npc_restock_proof_rejected"}
    if str(verified.get("vendor_id", "")) != str(request.get("vendor_id", "")):
        return {"ok":false,"reason":"vendor_mismatch"}
    if not State._integer_between(request.get("quantity", 0), 1, 500):
        return {"ok":false,"reason":"invalid_quantity"}
    var good_id: String = str(request.get("good_id", ""))
    var vendor: String = str(request.get("vendor_id", ""))
    if not save.data.exo_economy.shops.has(vendor): return {"ok":false,"reason":"shop_not_initialized"}
    var shop: Dictionary = save.data.exo_economy.shops[vendor]
    if not shop.stock.has(good_id) or int(shop.stock[good_id]) + int(request.quantity) > 500:
        return {"ok":false,"reason":"stock_capacity_or_unknown_good"}
    if save.data.exo_economy.receipts.size() >= State.MAX_RECEIPTS: return {"ok":false,"reason":"receipt_limit"}
    var cost: Variant = verified.get("wholesale_cost_wen", -1)
    if not State._integer_between(cost, 0, Currency.MAX_WEN) or int(shop.treasury_wen) < int(cost):
        return {"ok":false,"reason":"restock_unfunded"}
    var before: Dictionary = save.data.duplicate(true)
    shop.stock[good_id] = int(shop.stock[good_id]) + int(request.quantity)
    shop.treasury_wen = int(shop.treasury_wen) - int(cost)
    shop.revision = int(shop.revision) + 1
    save.data.exo_economy.receipts[key] = fp
    if not State.valid(save.data.exo_economy) or not save.valid(save.data) or not save.save_coordinator.commit(save):
        save.data = before
        return {"ok":false,"reason":"restock_save_failed"}
    return {"ok":true,"committed":true,"vendor_revision":int(shop.revision)}

func shutdown() -> void:
    approved_city_provider = Callable()
    event_verifier = Callable()
    trade_verifier = Callable()
    item_stager = Callable()
    restock_verifier = Callable()
    trade_busy = false
    core = null
    initialized = false

# Creator-only initialization; refuses to erase any economic progress.
func prepare_new_campaign_seed(seed: String) -> bool:
    if not initialized or core.world.flow.phase != "creator": return false
    var domain: Dictionary = core.world.journey.data.get("exo_economy", {})
    if not State.valid(domain): return false
    for key in ["receipts", "events", "shops"]:
        if not domain.get(key, {}).is_empty(): return false
    core.world.journey.data.exo_economy = State.fresh(seed)
    return true
