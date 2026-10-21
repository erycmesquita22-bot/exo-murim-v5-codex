extends SceneTree
const World=preload("res://main.gd")
const Library=preload("res://world/asset_library.gd")
const Motions=preload("res://animation_library.gd")
var passed:=0
var failed:=0
var w: Node3D
func _initialize() -> void:call_deferred("run")
func check(ok: bool,label: String) -> void:
	passed+=int(ok);failed+=int(not ok);print(("OK " if ok else "FAIL ")+label)
func rendered(node: Node) -> int:
	var result:=int(node is MeshInstance3D and node.mesh!=null and node.is_visible_in_tree())
	for child in node.get_children():result+=rendered(child)
	return result
func run() -> void:
	w=World.new();w.load_on_start=false;w.save_path="user://assets08.json";w.settings_path="user://assets08.cfg";root.add_child(w);await process_frame
	w.simulation_enabled=false
	check(Library.catalog.size()==10,"Seleção dos dez componentes utilizados, sem carregar os 74 excedentes")
	for id in ["building_1","building_2","shop","well","cart","gong","statue_monk"]:
		check(not w.find_children("Asset_"+id,"Node3D",true,false).is_empty(),"Modelo externo aparece na região: "+id)
	var profile: Dictionary={"name":"Teste","race":0,"path":0,"robe":1,"hair":0,"skin":0,"style":0,"weapon":"sword","outfit":0}
	w.flow.phase="creator";w.flow.create_character(profile);w.ui.resume();w.simulation_enabled=false
	check(w.model.get_meta("batched_surfaces",0)>0 and w.model.find_children("BatchedClothing*","MeshInstance3D",true,false).size()<int(w.model.get_meta("batched_surfaces",0)),"Roupas são combinadas em menos malhas por articulação")
	print("CHARACTER visible meshes=",rendered(w.model)," batched originals=",w.model.get_meta("batched_surfaces",0))
	var garments: Array=w.model.get_meta("garments",[])
	var render_before:=rendered(w.model)
	w.flow.apply_character();await process_frame
	check(rendered(w.model)==render_before,"Reaplicar aparência não acumula malhas visíveis")
	check(Motions.new().has_method("locomotion"),"Animação autoral direcional disponível")
	w.model.pose(0,false,false,true)
	Motions.locomotion(w.model,.9,false,true,1.0,3.6)
	check(w.model.get_meta("motion_source","")=="EXO_original_local_8directions","Caminhada autoral aplicada ao rig do EXO")
	var first: Quaternion=w.model.arms[0].quaternion
	Motions.locomotion(w.model,2.4,false,true,1.0,3.6)
	check(first.angle_to(w.model.arms[0].quaternion)>.05,"Braços produzem poses diferentes durante o ciclo")
	Motions.locomotion(w.model,1.0,true,true,1.0,6.0)
	check(w.model.get_meta("motion_source","")=="EXO_original_local_8directions","Corrida utiliza animação autoral")
	for level in range(3):
		w.graphics.select(level)
		check(not w.sun.shadow_enabled,"Sombras dinâmicas desativadas: "+str(level))
		check(is_equal_approx(w.get_viewport().scaling_3d_scale,1.0),"Resolução nativa preservada no perfil "+str(level))
	# The character creator switches to the procedural village V2. Test the
	# imported asset occluder explicitly instead of requiring an obsolete house name.
	var house: Node3D=Library.place(w,"building_1",Vector3(-18,0,45),7.0)
	var axis: Vector3=Vector3(1,0,1).normalized()
	w.player.position=house.position-axis*6;w.update_camera();house._process(1.0)
	check(house.get_meta("occlusion_alpha",1.0)<.5,"Edificação entre a câmera e o jogador torna-se translúcida")
	w.player.position=Vector3(0,.03,27);w.update_camera();house._process(1.0)
	check(house.get_meta("occlusion_alpha",0.0)>.9,"Edificação recupera opacidade ao liberar a visão")
	for event in ["punch","swing","fist_hit","blade_hit","strong_hit"]:
		check(w.audio_fx.BANK[event].size()>=2,"Variação real por evento: "+event)
	check(w.audio_fx.BANK.punch[0].contains("kungfu_air"),"Antecipação marcial usa gravação CC0 de Kung-Fu Whooshes")
	check(w.audio_fx.BANK.fist_hit[0].contains("palm_"),"Soco usa composição de contato, sem ar antecipado embutido")
	# Physics checks at unchanged Guild and inn interactions.
	w.player.position=w.village_anchor("npc",w.NPC_POS)+Vector3(0,0,2.0);w.flow.interact()
	check(w.journey.data.stage==1,"Interação da Guilda continua acessível com os modelos externos")
	w.ui.resume()
	w.audio_fx.shutdown();await create_timer(.2,true,false,true).timeout;w.queue_free();await process_frame;await process_frame
	w=null;await create_timer(.35,true,false,true).timeout
	print("ASSETS08: %d passaram / %d falharam"%[passed,failed]);quit(int(failed>0))
