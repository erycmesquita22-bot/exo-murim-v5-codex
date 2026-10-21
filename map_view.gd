extends Control
# Schematic minimap of the actual connected playable region; no fake quest pins.
var world: Node3D
func _ready() -> void:
	custom_minimum_size=Vector2(620,430)
	mouse_filter=Control.MOUSE_FILTER_IGNORE
func point(p: Vector3) -> Vector2:
	return Vector2((p.x+104.0)/208.0*size.x,(p.z+120.0)/224.0*size.y)
func _draw() -> void:
	var dungeon_map:Dictionary=preload("res://exo_dungeon/ui/map_draw.gd").snapshot(world)
	if not dungeon_map.is_empty():
		draw_rect(Rect2(Vector2.ZERO,size),Color("12161c"))
		preload("res://exo_dungeon/ui/map_draw.gd").draw_map(self,dungeon_map,size/2,minf(size.x,size.y)*0.46)
		return
	if world.get("current_region")!=null and int(world.get("current_region"))>=0:
		draw_regional();return
	draw_rect(Rect2(Vector2.ZERO,size),Color("202b30"))
	# Village, western highlands, eastern bamboo belt, northern ruins.
	draw_rect(Rect2(point(Vector3(-102,0,-112)),point(Vector3(-35,0,95))-point(Vector3(-102,0,-112))),Color("3d4b47"))
	draw_rect(Rect2(point(Vector3(35,0,-112)),point(Vector3(102,0,95))-point(Vector3(35,0,-112))),Color("294538"))
	draw_rect(Rect2(point(Vector3(-33,0,-118)),point(Vector3(33,0,-49))-point(Vector3(-33,0,-118))),Color("3b5754"))
	draw_rect(Rect2(point(Vector3(-38,0,15)),point(Vector3(38,0,65))-point(Vector3(-38,0,15))),Color("545447"))
	for x in range(-100,105,20):draw_line(point(Vector3(x,0,-120)),point(Vector3(x,0,104)),Color("536064",.20),1)
	for z in range(-120,105,20):draw_line(point(Vector3(-104,0,z)),point(Vector3(104,0,z)),Color("536064",.20),1)
	# All trails are walkable in the scene, and neither requires a teleport.
	draw_line(point(Vector3(0,0,62)),point(Vector3(90,0,62)),Color("a08a64"),3)
	draw_line(point(Vector3(0,0,10)),point(Vector3(-90,0,10)),Color("a08a64"),3)
	draw_line(point(Vector3(0,0,60)),point(Vector3(0,0,-112)),Color("a08a64"),3)
	var plot: Dictionary=world.get_meta("landscape_plan",{})
	for house in plot.get("houses",[]):
		draw_rect(Rect2(point(Vector3(float(house.x),0,float(house.z)))-Vector2(3,3),Vector2(6,6)),Color("b7ac86"))
	if int(plot.get("version",1))>=2:
		for site in plot.get("sites",{}).values():
			var pos:=Vector3(float(site.x),0,float(site.z))
			draw_rect(Rect2(point(pos)-Vector2(5,4),Vector2(10,8)),Color("90a397"))
	else:
		for p in [Vector3(-12,0,30),Vector3(12,0,31),Vector3(-12,0,20),Vector3(13,0,20)]:
			draw_rect(Rect2(point(p)-Vector2(5,4),Vector2(10,8)),Color("90a397"))
	for p in world.flow.PATROL:
		if world.journey.data.stage!=1:continue
		draw_circle(point(p),3,Color("e8cb87"))
	for actor in world.flow.field_enemies:
		if actor.hp>0 and actor.position.distance_to(world.player.position)<12:draw_circle(point(actor.position),3,Color("d88b75"))
	if world.flow.has_destination():draw_arc(point(world.flow.destination()),7,0,TAU,32,Color("efd494"),2)
	for site in world.exploration_sites:
		var completed: bool=preload("res://procedural/world_state.gd").has_event(world.journey.data.world,"loot/explore_"+str(site.id))
		draw_circle(point(site.point),5,Color("667e79") if completed else Color("e0bc77"))
	draw_circle(point(world.player.position),5,Color("9ef0e5"))
	draw_circle(point(world.flow.BED),3,Color("a3bee5"))
	var font:=ThemeDB.fallback_font
	var labels: Array=[[Vector3(40,0,69),"Bambu"],[Vector3(-85,0,24),"Montanhas"],[Vector3(-26,0,-103),"Ruínas distantes"],[Vector3(4,0,-34),"Vigia"]]
	var anchors: Dictionary=world.get_meta("village_services",{})
	labels.append([anchors.get("npc",Vector3(-35,0,35)),"Guilda"])
	labels.append([anchors.get("bed",Vector3(8,0,38)),"Abrigo"])
	for entry in labels:
		draw_string(font,point(entry[0]),entry[1],HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("dfd7b9"))

# Same map surface, fed by the active Genesis data rather than tutorial pins.
func regional_point(p: Vector2) -> Vector2:
	return (p/512.0+Vector2(.5,.5))*size
func draw_regional() -> void:
	draw_rect(Rect2(Vector2.ZERO,size),Color("202b30"))
	var region: Node3D=world.get("active_region")
	var data: RefCounted=region.data
	var font:=ThemeDB.fallback_font
	for road in data.settlement_roads:
		draw_line(regional_point(road.a),regional_point(road.b),Color("a08a64"),3)
	for gate in data.gates:
		draw_line(regional_point(Vector2.ZERO),regional_point(gate.p),Color("a08a64"),3)
		draw_circle(regional_point(gate.p*.92),5,Color("d8c89f"))
		draw_string(font,regional_point(gate.p*.87),"→ %02d"%int(gate.neighbor),HORIZONTAL_ALIGNMENT_LEFT,-1,14)
	for lot in data.lots:draw_rect(Rect2(regional_point(lot.p)-Vector2(4,4),Vector2(8,8)),Color("b7ac86"))
	for actor in world.get("residents"):draw_circle(regional_point(Vector2(actor.position.x,actor.position.z)),3,Color("e6bc77"))
	draw_circle(regional_point(Vector2(world.player.position.x,world.player.position.z)),5,Color("9ef0e5"))
	draw_string(font,Vector2(16,22),"Região %02d • %s • 88 externas"%[int(world.get("current_region")),str(world.call("region_title",data.spec))],HORIZONTAL_ALIGNMENT_LEFT,-1,16)
