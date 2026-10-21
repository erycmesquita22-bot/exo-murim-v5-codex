extends RefCounted
const Stream=preload("res://procedural/seed_stream.gd")
const GENERATION_VERSION=1
static func create(seed_value: int=-1,identity: String="") -> Dictionary:
	if seed_value<0:seed_value=Stream.hash_value(Crypto.new().generate_random_bytes(16).hex_encode())
	if identity.is_empty():identity="world_"+Crypto.new().generate_random_bytes(12).hex_encode()
	return {"schema":1,"seed":seed_value,"id":identity,"generation_version":GENERATION_VERSION,"events":{}}
static func stream(w: Dictionary,domain: String,key: String) -> RefCounted:
	return Stream.new(Stream.hash_value("%d|%d|%s|%s"%[int(w.seed),int(w.generation_version),domain,key]))
static func migrate_legacy(save: Dictionary) -> void:
	if save.has("world"):return
	var signature: String=JSON.stringify(save,"",true).sha256_text()
	save.world=create(Stream.hash_value(signature),"world_legacy_"+signature.substr(0,24))
	for drop in save.get("pending_loot",[]):save.world.events["loot/"+str(drop.source)]={"status":"pending","legacy":true}
	for id in save.get("defeated",[]):
		if not save.world.events.has("loot/"+str(id)):save.world.events["loot/"+str(id)]={"status":"collected","legacy":true}
static func valid(w: Variant) -> bool:
	if not w is Dictionary or w.get("schema")!=1 or w.get("generation_version")!=GENERATION_VERSION:return false
	if not w.get("id") is String or not w.id.begins_with("world_") or w.id.length()>96:return false
	var seed_value: Variant=w.get("seed")
	if (not seed_value is int and not seed_value is float) or not is_finite(float(seed_value)) or int(seed_value)!=seed_value or seed_value<0 or seed_value>=2147483647:return false
	if not w.get("events") is Dictionary or w.events.size()>2048:return false
	for id in w.events:
		if not id is String or id.length()>128 or not w.events[id] is Dictionary or w.events[id].get("status") not in ["pending","collected"]:return false
	return true
