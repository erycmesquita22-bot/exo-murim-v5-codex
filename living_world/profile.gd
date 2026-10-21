extends RefCounted
# Deterministic identity extension; original Living World IDs and saves unchanged.
const Seed=preload("res://procedural/seed_stream.gd")
const TEMPERAMENTS=["prudente","sociavel","disciplinado","reservado","audacioso","ambicioso"]
const HABITS=["pontual","flexivel","matinal","noturno"]
static func _choice(seed_text: String,id: String,purpose: String,count: int) -> int:
	return Seed.new(Seed.hash_value("EXO|LivingWorldV5|%s|%s|%s"%[seed_text,id,purpose])).below(count)
static func _traits(personality: String) -> Dictionary:
	match personality:
		"prudente":return {"risk":15,"social":40,"duty":60,"curiosity":30,"ambition":35}
		"sociavel":return {"risk":40,"social":86,"duty":50,"curiosity":65,"ambition":42}
		"reservado":return {"risk":35,"social":12,"duty":65,"curiosity":35,"ambition":40}
		"audacioso":return {"risk":88,"social":55,"duty":45,"curiosity":90,"ambition":72}
		"ambicioso":return {"risk":60,"social":57,"duty":80,"curiosity":63,"ambition":92}
		_:return {"risk":42,"social":38,"duty":92,"curiosity":45,"ambition":60}
static func enrich(person: Dictionary,seed_text: String) -> bool:
	var changed:=false
	var id: String=str(person.get("id",""))
	if id.is_empty():return false
	var role: String=str(person.get("role","resident"))
	if not person.has("life_stage"):
		person["life_stage"]="idoso" if role=="master" and _choice(seed_text,id,"stage",5)==0 else "adulto" if role in ["master","guard","merchant","healer","guild_agent"] else ["jovem","adulto","adulto"][_choice(seed_text,id,"stage",3)]
		changed=true
	if not person.has("personality"):
		var preferred: String="disciplinado" if role in ["guard","disciple","master"] else "prudente" if role in ["farmer","healer"] else "sociavel" if role in ["merchant","courier"] else "reservado"
		person["personality"]=preferred if _choice(seed_text,id,"temperament",4)!=0 else TEMPERAMENTS[_choice(seed_text,id,"alt_temperament",TEMPERAMENTS.size())]
		changed=true
	if not person.has("habit"):
		person["habit"]=HABITS[_choice(seed_text,id,"habit",HABITS.size())];changed=true
	if not person.has("routine_offset"):
		person["routine_offset"]=_choice(seed_text,id,"clock",46)-22;changed=true
	if not person.has("social_cooldown_bias"):
		person["social_cooldown_bias"]=_choice(seed_text,id,"social",14);changed=true
	if not person.get("relations",null) is Array:person["relations"]=[];changed=true
	if not person.get("social_memory",null) is Dictionary:person["social_memory"]={};changed=true
	if not person.get("preferences",null) is Dictionary:
		var base: Dictionary=_traits(str(person.personality));var prefs: Dictionary={}
		for key in base:
			prefs[key]=clampi(int(base[key])+_choice(seed_text,id,"pref_"+str(key),17)-8,0,100)
		person["preferences"]=prefs;changed=true
	if int(person.get("profile_version",0))<2:person["profile_version"]=2;changed=true
	return changed
static func link_roster(people: Array) -> bool:
	var changed: bool=false
	for person in people:
		if not person.get("relations") is Array:
			person["relations"]=[];changed=true
	return changed
