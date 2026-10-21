extends RefCounted
const Catalog=preload("res://exo_martial/styles/martial_catalog.gd")
# Safe variant descriptors: DO NOT overwrite Catalog.SKILLS or alter core combat arithmetic.
const FORMS=["leve","equilibrada","pesada"]
const EXTENSIONS=["nenhum","eco","ritmo"]
static func descriptor(world_seed: String, school_id: String, technique_id: String, version: int=1) -> Dictionary:
	var t: Dictionary=Catalog.technique(technique_id)
	if t.is_empty() or Catalog.school(school_id).is_empty():return {}
	var source: String="EXO-MARTIAL-VARIANT|%d|%s|%s|%s"%[version,world_seed,school_id,technique_id]
	var h: String=source.sha256_text()
	var first: int=h.substr(0,7).hex_to_int()
	var second: int=h.substr(7,7).hex_to_int()
	var form: String=FORMS[first%FORMS.size()]
	var variant_trait: String=EXTENSIONS[second%EXTENSIONS.size()]
	if str(t.kind) in ["heal","shield","summon"]:
		form="equilibrada";variant_trait="nenhum"
	# All proposals are clamped. These are presentation/pre-integration metadata,
	# NEVER applied to combat directly. Active coefficients remain neutral.
	var proposal: Dictionary={"leve":{"range":1.04,"speed":1.08,"intensity":0.94,"resource":0.95},"equilibrada":{"range":1.0,"speed":1.0,"intensity":1.0,"resource":1.0},"pesada":{"range":0.96,"speed":0.92,"intensity":1.08,"resource":1.08}}[form]
	return {"id":"exo_martial.variant."+h.substr(0,24),"technique_id":technique_id,"school_id":school_id,"form":form,"trait":variant_trait,"element":int(t.core_element),"version":version,"core_skill_id":t.core_skill_id,"qi":int(t.resources.qi),"stamina":int(t.resources.stamina),"cooldown":float(t.cooldown_seconds),"activation":"catalog_only","damage_multiplier":1.0,"range_multiplier":1.0,"speed_multiplier":1.0,"intensity_multiplier":1.0,"proposal_preview":proposal}
