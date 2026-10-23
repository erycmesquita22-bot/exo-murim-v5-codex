extends SceneTree
## Actual Forja bake + gameplay HUD: semantic colors, fit, cast/resource feedback.
const Baker=preload("res://exo_settlement_forge/runtime/house_baker_ac.gd")
const Builder=preload("res://exo_settlement_forge/runtime/architecture_builder.gd")
var failures: Array=[]
var checks: Array=[]
var w: Node3D
var capture: bool=false
var output_dir: String="user://hud-city-qa"
func _initialize() -> void:call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks.append({"name":label,"pass":ok})
	if not ok:failures.append(label)
	print("HUD_CITY_CHECK ",label," ",ok)
func shot(label: String) -> void:
	if not capture:return
	for i in range(3):await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output_dir.path_join(label+".png"))
func run() -> void:
	capture="capture" in OS.get_cmdline_user_args()
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--output="):output_dir=argument.trim_prefix("--output=")
	DirAccess.make_dir_recursive_absolute(output_dir)
	root.size=Vector2i(1280,720)
	var baked: Dictionary=Baker.get_house()
	check(not baked.is_empty(),"original_house_bakes")
	for role in ["wood","plaster","roof","stone"]:
		check(baked.role_uv.has(role),"semantic_atlas_role_"+role)
	var atlas: Image=baked.atlas
	var colors: Dictionary={}
	for role in baked.role_uv:
		var point: Vector2=baked.role_uv[role]*Vector2(atlas.get_size())
		colors[role]=atlas.get_pixel(int(point.x),int(point.y))
	check(colors.plaster.get_luminance()>colors.wood.get_luminance()*1.6,"plaster_is_lighter_than_timber")
	check(colors.roof.b>colors.roof.r*1.15,"roof_retains_blue_slate")
	var lod_uv: PackedVector2Array=baked.lod.surface_get_arrays(0)[Mesh.ARRAY_TEX_UV]
	check(lod_uv.has(baked.role_uv.plaster) and lod_uv.has(baked.role_uv.roof),"distant_mesh_samples_actual_plaster_and_roof_tiles")
	var lod_vertices: PackedVector3Array=baked.lod.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	# Six solid boxes (foundation, walls, three uprights and crossbeam),
	# plus two complete gable slopes: 6*12+4 triangles.
	check(lod_vertices.size()==228,"distant_boxes_have_all_twelve_triangles")
	var game_script: Script=load("res://convergence/game.gd")
	w=game_script.new();w.load_on_start=false;w.world_seed_override=101
	w.save_path="user://hud-city-qa.json";w.settings_path="user://hud-city-qa.cfg"
	root.add_child(w);await process_frame
	w.simulation_enabled=false
	w.flow.phase="adventure";w.ui.resume();w.ui.flow_screen.hide()
	w.graphics.hud.style=0;w.graphics.hud.scale=1.0
	w.ui.refresh()
	var hud: Control=w.ui.murim_hud
	var original_ids: Array=[]
	for skill in w.techniques.DATA:original_ids.append(skill.id)
	var ids: Array=[]
	for i in range(6):ids.append(w.Catalog.SKILLS[i].id)
	for count in [3,6]:
		w.techniques.configure(ids.slice(0,count))
		for size_value in [Vector2(960,540),Vector2(1280,720),Vector2(1920,1080),Vector2(2560,1080)]:
			for setting in [.6,1.0,1.5]:
				w.graphics.hud.scale=setting
				var layout: Dictionary=hud.layout_for(size_value)
				var screen: Rect2=Rect2(Vector2.ZERO,size_value)
				var ok: bool=true
				for name_value in ["vitals","navigation","techniques"]:ok=ok and screen.encloses(layout[name_value])
				ok=ok and not layout.vitals.intersects(layout.navigation) and not layout.navigation.intersects(layout.techniques)
				check(ok,"layout_%d_%s_scale_%.1f"%[count,str(size_value),setting])
	w.techniques.configure(original_ids);w.graphics.hud.scale=1.0
	check(w.techniques.cast(0),"real_technique_cast_commits")
	check(w.techniques.cooldowns[0]>0 and w.techniques.stamina<100,"real_cooldown_and_cost_visible")
	w.ui.refresh();await process_frame
	check(hud.visible and not w.ui.prompt.visible and not w.ui.quest.get_parent().get_parent().visible,"one_hud_owns_tracker_and_context_prompt")
	w.visible=false;w.camera.current=false
	var gallery:=Node3D.new();root.add_child(gallery)
	var environment:=WorldEnvironment.new();environment.environment=Environment.new()
	environment.environment.background_mode=Environment.BG_COLOR;environment.environment.background_color=Color("34434b")
	environment.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color=Color("e8dccc");environment.environment.ambient_light_energy=.7
	gallery.add_child(environment)
	var light:=DirectionalLight3D.new();gallery.add_child(light);light.rotation_degrees=Vector3(-45,-30,0);light.light_energy=1.1
	for index in range(2):
		var record: Dictionary={"accessible":true,"dimensions":[6.0,5.8,4.0],"position":[-6 if index==0 else 6,0,0],"yaw":0.0,"building_id":"qa_"+str(index),"function":"residence"}
		var house: Node3D=Builder.build(gallery,record)
		var near: MeshInstance3D=house.get_node("ForjaCompleteVisual")
		var far: MeshInstance3D=house.get_node("ForjaDistantLOD")
		near.visibility_range_end=0;near.visible=index==0
		far.visibility_range_begin=0;far.visible=index==1
	var camera:=Camera3D.new();gallery.add_child(camera);camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=26
	camera.position=Vector3(16,16,24);camera.look_at(Vector3(0,2.5,0));camera.current=true
	await shot("hud-cooldown-house-near-and-far")
	w.techniques.finish();w.techniques.mana=0;w.techniques.stamina=0
	check(not w.techniques.cast(1),"real_cast_rejects_depleted_qi")
	w.feedback_time=0;await shot("hud-depleted-resources")
	w.techniques.configure(ids);w.techniques.cooldowns.fill(0);w.techniques.mana=100;w.techniques.stamina=100
	w.graphics.hud.compact=true
	root.size=Vector2i(960,540);await shot("hud-six-techniques-960x540")
	print("HUD_CITY_RESULT ",JSON.stringify({"checks":checks,"failures":failures}))
	w.audio_fx.shutdown();w.free();gallery.free()
	quit(0 if failures.is_empty() else 1)
