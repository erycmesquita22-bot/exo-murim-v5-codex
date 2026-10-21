extends RefCounted
const PREFIX="res://exo_martial/data/"
static var _styles: Array=[]
static var _schools: Array=[]
static var _techniques: Array=[]
static var _methods: Array=[]
static var _weapons: Array=[]

static func parse_catalog(name: String) -> Array:
	var json: Variant=JSON.parse_string(FileAccess.get_file_as_string(PREFIX+name+".json"))
	return json if json is Array else []

static func styles() -> Array:
	if _styles.is_empty():_styles=parse_catalog("styles")
	return _styles
static func schools() -> Array:
	if _schools.is_empty():_schools=parse_catalog("schools")
	return _schools
static func techniques() -> Array:
	if _techniques.is_empty():_techniques=parse_catalog("techniques")
	return _techniques
static func methods() -> Array:
	if _methods.is_empty():_methods=parse_catalog("training_methods")
	return _methods
static func weapon_pose(weapon_id: String) -> String:
	if _weapons.is_empty():
		var records: Variant=JSON.parse_string(FileAccess.get_file_as_string("res://data/weapons.json"))
		if records is Array:_weapons=records
	for weapon in _weapons:
		if weapon is Dictionary and str(weapon.get("id",""))==weapon_id:return str(weapon.get("pose",""))
	return ""
static func by_id(records: Array,id: String) -> Dictionary:
	for value in records:
		if value is Dictionary and value.get("id")==id:return value
	return {}
static func style(id: String) -> Dictionary:return by_id(styles(),id)
static func school(id: String) -> Dictionary:return by_id(schools(),id)
static func technique(id: String) -> Dictionary:return by_id(techniques(),id)
static func method(id: String) -> Dictionary:return by_id(methods(),id)

static func valid_catalogs() -> Dictionary:
	var catalogues: Array=[styles(),schools(),techniques(),methods()]
	var seen: Dictionary={}
	for catalogue in catalogues:
		if catalogue.is_empty():return {"ok":false,"reason":"empty_catalogue"}
		for item in catalogue:
			if not item is Dictionary or not item.get("id") is String:return {"ok":false,"reason":"bad_record"}
			if seen.has(item.id):return {"ok":false,"reason":"duplicate_id:"+str(item.id)}
			seen[item.id]=true
	for school_item in schools():
		if style(str(school_item.style_id)).is_empty():return {"ok":false,"reason":"unknown_school_style"}
	for style_item in styles():
		for core_id in style_item.core_techniques:
			if technique("exo_martial.technique."+str(core_id)).is_empty():return {"ok":false,"reason":"unknown_technique"}
	for t in techniques():
		if not t.get("validated_core_id",false):return {"ok":false,"reason":"unbound_core_skill"}
		if float(t.cooldown_seconds)<0 or float(t.cooldown_seconds)>120:return {"ok":false,"reason":"bad_cooldown"}
		for cost in ["qi","stamina"]:
			if not t.resources.has(cost) or int(t.resources[cost])<0 or int(t.resources[cost])>100:return {"ok":false,"reason":"bad_cost"}
		for sid in t.style_ids:
			if style(str(sid)).is_empty():return {"ok":false,"reason":"unknown_style"}
	return {"ok":true,"styles":styles().size(),"schools":schools().size(),"techniques":techniques().size()}
