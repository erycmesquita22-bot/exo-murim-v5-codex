extends RefCounted
# Stable original slot IDs remain valid; additional occupants use explicit IDs.
const SERVICES={"smithy":"ferraria","herbalist":"medicina","market":"comércio","inn":"hospedagem","administration":"orientação","martial_school":"treino","shrine":"meditação","warehouse":"provisões","farmstead":"cultivo"}
static func assign(region: Node3D) -> void:
	var beds: Array=[];var capacity: Dictionary={}
	for i in range(region.data.lots.size()):
		var lot: Dictionary=region.data.lots[i];var bp: Dictionary=region.blueprints[i]
		var cap: int=(4 if int(bp.stories)==2 else 3 if int(bp.width_m)>=6 else 2) if lot.function in ["residence","dwelling","farmstead"] else 4 if lot.function=="inn" else 0
		capacity[lot.id]=cap
		for k in range(cap):beds.append(lot.id)
	var workplaces: Array=[]
	for lot in region.data.lots:
		if lot.function not in ["residence","dwelling","shrine","administration","martial_school"]:workplaces.append(lot.id)
	var original: Array=region.assigned_slots.duplicate(true)
	region.assigned_slots.clear()
	var used: Dictionary={}
	for slot in original:
		var home: String=str(slot.id) if beds.has(slot.id) else str(beds[0]) if not beds.is_empty() else str(slot.id)
		if beds.has(home):beds.erase(home)
		if slot.role=="resident" and capacity.get(slot.id,0)>0 and not workplaces.is_empty():slot.work_slot=workplaces[region.assigned_slots.size()%workplaces.size()]
		slot.home_slot=home;used[home]=int(used.get(home,0))+1
		region.assigned_slots.append(slot)
	# At most 50% extra occupants, capped at 72 active characters per city.
	var budget: int=mini(72,original.size()+int(ceil(original.size()*.5)))
	var index:=0
	while not beds.is_empty() and region.assigned_slots.size()<budget:
		var home: String=beds.pop_front();index+=1
		region.assigned_slots.append({"id":home+"_occupant_%02d"%index,"role":"resident","home_slot":home,"work_slot":home})
		used[home]=int(used.get(home,0))+1
	region.set_meta("housing_capacity",capacity);region.set_meta("housing_occupancy",used)
static func commute(region: Node3D,from_id: String,to_id: String) -> Array:
	var a: Array=region.route_points[from_id];var b: Array=region.route_points[to_id]
	if from_id==to_id:return [a[0]]
	var middle:Array=region.navigator.route(a[-1],b[-1])
	if middle.is_empty():return []
	var path: Array=a.duplicate();path.append_array(middle)
	var back: Array=b.duplicate();back.reverse();path.append_array(back)
	return path
