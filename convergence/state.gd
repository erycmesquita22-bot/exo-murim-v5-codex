extends RefCounted
static func valid(value: Variant) -> bool:
	if not value is Dictionary or value.get("schema")!=1 or value.get("regional_version")!=7:return false
	if (int(value.get("regional_version",0))==7)!=value.has("worldgen_v4"):return false
	if value.get("atlas") is Dictionary and value.atlas.has("worldgen_v4")!=value.has("worldgen_v4"):return false
	if value.has("worldgen_v4"):
		if not value.worldgen_v4 is Dictionary or value.worldgen_v4.get("schema")!=1 or value.worldgen_v4.get("generator")!=4:return false
		if value.has("atlas") and not preload("res://genesis/v4/world_plan.gd").valid_atlas(value.atlas):return false
	if not value.get("atlas_seed") is String or not value.atlas_seed.is_valid_int():return false
	if not (value.get("current") is int or value.get("current") is float):return false
	if int(value.current)!=value.current or value.current< -1 or value.current>87:return false
	if not value.get("position") is Array or value.position.size() not in [0,3]:return false
	for number in value.position:
		if not (number is float or number is int) or not is_finite(float(number)) or absf(number)>10000:return false
	for key in ["visited","actors"]:
		if not value.get(key) is Dictionary:return false
	if value.actors.size()>12000 or value.visited.size()>88:return false
	if value.has("worldgen_v5_visit"):
		var visit: Variant=value.worldgen_v5_visit
		if not visit is Dictionary or not visit.get("inside") is bool:return false
		if visit.inside:
			if visit.get("schema")!="exo.settlement.transition.v1":return false
			if not visit.get("building_id") is String or str(visit.building_id).is_empty():return false
			if str(visit.get("region_id",""))!=str(int(value.current)):return false
			for key in ["player_position","return_position"]:
				if not visit.get(key) is Array or visit[key].size()!=3:return false
				for component in visit[key]:
					if not (component is int or component is float) or not is_finite(float(component)) or absf(float(component))>20000:return false
	if value.has("activation_v4"):
		var activated:Variant=value.activation_v4
		if not activated is Dictionary or activated.get("schema")!=1:return false
		for key in ["receipts","recovery","library"]:
			if not activated.get(key) is Dictionary or activated[key].size()>512:return false
		for id in activated.recovery:
			var cd:Variant=activated.recovery[id]
			if not (cd is int or cd is float) or not is_finite(float(cd)) or float(cd)<0 or float(cd)>3600:return false
	if value.has("r10_energy"):
		var energy:Variant=value.r10_energy
		if not energy is Dictionary or energy.get("schema")!=1:return false
		for meter in ["qi","stamina"]:
			if not (energy.get(meter) is int or energy.get(meter) is float):return false
			if not is_finite(float(energy[meter])) or float(energy[meter])<0.0 or float(energy[meter])>100.0:return false
	if value.has("ecology"):
		var eco: Variant=value.ecology
		if not eco is Dictionary or int(eco.get("version",0))!=1:return false
		if not eco.get("regions") is Dictionary or not eco.get("farm_counts") is Dictionary:return false
		if eco.regions.size()>88 or eco.farm_counts.size()>250:return false
		for counter in eco.farm_counts.values():
			if not counter is Dictionary:return false
			if int(counter.get("day",-1))<0 or int(counter.get("count",-1))<0 or int(counter.get("count",0))>100000:return false
		if int(eco.get("level",1))<1 or int(eco.get("level",1))>50:return false
		if not (eco.get("xp_total") is int or eco.get("xp_total") is float):return false
		if float(eco.xp_total)<0 or float(eco.xp_total)>2000000000 or not is_finite(float(eco.xp_total)):return false
		for region in eco.regions.values():
			if not region is Dictionary or region.size()>16:return false
			for record in region.values():
				if not record is Dictionary:return false
				if float(record.get("defeated_at",-1))< -1 or not is_finite(float(record.get("defeated_at",-1))):return false
				if int(record.get("generation",-1))<0 or int(record.get("kills",-1))<0:return false
				if record.has("members_dead"):
					if not record.members_dead is Array or record.members_dead.size()>8:return false
					var seen_members: Array=[]
					for member in record.members_dead:
						if (not member is int and not member is float) or int(member)!=member or member<0 or member>7 or member in seen_members:return false
						seen_members.append(member)
	for id in value.actors:
		if not id is String or not id.begins_with("npc/r"):return false
		var actor: Variant=value.actors[id]
		if not actor is Dictionary or not actor.get("position") is Array or actor.position.size()!=3:return false
		for number in actor.position:
			if not (number is float or number is int) or not is_finite(float(number)) or absf(number)>10000:return false
		var index: Variant=actor.get("route_index",0)
		if not (index is float or index is int) or index!=floorf(float(index)) or index<0 or index>2048:return false
		if actor.has("visual_r2") and not actor.visual_r2.is_empty() and not preload("res://exo_humanoids03_r2/scripts/preset_selector.gd").valid(actor.visual_r2):return false
		for key in ["from_slot","to_slot"]:
			if actor.has(key) and (not actor[key] is String or actor[key].length()>100):return false
		if actor.has("visits") and (not actor.visits is Dictionary or actor.visits.size()>90):return false
	if not (value.get("clock") is float or value.get("clock") is int) or not is_finite(value.clock) or value.clock<0:return false
	if value.has("atlas"):
		if not value.atlas is Dictionary:return false
		for key in ["regions","portals","rivers_macro","hydrology_macro"]:
			if not value.atlas.get(key) is Array:return false
		if value.atlas.regions.size()!=88:return false
	return true
