extends RefCounted
# An EXO-owned, culturally inspired romanized name pool. The prefix identifies
# occupation/status; a suffix identifies an institutional bond, never an item perk.
const Stream=preload("res://procedural/seed_stream.gd")
static var PEOPLE: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://living_world/data/people.json"))

static func _rng(seed_text: String, region_id: int, slot_id: String, purpose: String) -> RefCounted:
	return Stream.new(Stream.hash_value("EXO|LIVING|NAMES|1|%s|%d|%s|%s" % [seed_text,region_id,slot_id,purpose]))

static func generate(seed_text: String, region_id: int, slot_id: String, role: String) -> Dictionary:
	var roles: Dictionary=PEOPLE.roles
	if not roles.has(role):role="resident"
	var surname_rng: RefCounted=_rng(seed_text,region_id,slot_id,"surname")
	var given_rng: RefCounted=_rng(seed_text,region_id,slot_id,"given")
	var surname: String=str(PEOPLE.surnames[surname_rng.below(PEOPLE.surnames.size())])
	var given: String=str(PEOPLE.given_names[given_rng.below(PEOPLE.given_names.size())])
	var role_data: Dictionary=roles[role]
	var real_name: String=surname+" "+given
	var display: String=real_name
	if not str(role_data.prefix).is_empty():display=str(role_data.prefix)+" "+display
	if not str(role_data.suffix).is_empty():display+=" "+str(role_data.suffix)
	return {"name":real_name,"display_name":display,"prefix":str(role_data.prefix),"suffix":str(role_data.suffix)}
