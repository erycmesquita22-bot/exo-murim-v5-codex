extends RefCounted
# Functional, varied village streets. No NPC or quest coordinates belong here.
const Layout=preload("res://world/village_layout_v2.gd")
const Paving=preload("res://world/paving.gd")
const LevelDesign=preload("res://world/level_design.gd")
const Assets=preload("res://world/asset_library.gd")
const Region=preload("res://region.gd")

static func build(w: Node3D,plan: Dictionary) -> void:
	assert(Layout.safe_layout(plan))
	# These Vector3 values are the canonical positions for NPCs, spawning and interactions.
	var services: Dictionary={}
	for role in plan.anchors.keys():services[role]=Layout.anchor(plan,str(role))
	w.set_meta("village_services",services)
	# Four district patterns are visually different: market crossings, hillside avenue,
	# paired courtyards or split lanes. Buildings and route topology vary by seed.
	LevelDesign.ground(w,plan)
	for role in ["guild","inn","training"]:
		var cell: Dictionary=plan.sites[role]
		var site_pos:=Vector3(float(cell.x),0,float(cell.z))
		var is_guild: bool=role=="guild"
		Region.house(w,site_pos,Vector3(float(cell.width),3.0,5.7),"3c4541",is_guild,"village/"+role)
		var label: String="GUILDA DOS AVENTUREIROS" if role=="guild" else "POUSADA • ABRIGO" if role=="inn" else "PÁTIO DE TREINO"
		w.add_sign(site_pos+Vector3(0,4.2,0),label,Color("e7d3a6"))
	for cell in plan.houses:
		var p:=Vector3(float(cell.x),0,float(cell.z))
		Region.house(w,p,Vector3(float(cell.width),2.6,5.5),"483f36",false,"village/home_%d"%int(cell.slot))
		var external: float=1.0 if p.x>0 else -1.0
		if str(plan.kind)!="empobrecida" and int(cell.slot)%3!=0:
			Region.bamboo(w,p+Vector3(external*3.4,0,2.6),2.0+float(int(cell.slot)%3)*.3)
	# Interactive locations correspond exactly to anchors, not previous fixed positions.
	var board: Vector3=services.board
	w.block(board+Vector3(0,1.35,0),Vector3(1.65,1.45,.22),Color("634a36"),true)
	for x in [-.57,.57]:w.block(board+Vector3(x,.52,0),Vector3(.13,1.05,.15),Color("453429"),false)
	for x in [-.45,0,.45]:w.block(board+Vector3(x,1.45,-.13),Vector3(.33,.45,.035),Color("d5c9a5"),false)
	var bed: Vector3=services.bed
	w.block(bed+Vector3(0,.12,0),Vector3(1.3,.23,2.1),Color("8b7355"),false)
	w.block(bed+Vector3(0,.26,0),Vector3(1.2,.05,1.7),Color("42605c"),false)
	var mat: Vector3=services.mat
	w.block(mat+Vector3(0,.045,0),Vector3(2.4,.09,2.5),Color("9e8d6f"),true)
	w.block(mat+Vector3(0,.096,0),Vector3(1.45,.015,1.5),Color("436f70"),false)
	# Plots, commons, cultural landmarks and village profile use the same seed.
	LevelDesign.decorate(w,plan)
	# The gate is always accessible but its design and placement fit the selected streets.
	for side in [-1,1]:
		w.block(Vector3(float(side)*4.4,1.65,15),Vector3(.5,3.3,.55),Color("67503c"),true)
	w.block(Vector3(0,3.35,15),Vector3(9.1,.35,.8),Color("664b35"),false)
	Region.roof(w,Vector3(0,3.6,15),9.2,2.3)
	w.add_sign(Vector3(0,4.65,15),str(plan.title).to_upper(),Color("dfd1a9"))
	w.add_sign(Vector3(0,2.4,13.0),"ESTRADAS DO MURIM",Color("98c1ad"))

