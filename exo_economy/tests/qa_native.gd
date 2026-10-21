extends SceneTree
## Run under an isolated Godot 4.6.2 Compatibility project rooted beside exo_economy/.
const Currency = preload("res://exo_economy/currency.gd")
const State = preload("res://exo_economy/state.gd")
const Market = preload("res://exo_economy/market.gd")
const Crowd = preload("res://exo_economy/adapters/crowd_illusion_adapter.gd")
const Narrative = preload("res://exo_economy/adapters/narrative_adapter.gd")
var checks: int = 0
var failures: Array[String] = []

func check(condition: bool, description: String) -> void:
    checks += 1
    if not condition: failures.append(description)

func _initialize() -> void:
    call_deferred("run")

func run() -> void:
    var amount: Dictionary = Currency.breakdown(205047)
    check(amount.get("gold") == 2 and amount.get("liang") == 5 and amount.get("wen") == 47, "denominations")
    check(not Currency.combine(0, 100, 0).ok, "noncanonical_currency")
    check(not Currency.combine(92233720368547, 0, 0).ok, "currency_int64_overflow_rejected")
    check(State.MAX_RECEIPTS > 2048, "expanded_receipt_capacity")
    var state: Dictionary = State.fresh("seed-101")
    check(State.valid(state), "fresh_state")
    var spec: Dictionary = {"id": 78, "region_seed": "78", "kind": "settlement", "settlement_scale": "city", "biome": "rocky_highlands"}
    var city: Dictionary = {"status": "ready", "region_id": 78, "sectors": [{"category": "commercial"}, {"category": "artisan"}], "buildings": []}
    var before: Dictionary = Market.quote(spec, city, state, "iron", "buy", 1, 0)
    var sale: Dictionary = Market.quote(spec, city, state, "iron", "sell", 1, 0)
    check(before.ok and sale.ok and int(sale.total_wen) < int(before.total_wen), "no_simple_arbitrage")
    var event: Dictionary = Narrative.canonical({"id": "quest/raid78", "kind": "bandit_raid", "region_id": 78}, 0)
    check(event.ok and State.stage_event(state, event).ok, "stage_event")
    check(bool(State.stage_event(state, event).get("duplicate", false)), "idempotence")
    var future: Dictionary = Narrative.canonical({"id": "quest/future78", "kind": "mine_strike", "region_id": 78}, 10)
    check(bool(State.stage_event(state, future).get("ok", false)), "future_event_inserted")
    check(State.impact_for(state, 78, "iron", 0) == 20, "no_future_event_leak")
    check(State.impact_for(state, 78, "iron", 10) == 48, "future_event_starts_on_day")
    check(not Narrative.canonical({"id":"trade/spoof", "kind":"flood", "region_id":78}, 0).ok, "reserved_receipt_namespace")
    var crisis: Dictionary = Market.quote(spec, city, state, "iron", "buy", 1, 0)
    check(crisis.ok and int(crisis.total_wen) > int(before.total_wen), "shock_increases_price")
    var restored: Dictionary = Market.quote(spec, city, state, "iron", "buy", 1, 5)
    check(restored.total_wen == before.total_wen, "shock_expiry")
    check(not State.valid({"schema":1,"seed":"x","receipts":{},"events":{"bad":{"kind":"flood","region_id":0,"day":9,"expires_day":2,"impact":10,"good_id":"rice"}}}), "reversed_event_period_invalid")
    var zones: Array = [{"id": "market/1", "role": "merchant", "capacity": 8, "points": [[0, 1, 0], [10, 1, 0]]}]
    var adjusted: Dictionary = Crowd.adjust_zones(spec, city, state, zones, {}, 0, 12)
    check(adjusted.ok and zones[0].capacity == 8, "crowd_input_immutable")
    check(adjusted.zones[0].points == zones[0].points and adjusted.zones[0].id == zones[0].id, "preserve_crowd_navigation")
    var status: Dictionary = Market.profile({"id": 88, "region_seed": "invalid"})
    check(not status.ok, "refuse_nonexistent_region")
    for region_id in range(88):
        var local: Dictionary = spec.duplicate(true)
        local.id = region_id
        local.region_seed = str(region_id)
        for good_id in Market.goods().keys():
            var a: Dictionary = Market.quote(local, {}, state, str(good_id), "buy", 2, 0)
            var b: Dictionary = Market.quote(local, {}, state, str(good_id), "sell", 2, 0)
            check(a.ok and b.ok and a.unit_wen >= b.unit_wen and b.unit_wen >= 1, "bounded_price_%s_%s" % [region_id, good_id])
    print("ECONOMY QA checks=%d failures=%d" % [checks, failures.size()])
    for reason in failures: push_error(reason)
    quit(0 if failures.is_empty() else 1)
