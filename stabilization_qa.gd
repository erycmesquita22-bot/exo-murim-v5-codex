extends SceneTree
var w: Node3D
var passed:=0
var failed:=0
func _initialize() -> void:call_deferred("run")
func check(ok: bool,label: String) -> void:
	passed+=int(ok);failed+=int(not ok);print(("OK " if ok else "FAIL ")+label)
func run() -> void:
	w=load("res://main.gd").new();w.load_on_start=false;w.save_path="user://stabilization081.json";w.settings_path="user://stabilization081.cfg";root.add_child(w);await process_frame
	w.simulation_enabled=false
	w.flow.phase="creator";w.flow.create_character({"name":"QA","race":0,"path":0,"robe":1,"hair":0,"skin":0,"style":0});w.ui.resume();w.simulation_enabled=false
	for level in range(3):
		w.graphics.select(level)
		check(not w.sun.shadow_enabled and root.positional_shadow_atlas_size==0,"Sem atlas ou sombra dinâmica no perfil "+str(level))
		var visible:=true
		for s in w.find_children("SoftGroundShadow*","MeshInstance3D",true,false):visible=visible and s.visible
		check(visible,"Sombras pintadas preservadas no perfil "+str(level))
		var lamps:=true
		for light in get_nodes_in_group("profile_lights"):lamps=lamps and not light.shadow_enabled
		check(lamps,"Lanternas não geram shadow maps "+str(level))
	var houses: Array=[]
	for node in w.get_children():
		if node.has_meta("entrance_position"):houses.append(node)
	check(houses.size()==3+w.get_meta("landscape_plan").houses.size(),"Todos os edifícios do plano atual orientados por entrada")
	var ids: Array=[]
	for house in houses:
		var toward_square:=Vector3(-signf(house.position.x),0,0)
		check(house.get_meta("entrance_direction").dot(toward_square)>.99,"Porta voltada ao pátio: "+str(house.name))
		ids.append(house.get_meta("persistent_id"))
		check(house.get_child_count()>=2,"Colisão acompanha a transformação da casa")
		# Actual CharacterBody motion on its approach, using physics, with scene simulation disabled.
		var entrance: Vector3=house.get_meta("entrance_position")
		var forward: Vector3=house.get_meta("entrance_direction")
		w.player.position=entrance+forward*2+Vector3.UP*.08
		var start: Vector3=w.player.position
		for i in range(32):
			await physics_frame
			w.player.velocity=-forward*3.6+Vector3.DOWN
			w.player.move_and_slide()
		check(w.player.position.distance_to(start)>1.5,"Aproximação física sem barreira invisível: "+str(house.name))
	check(ids.size()==houses.size() and ids.size()==unique_ids(ids),"IDs persistentes distintos para edifícios")
	check(w.get_meta("static_blocks_batched",0)>300,"Geometria imóvel agrupada uma vez por setor")
	var a: Node=w.audio_fx
	check(a.BANK.magia!=a.BANK.evade and a.BANK.magia!=a.BANK.vento,"Magia, esquiva e vento têm gravações diferentes")
	check(a.BANK.qi_hit!=a.BANK.vento and a.BANK.qi_hit!=a.BANK.wood_hit,"Contato Qi separado de ar e madeira")
	check(a.BANK.skill_windup!=a.BANK.leap,"Preparação de energia separada do salto")
	for spec in [[{"kind":"projectile","element":0},"vento"],[{"kind":"projectile","element":1},"terra"],[{"kind":"projectile","element":5},"fogo"],[{"kind":"projectile","element":6},"gelo"],[{"kind":"projectile","element":11},"qi"],[{"kind":"summon","element":11},"summon"]]:
		check(a.skill_event(spec[0])==spec[1],"Família sonora: "+spec[1])
	w.ui.show_extra(false);await process_frame
	var menu: int=w.ui.exo.shell.get_instance_id()
	for page in ["inventario","ativas","jornada","config","audio"]:
		w.ui.exo.open(page);await process_frame
		check(w.ui.exo.shell.get_instance_id()==menu and not w.ui.menu.visible,"Navegação mantém uma estrutura de interface: "+page)
	w.ui.exo.close_menu();w.audio_fx.shutdown();w.queue_free();await process_frame;await process_frame
	print("STABILIZATION081: %d passaram / %d falharam"%[passed,failed]);quit(int(failed>0))

func unique_ids(ids: Array) -> int:
	var seen: Dictionary={}
	for id in ids:seen[id]=true
	return seen.size()
