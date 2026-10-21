extends RefCounted
const Catalog=preload("res://catalog.gd")
# Existing EXO techniques, connected as the first cultivation branches.
var rules: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://exo_mastery.json"))
var BRANCHES: Dictionary=rules.branches
var credits: Dictionary={}

var world: Node3D
func _init(w: Node3D) -> void:world=w
func learned(id: String) -> bool:return id in world.journey.data.learned
func known(id: String) -> bool:return id in world.journey.data.known
func rumor(id: String) -> void:
	var d: Dictionary=world.journey.data
	if id not in d.rumors and id not in d.known:
		d.rumors.append(id)
		world.message("Uma possibilidade de cultivo foi percebida • P > Personagem > Técnicas.")
func reveal(id: String) -> void:
	var d: Dictionary=world.journey.data
	if id not in d.known:d.known.append(id)
	world.message("Conhecimento registrado • P > Personagem > Técnicas.")
func practice(id: String) -> void:
	# Kept as a no-op for old callers: merely releasing a cast never awards practice.
	pass
func credit(data: Dictionary) -> void:
	if world.flow.phase!="adventure" or world.flow.lab_mode:return
	var id: String=data.get("id","")
	var token: int=int(data.get("_cast",0))
	if token<=0 or id not in world.journey.data.learned or not rules.actives.has(id):return
	if credits.has(token):return
	credits[token]=true
	if credits.size()>128:credits.erase(credits.keys()[0])
	award(id)
	if data.get("mana",0)>0 and world.has_passive("concentracao_1"):award("concentracao_1")
	if data.get("stamina",0)>0 and world.has_passive("folego_1"):award("folego_1")
func award(id: String) -> void:
	if world.flow.phase!="adventure" or world.flow.lab_mode:return
	var weight:=1000
	if world.health<=world.max_health*.25:weight+=250
	var nearby:=0
	for actor in world.enemies:
		if actor.hp>0 and actor.position.distance_to(world.player.position)<7:nearby+=1
	if nearby>=3:weight+=150
	var d: Dictionary=world.journey.data
	var fractions: Dictionary=d.get("mastery_fraction",{})
	var value: int=int(fractions.get(id,0))+weight
	d.mastery[id]=int(d.mastery.get(id,0))+int(value/1000)
	fractions[id]=value%1000
	d.mastery_fraction=fractions
func grade(id: String) -> int:
	if not rules.actives.has(id):return 0
	var r: Dictionary=rules.actives[id]
	return mini(int(r.maxMasteryRank),int(world.journey.data.mastery.get(id,0))/maxi(1,int(r.masteryStep)))
func stats(data: Dictionary) -> Dictionary:
	var adjusted: Dictionary=data.duplicate(true)
	var id: String=data.id
	if not rules.actives.has(id) or world.flow==null or world.flow.phase!="adventure":return adjusted
	var r: Dictionary=rules.actives[id]
	var rank_value:=grade(id)
	var cost_factor:=1.0-minf(.5,rank_value*float(r.costReductionPerRank))
	adjusted.mana=ceilf(data.mana*cost_factor)
	adjusted.stamina=ceilf(data.stamina*cost_factor)
	adjusted.cooldown=data.cooldown*(1.0-minf(.5,rank_value*float(r.cooldownReductionPerRank)))
	adjusted.damage=data.damage*(1.0+minf(1.0,rank_value*float(r.damageIncreasePerRank)))
	return adjusted
func eligible(id: String) -> bool:
	if not known(id):return false
	if id.begins_with("exo.sf."):
		return world.get("activation_v4")!=null and world.activation_v4.eligible_skill(id)
	if id=="percepcao_qi":return world.journey.data.meditation>=120
	if BRANCHES.has(id):
		var branch: Dictionary=BRANCHES[id]
		return learned(branch.parent) and int(world.journey.data.mastery.get(branch.parent,0))>=branch.mastery
	return true
# R9: stage an authoritative skill grant in the SAME save as the Martial ticket.
# The Core orchestrates the final commit; this owner still enforces eligibility.
func stage_martial_reveal(id:String) -> bool:
	if world.flow==null or world.flow.phase!="adventure" or id.is_empty():return false
	if not known(id):world.journey.data.known.append(id)
	return true
func stage_martial_learn(id:String) -> bool:
	if not world.can_configure() or learned(id) or not eligible(id):return false
	world.journey.data.learned.append(id)
	return true
func learn(id: String) -> bool:
	if not world.can_configure() or learned(id) or not eligible(id):return false
	world.journey.data.learned.append(id)
	if not world.save_progress():
		world.journey.data.learned.erase(id)
		return false
	return true
func visible(id: String) -> bool:
	return learned(id) or known(id) or id in world.journey.data.rumors
func trajectory() -> bool:
	return world.has_passive("percepcao_qi") or world.flow.lab_mode
