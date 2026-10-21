extends RefCounted
## Explicit R5 bridging to the ACTUAL C3 Work inventory. No speculative item IDs.
const LegacyInventory = preload("res://inventory.gd")
const Market = preload("res://exo_economy/market.gd")
const TRADABLE = {
    "healing_tonic": {"kind":"consumable", "ref":"potion", "max_quantity":99, "shop_category":"healer"},
    "iron": {"kind":"material", "ref":"iron", "max_quantity":99, "shop_category":"smith"},
    "weapon_common": {"kind":"weapon", "ref":"sword", "max_quantity":1, "shop_category":"smith"}
}
static func mapping(good_id: String) -> Dictionary:
    if not Market.goods().has(good_id): return {"ok":false,"reason":"unknown_good"}
    if not TRADABLE.has(good_id): return {"ok":false,"reason":"no_official_inventory_id"}
    var value: Dictionary = TRADABLE[good_id].duplicate(true)
    value["ok"] = true
    value["goods_id"] = good_id
    value["inventory_id"] = str(value.kind) + "/" + str(value.ref)
    return value
static func can_trade(item: Dictionary, descriptor: Dictionary) -> bool:
    if not LegacyInventory.valid_item(item): return false
    if str(item.get("kind", "")) != str(descriptor.kind) or str(item.get("ref", "")) != str(descriptor.ref): return false
    # Only common catalogue weapons with no procedural generation are purchasable in regular shops.
    if str(descriptor.kind) == "weapon":
        return not item.has("generation") and str(item.get("rarity", "Comum")) == "Comum" and item.get("affixes", []) == []
    return true
static func count_stock(items: Array, desc: Dictionary) -> int:
    var total: int = 0
    for item in items:
        if item is Dictionary and can_trade(item, desc): total += int(item.get("qty", 0))
    return total
static func preview(save: Dictionary, intent: Dictionary, desc: Dictionary, side: String, quantity: int) -> Dictionary:
    if not save.get("items") is Array or not preload("res://exo_economy/state.gd")._integer_between(save.get("next_item"), 1, 2147483647) or not save.get("equipped") is String:
        return {"ok":false,"reason":"official_inventory_unavailable"}
    var max_quantity: int = int(desc.max_quantity)
    if quantity < 1 or quantity > max_quantity: return {"ok":false,"reason":"quantity_exceeds_item_stack"}
    var items: Array = save.items.duplicate(true)
    var next_id: int = int(save.next_item)
    if side == "buy":
        var left: int = quantity
        if str(desc.kind) != "weapon":
            for item in items:
                if item is Dictionary and can_trade(item, desc):
                    var take: int = mini(99 - int(item.qty), left)
                    item.qty += take
                    left -= take
                    if left == 0: break
        while left > 0:
            if items.size() >= LegacyInventory.CAPACITY: return {"ok":false,"reason":"inventory_full"}
            var add_qty: int = 1 if str(desc.kind) == "weapon" else mini(99, left)
            var added: Dictionary = {"uid":"item_%d" % next_id, "kind":str(desc.kind), "ref":str(desc.ref), "qty":add_qty, "rarity":"Comum", "affixes":[]}
            if not LegacyInventory.valid_item(added): return {"ok":false,"reason":"official_item_schema_rejected"}
            items.append(added)
            next_id += 1
            left -= add_qty
    elif side == "sell":
        # A concrete UID is mandatory: cannot silently sell rare/affixed items.
        var uid: String = str(intent.get("item_uid", ""))
        var found: bool = false
        for item in items:
            if not item is Dictionary or str(item.get("uid", "")) != uid: continue
            if not can_trade(item, desc): return {"ok":false,"reason":"item_not_authorized_for_sale"}
            if str(item.uid) == str(save.equipped): return {"ok":false,"reason":"equipped_item"}
            if int(item.qty) < quantity: return {"ok":false,"reason":"insufficient_items"}
            item.qty -= quantity
            if int(item.qty) == 0: items.erase(item)
            found = true
            break
        if not found: return {"ok":false,"reason":"item_uid_not_found"}
    else: return {"ok":false,"reason":"bad_trade_side"}
    return {"ok":true, "items":items, "next_item":next_id, "equipped":str(save.equipped)}
static func stage_authorized(save: Dictionary, intent: Dictionary, quote: Dictionary) -> Dictionary:
    # Only call from C3 inventory owner's trusted bound callback, never a public economy method.
    var descriptor: Dictionary = mapping(str(quote.get("good_id", "")))
    if not bool(descriptor.get("ok", false)): return descriptor
    var result: Dictionary = preview(save, intent, descriptor, str(quote.side), int(quote.quantity))
    if not bool(result.get("ok", false)): return result
    save.items = result.items
    save.next_item = result.next_item
    return {"ok":true}
