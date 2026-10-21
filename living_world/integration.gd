extends RefCounted
# Stable, read-only contract between the 88-region planner and Living World.
# Geometry and the gameplay stage/saves remain owned by their original modules.
const People=preload("res://living_world/people.gd")
const Quests=preload("res://living_world/quests.gd")

static func context_from_region(region: Dictionary,assigned_slots: Array=[]) -> Dictionary:
	var services: Array=[]
	for slot in assigned_slots:
		if not slot is Dictionary:continue
		match str(slot.get("role","")):
			"guild_agent":
				if "guild" not in services:services.append("guild")
			"healer":
				if "healer" not in services:services.append("healer")
			"master","disciple":
				if "martial_school" not in services:services.append("martial_school")
	return {"id":int(region.get("id",0)),"kind":str(region.get("kind","wild")),
		"settlement_scale":str(region.get("settlement_scale","")),
		"difficulty":clampi(int(region.get("difficulty",1)),1,6),"services":services}

static func preview(atlas: Dictionary,region_id: int,assigned_slots: Array=[],stage: int=5) -> Dictionary:
	if not atlas.has("regions") or region_id<0 or region_id>=atlas.regions.size():return {}
	var region: Dictionary=atlas.regions[region_id]
	var context: Dictionary=context_from_region(region,assigned_slots)
	var seed_text: String=str(atlas.get("seed","0"))
	return {"region_id":region_id,"npcs":People.roster(seed_text,region_id,assigned_slots,int(context.difficulty)),
		"contracts":Quests.offers(context,stage),"context":context}
