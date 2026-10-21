extends RefCounted
## Pure seller stock/pricing logic. Persisted state belongs to exo_economy domain, not NPC identities.
const Market = preload("res://exo_economy/market.gd")
const Goods = preload("res://exo_economy/trade_goods.gd")
const Currency = preload("res://exo_economy/currency.gd")
static func validated_context(request: Dictionary, proof: Variant, active_region: int) -> Dictionary:
    if not proof is Dictionary or proof.get("authorized") != true:
        return {"ok":false,"reason":"trusted_merchant_proof_rejected"}
    var seller: String = str(request.get("vendor_id", ""))
    if not seller.begins_with("npc/r") or seller.length() > 115 or str(proof.get("vendor_id", "")) != seller:
        return {"ok":false,"reason":"unknown_authorized_vendor"}
    if int(proof.get("region_id", -1)) != active_region or int(request.get("region_id", -2)) != active_region:
        return {"ok":false,"reason":"merchant_not_in_active_region"}
    if not proof.get("goods") is Array or not proof.get("initial_stock") is Dictionary:
        return {"ok":false,"reason":"merchant_contract_missing"}
    if not proof.get("treasury_wen") is int or not Currency.valid_amount(proof.treasury_wen):
        return {"ok":false,"reason":"invalid_merchant_treasury"}
    if not proof.get("reputation_percent", 100) is int or int(proof.get("reputation_percent", 100)) < 90 or int(proof.get("reputation_percent", 100)) > 110:
        return {"ok":false,"reason":"invalid_reputation"}
    for good in proof.goods:
        if not good is String or not Goods.mapping(str(good)).get("ok", false):
            return {"ok":false,"reason":"merchant_unbacked_good"}
    for key in proof.initial_stock:
        if key not in proof.goods or not proof.initial_stock[key] is int or int(proof.initial_stock[key]) < 0 or int(proof.initial_stock[key]) > 500:
            return {"ok":false,"reason":"invalid_merchant_stock"}
    return {"ok":true,"vendor_id":seller,"region_id":active_region,"goods":proof.goods.duplicate(true),
        "initial_stock":proof.initial_stock.duplicate(true),"treasury_wen":proof.treasury_wen,
        "reputation_percent":int(proof.get("reputation_percent",100))}
static func shop_from_context(proof: Dictionary) -> Dictionary:
    var demand: Dictionary = {}
    for key in proof.initial_stock: demand[key] = 0
    return {"region_id":int(proof.region_id),"stock":proof.initial_stock.duplicate(true),"demand":demand,
        "treasury_wen":int(proof.treasury_wen),"revision":0}
static func quote(base: Dictionary, shop: Dictionary, request: Dictionary, proof: Dictionary) -> Dictionary:
    if not bool(base.get("ok",false)): return base
    var id: String = str(base.good_id)
    if id not in proof.goods or not shop.stock.has(id): return {"ok":false,"reason":"merchant_does_not_trade_good"}
    var mapping: Dictionary = Goods.mapping(id)
    if not bool(mapping.get("ok",false)): return mapping
    var quantity: int = int(base.quantity)
    if quantity > int(mapping.max_quantity): return {"ok":false,"reason":"quantity_exceeds_item_stack"}
    var side: String = str(base.side)
    if side == "buy" and quantity > int(shop.stock[id]): return {"ok":false,"reason":"vendor_out_of_stock"}
    if side == "sell" and int(shop.stock[id]) + quantity > 500: return {"ok":false,"reason":"vendor_stock_capacity"}
    var pressure: int = clampi(int(shop.demand.get(id, 0)), -20, 20)
    var modifier: int = clampi(100 + pressure + int(proof.reputation_percent) - 100, 80, 120)
    var unit: int = maxi(1, int(round(float(base.unit_wen) * float(modifier) / 100.0)))
    if unit > Currency.MAX_WEN / quantity: return {"ok":false,"reason":"price_overflow"}
    var total: int = unit * quantity
    if side == "sell" and total > int(shop.treasury_wen): return {"ok":false,"reason":"vendor_insufficient_funds"}
    var output: Dictionary = base.duplicate(true)
    output["unit_wen"] = unit
    output["total_wen"] = total
    output["vendor_id"] = str(proof.vendor_id)
    output["vendor_revision"] = int(shop.revision)
    output["available_stock"] = int(shop.stock[id])
    output["inventory_id"] = str(mapping.inventory_id)
    output["reputation_percent"] = int(proof.reputation_percent)
    output["quote_fingerprint"] = (str(base.quote_fingerprint)+"|"+str(proof.vendor_id)+"|"+str(shop.revision)+"|"+str(modifier)+"|"+str(total)).sha256_text()
    return output
static func stage(shop: Dictionary, quote_result: Dictionary) -> bool:
    var id: String = str(quote_result.good_id)
    var quantity: int = int(quote_result.quantity)
    var total: int = int(quote_result.total_wen)
    var buy: bool = str(quote_result.side) == "buy"
    var updated: int = int(shop.stock[id]) - quantity if buy else int(shop.stock[id]) + quantity
    var treasury: int = int(shop.treasury_wen) + total if buy else int(shop.treasury_wen) - total
    if updated < 0 or updated > 500 or treasury < 0 or treasury > Currency.MAX_WEN: return false
    shop.stock[id] = updated
    shop.treasury_wen = treasury
    shop.demand[id] = clampi(int(shop.demand.get(id,0)) + (quantity if buy else -quantity), -20, 20)
    shop.revision = int(shop.revision) + 1
    return true
