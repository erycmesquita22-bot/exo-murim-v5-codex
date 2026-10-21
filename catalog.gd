extends RefCounted
# Immutable source catalogue; importable data is separate from execution.
static var WEAPONS: Array=read_table("weapons")
static var RACES: Array=read_table("races")
static var SKILLS: Array=read_table("skills")
static var PASSIVES: Array=read_table("passives")
static var ELEMENTS: Array=read_table("elements")
static var COLORS: Array=read_table("colors")
static var HEROES: Array=read_table("heroes")

static func read_table(id: String) -> Array:
	var parsed: Variant=JSON.parse_string(FileAccess.get_file_as_string("res://data/"+id+".json"))
	assert(parsed is Array,"Invalid catalogue: "+id)
	if id=="skills":
		var extra:Variant=JSON.parse_string(FileAccess.get_file_as_string("res://convergence4/skills_runtime.json"))
		if extra is Array:parsed.append_array(extra)
	return parsed

static func weapon(id: String) -> Dictionary:
	for item in WEAPONS:
		if item.id==id:
			return item
	return WEAPONS[0]

static func skill(id: String) -> Dictionary:
	for item in SKILLS:
		if item.id==id:
			return item
	return SKILLS[0]

static func hero_profile(index: int) -> Dictionary:
	var hero: Dictionary=HEROES[clampi(index,0,11)]
	return {"name":hero.name,"race":hero.race,"path":hero.path,"weapon":hero.weapon,"element":hero.element,"robe":[0,3,1,5,2,2,1,4,3,4,3,4][index],"hair":index%4,"skin":index%4,"style":index%3}

static func kind_name(id: String) -> String:
	return {"Todos":"Todos","cut":"Corte","projectile":"Projétil","area":"Área","root":"Imobilização","pull":"Atração","repel":"Repulsão","dash":"Investida","leap":"Salto","channel":"Canalização","shield":"Barreira","heal":"Cura","trap":"Armadilha / campo","summon":"Invocação"}.get(id,id)
