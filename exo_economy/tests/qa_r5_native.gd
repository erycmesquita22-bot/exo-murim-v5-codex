extends SceneTree
## Execute only in a disposable copy of C3 Work with Economy R5 copied into res://.
const TradeGoods = preload("res://exo_economy/trade_goods.gd")
const TradeShop = preload("res://exo_economy/trade_shop.gd")
const Currency = preload("res://exo_economy/currency.gd")
const Market = preload("res://exo_economy/market.gd")
const State = preload("res://exo_economy/state.gd")
var count: int = 0
var fails: Array[String] = []
func check(value: bool, id: String) -> void:
    count += 1
    if not value: fails.append(id)
func _initialize() -> void: call_deferred("run")
func run() -> void:
    var state: Dictionary = State.fresh("seed_r5")
    check(State.valid(state), "fresh_state")
    check(Currency.combine(1,0,0).total_wen == 100000, "currency")
    check(TradeGoods.mapping("iron").ok, "iron_inventory_id")
    check(not TradeGoods.mapping("silk").ok, "block_silk_no_item")
    var inventory: Dictionary = {"items":[{"uid":"item_1","kind":"weapon","ref":"sword","qty":1,"rarity":"Comum","affixes":[]}],"next_item":2,"equipped":"item_1"}
    var new_item: Dictionary = TradeGoods.preview(inventory,{},TradeGoods.mapping("healing_tonic"),"buy",3)
    check(new_item.ok and new_item.items.size()==2 and new_item.items[1].ref=="potion", "potion_buy")
    check(not TradeGoods.preview(inventory,{},TradeGoods.mapping("weapon_common"),"buy",99).ok,"reject_99_swords")
    check(not TradeGoods.preview(inventory,{"item_uid":"item_1"},TradeGoods.mapping("weapon_common"),"sell",1).ok,"reject_equipped_weapon")
    var region: Dictionary={"id":78,"region_seed":"seed_r78","kind":"settlement","settlement_scale":"city","biome":"rocky_highlands","entrances":[]}
    var owner: Dictionary={"authorized":true,"vendor_id":"npc/r78_demo","region_id":78,"goods":["iron"],"initial_stock":{"iron":2},"treasury_wen":3000,"reputation_percent":100}
    var request: Dictionary={"vendor_id":"npc/r78_demo","region_id":78,"good_id":"iron","side":"buy","quantity":1}
    var validated: Dictionary=TradeShop.validated_context(request,owner,78)
    check(validated.ok,"merchant_approved")
    var shop: Dictionary=TradeShop.shop_from_context(validated)
    var base: Dictionary=Market.quote(region,{},state,"iron","buy",1,0)
    var offer: Dictionary=TradeShop.quote(base,shop,request,validated)
    check(offer.ok,"finite_stock_quote")
    check(TradeShop.stage(shop,offer) and shop.stock.iron==1,"finite_stock_stage")
    var stale: Dictionary=TradeShop.quote(base,shop,request,validated)
    check(stale.ok and stale.quote_fingerprint!=offer.quote_fingerprint,"stale_quote_revision")
    check(State.valid({"schema":1,"seed":"x","events":{},"receipts":{},"shops":{"npc/test":{"region_id":78,"stock":{"iron":1},"demand":{"iron":0},"treasury_wen":100,"revision":0}}}), "shops_schema")
    for region_id in range(88):
        region.id=region_id
        for good_id in Market.goods():
            var a: Dictionary=Market.quote(region,{},state,str(good_id),"buy",1,0)
            var b: Dictionary=Market.quote(region,{},state,str(good_id),"sell",1,0)
            check(a.ok and b.ok and a.unit_wen>=b.unit_wen and a.supply_percent>=75 and a.supply_percent<=140,"bounded_market_%d_%s"%[region_id,good_id])
    print("ECONOMY R5 NATIVE checks=%d failures=%d" % [count,fails.size()])
    for fail in fails: push_error(fail)
    quit(0 if fails.is_empty() else 1)
