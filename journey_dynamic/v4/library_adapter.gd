extends RefCounted
# CONSUMER ONLY of World Library R4. Never writes the library or any save.
const Ext=preload("res://journey_dynamic/v4/extension.gd")
static func preview(world: Object,library: Object,story_id: String,context: Dictionary) -> Dictionary:
    if library==null or not is_instance_valid(library):return {"ok":false,"status":"BLOCKED","reason":"world_library_missing"}
    if not bool(library.get("is_loaded")):return {"ok":false,"status":"BLOCKED","reason":"world_library_not_loaded"}
    if not story_id.begins_with("story_arc/"):return {"ok":false,"status":"BLOCKED","reason":"invalid_story_id"}
    if world==null or not is_instance_valid(world):return {"ok":false,"status":"BLOCKED","reason":"world_missing"}
    if not world.get("atlas") is Dictionary:return {"ok":false,"status":"BLOCKED","reason":"world_atlas_missing"}
    var atlas: Dictionary=world.get("atlas")
    if str(atlas.get("seed",""))!=str(context.get("seed","")):return {"ok":false,"status":"BLOCKED","reason":"seed_mismatch"}
    if not library.has_method("query") or not library.has_method("resolve"):return {"ok":false,"status":"BLOCKED","reason":"library_interface_missing"}
    var eligible: Dictionary=library.query("story_arc",context,256)
    if not bool(eligible.get("ok",false)):return {"ok":false,"status":"BLOCKED","reason":"library_rejected_context:"+str(eligible.get("error",""))}
    var found: bool=false
    for rec in eligible.get("records",[]):
        if str(rec.get("id",""))==story_id:found=true;break
    if not found:return {"ok":false,"status":"BLOCKED","reason":"story_not_eligible"}
    var record: Dictionary=library.resolve(story_id)
    if record.is_empty():return {"ok":false,"status":"BLOCKED","reason":"story_not_found"}
    return Ext.preview(world,record,context)
