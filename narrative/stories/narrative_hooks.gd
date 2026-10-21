extends RefCounted
# Logical opportunities only: never issues objectives, rewards, or physical spawns.
const Registry=preload("res://narrative/factions/faction_registry.gd")
static func opportunities(s: Dictionary,atlas: Dictionary,npcs: Dictionary,origin: int) -> Array:
	if origin<0 or origin>=88 or not atlas.has("regions") or atlas.regions.size()!=88:return []
	var people: Array=[]
	for npc_id in npcs.keys():
		var n: Dictionary=npcs[npc_id]
		if int(n.get("region_id",-1))==origin:people.append(str(npc_id))
	people.sort()
	if people.is_empty():return []
	var result: Array=[]
	var ruins: int=-1
	var queue: Array=[origin]
	var seen: Dictionary={}
	seen[origin]=true
	while not queue.is_empty():
		var rid: int=int(queue.pop_front())
		if str(atlas.regions[rid].get("kind",""))=="ruins":ruins=rid;break
		for portal in atlas.regions[rid].get("entrances",[]):
			var next_r: int=int(portal.get("neighbor",-1))
			if next_r>=0 and next_r<88 and not seen.has(next_r):seen[next_r]=true;queue.append(next_r)
	if ruins>=0:
		var manual: String="story/manual/%s/%d/%s"%[str(s.world_id).substr(0,8),ruins,people[0]]
		if not s.decisions.has(manual):result.append({"id":manual,"kind":"manual_perdido","origin":origin,"region":ruins,"npc_ids":[people[0]],"factions":["cronicas_silenciosas","familias_ancestrais"],"outcomes":["manual_shared","manual_hidden"],"requires_physical":"item_discovered","knowledge":"manual_perdido"})
	var rival: String="story/rival/%s/%s"%[str(s.world_id).substr(0,8),people[0]]
	if not s.decisions.has(rival):result.append({"id":rival,"kind":"discipulo_rival","origin":origin,"region":origin,"npc_ids":[people[0]],"factions":[],"outcomes":["rival_resolved","rival_worsened"],"requires_physical":"npc_helped"})
	var dispute: String="story/dispute/%s/%d"%[str(s.world_id).substr(0,8),origin]
	if not s.decisions.has(dispute):result.append({"id":dispute,"kind":"disputa_regional","origin":origin,"region":origin,"npc_ids":[people[0]],"factions":["caminho_celestial","culto_abismo"],"outcomes":["support_celestial","support_abismo"],"requires_physical":"quest_completed"})
	return result
static func validate_choice(s: Dictionary,atlas: Dictionary,npcs: Dictionary,story_id: String,resolution: String) -> Dictionary:
	for region in range(88):
		# A story may have been offered from any region; validate against same world + real participants.
		for hook in opportunities(s,atlas,npcs,region):
			if hook.id==story_id and resolution in hook.outcomes:return hook
	return {}
