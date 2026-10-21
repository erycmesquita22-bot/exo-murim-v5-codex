extends RefCounted
const Stable = preload("res://npc_system03/core/stable.gd")
const MIN_ADULT_AGE := 18
const FORMS := ["feminino", "masculino"]
const APPEARANCE_KEYS := ["race", "robe", "hair", "skin", "style", "voice"]

static func preview(person: Dictionary, seed_text: String) -> Dictionary:
	var uid: String = str(person.get("id", ""))
	if uid.is_empty() or not uid.begins_with("npc/r") or int(person.get("generation_version", 1)) != 1:
		return {"status":"BLOCKED", "reason":"unknown_legacy_identity"}
	var current_value: Variant = person.get("appearance", {})
	if not current_value is Dictionary:
		return {"status":"BLOCKED", "reason":"appearance_invalid"}
	var current: Dictionary = current_value
	for key in APPEARANCE_KEYS:
		if not current.get(key) is int:
			return {"status":"BLOCKED", "reason":"appearance_schema_invalid"}
	var morphology: String = str(person.get("body_presentation", ""))
	if morphology not in FORMS:
		morphology = FORMS[Stable.choose(seed_text, uid, "presentation", FORMS.size())]
	var hair_variant: int = Stable.choose(seed_text, uid, "hair_03", 6)
	var garment_variant: int = Stable.choose(seed_text, uid, "garment_03", 6)
	var face_variant: int = Stable.choose(seed_text, uid, "face_03", 4)
	var adult: bool = confirmed_adult(person)
	return {"status":"PROPOSED", "npc_id":uid, "body_presentation":morphology,
		"hair_variant":hair_variant, "garment_variant":garment_variant,
		"face_variant":face_variant, "adult_confirmed":adult,
		"body_preset":"slim" if morphology == "feminino" else "classic",
		"visual_r2_preserve":true,"generation_version_preserve":1,
		"owner":"appearance", "committed":false,
		"preview_asset":"res://npc_system03/visuals/feminine_voxel.gd" if morphology == "feminino" else ""}

static func confirmed_adult(person: Dictionary) -> bool:
	if person.has("age") and person.get("age") is int:
		return int(person.age) >= MIN_ADULT_AGE
	return str(person.get("life_stage", "")) in ["adulto", "idoso"]
