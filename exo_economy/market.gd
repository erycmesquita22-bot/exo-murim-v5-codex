extends RefCounted
## Pure deterministic regional model: geographic seed + approved city sectors + short-lived story signals.
const Currency = preload("res://exo_economy/currency.gd")
const State = preload("res://exo_economy/state.gd")
static var _goods_cache: Dictionary = {}

static func goods() -> Dictionary:
    if not _goods_cache.is_empty(): return _goods_cache
    var doc: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://exo_economy/catalog/goods.json"))
    if not doc is Dictionary: return {}
    for good in doc.get("goods", []):
        if good is Dictionary and not str(good.get("id", "")).is_empty():
            _goods_cache[str(good.id)] = good.duplicate(true)
    return _goods_cache

static func valid_region(spec: Dictionary) -> bool:
    return int(spec.get("id", -1)) >= 0 and int(spec.get("id", -1)) < 88 and not str(spec.get("region_seed", "")).is_empty()

static func profile(spec: Dictionary, plan: Dictionary = {}) -> Dictionary:
    if not valid_region(spec): return {"ok": false, "reason": "invalid_worldgen_region"}
    var city_ok: bool = str(plan.get("status", "")) == "ready" and int(plan.get("region_id", -1)) == int(spec.id)
    var counts: Dictionary = {"commercial": 0, "artisan": 0, "martial": 0, "residential": 0, "mixed": 0, "institutional": 0}
    if city_ok:
        for sector in plan.get("sectors", []):
            if not sector is Dictionary: continue
            var key: String = str(sector.get("category", ""))
            if counts.has(key): counts[key] = int(counts[key]) + 1
    var commerce: int = int(counts.commercial) + int(counts.artisan) + int(counts.mixed)
    var kind: String = str(spec.get("kind", "wild"))
    var scale: String = str(spec.get("settlement_scale", "village"))
    var index: int = int(spec.id)
    var biome: String = str(spec.get("biome", "grassland"))
    var prosperity: int = 100
    if kind == "settlement":
        prosperity = 105 if scale == "city" else 98 if scale == "town" else 90
    else: prosperity = 65
    prosperity = clampi(prosperity + mini(12, commerce * 2) + mini(8, spec.get("entrances", []).size() * 2), 60, 122)
    return {"ok": true, "region_id": index, "region_seed": str(spec.region_seed), "kind": kind,
        "scale": scale, "biome": biome, "prosperity_percent": prosperity,
        "commerce_sectors": commerce, "sector_counts": counts,
        "plan_source": "city_forge_r2" if city_ok else "worldgen_r13",
        "city_plan_accepted": city_ok, "market_enabled": kind == "settlement"}

static func quote(spec: Dictionary, city_plan: Dictionary, state: Dictionary, good_id: String, side: String, quantity: int, day: int) -> Dictionary:
    var p: Dictionary = profile(spec, city_plan)
    if not bool(p.get("ok", false)): return p
    if not bool(p.market_enabled): return {"ok": false, "reason": "no_settlement_market"}
    if side not in ["buy", "sell"] or quantity < 1 or quantity > 99 or day < 0:
        return {"ok": false, "reason": "invalid_quote_request"}
    var catalog: Dictionary = goods()
    if not catalog.has(good_id): return {"ok": false, "reason": "unknown_good"}
    var good: Dictionary = catalog[good_id]
    var supply: int = 100
    if str(p.biome) in good.get("biomes", []): supply -= 16
    else: supply += 12 if not good.get("biomes", []).is_empty() else 0
    var profession: String = "commercial" if str(good.category) in ["food", "cloth"] else "artisan" if str(good.category) in ["ore", "wood", "equipment"] else "mixed"
    if int(p.sector_counts.get(profession, 0)) > 0: supply -= 7
    var shock: int = State.impact_for(state, int(p.region_id), good_id, day)
    supply = clampi(supply + shock, 75, 140)
    var prosperity: int = int(p.prosperity_percent)
    # 25% default buy/sell spread is a sink that blocks repeated two-way arbitrage.
    var side_factor: int = 75 if side == "sell" else 100
    var base: int = int(good.base_wen)
    var unit: int = maxi(1, int(round(float(base * supply * prosperity * side_factor) / 1000000.0)))
    var total: int = unit * quantity
    if total > Currency.MAX_WEN: return {"ok": false, "reason": "price_overflow"}
    return {"ok": true, "region_id": int(p.region_id), "good_id": good_id, "side": side,
        "quantity": quantity, "unit_wen": unit, "total_wen": total, "day": day,
        "supply_percent": supply, "shock_percent": shock, "profile": p.plan_source,
        "quote_fingerprint": (str(p.region_seed) + "|" + good_id + "|" + side + "|" + str(quantity) + "|" + str(day) + "|" + str(shock) + "|" + str(unit)).sha256_text()}

static func list_prices(spec: Dictionary, city_plan: Dictionary, state: Dictionary, day: int) -> Dictionary:
    var p: Dictionary = profile(spec, city_plan)
    if not bool(p.get("ok", false)): return p
    var offers: Array = []
    if p.market_enabled:
        var ids: Array = goods().keys()
        ids.sort()
        for good_id in ids:
            offers.append(quote(spec, city_plan, state, str(good_id), "buy", 1, day))
    return {"ok": true, "profile": p, "offers": offers, "day": day}
