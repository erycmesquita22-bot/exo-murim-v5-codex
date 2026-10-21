extends RefCounted
## Exo Items R3 exposes describe(item). We consume only description; inventory owner controls items.
static func good_from_description(item: Dictionary) -> String:
    var family: String = str(item.get("family", "")).to_lower()
    var material: String = str(item.get("material_id", "")).to_lower()
    if family in ["ore", "mineral", "material"] and material == "iron": return "iron"
    if family in ["ore", "mineral", "material"] and material == "copper": return "copper_ore"
    if family in ["wood", "material"] and material == "bamboo": return "bamboo"
    if family in ["wood", "material"] and material == "timber": return "timber"
    if family in ["herb", "herbal"]: return "herbs"
    # Never price weapons using an assumed Exo Items schema or automatically transfer them.
    return ""

static func readonly_preview(description: Dictionary) -> Dictionary:
    var good_id: String = good_from_description(description)
    if good_id.is_empty(): return {"ok": false, "reason": "unmapped_item_description", "good_id": ""}
    return {"ok": true, "good_id": good_id, "owner": "exo_items", "can_transfer": false}
