extends Node3D
const NPC = preload("res://modules/village_npcs/npc_actor.gd")
const LEGACY_SAVE_PATH := "user://exo_village_npcs_01.json"
var save_path := LEGACY_SAVE_PATH
var host: Node3D
var residents: Dictionary = {}
var prompt: Label
var save_timer := 0.0
var village_active := true
var cultivation_sites: Array[Node3D] = []
var visibility_timer := 0.0
func configure(world: Node3D) -> void: host = world
func _ready() -> void:
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://modules/village_npcs/roster.json"))
	assert(manifest.region == "HWA-02")
	for spec in manifest.npcs:
		var npc = NPC.new()
		npc.configure(spec,host)
		add_child(npc)
		residents[str(spec.id)] = npc
		npc.life_changed.connect(func(_id: String,_hp: int):save_all())
	for site in manifest.get("cultivation_sites",[]): _create_cultivation_site(site)
	var canvas: CanvasLayer = host.hud.get_parent()
	prompt = Label.new()
	prompt.position = Vector2(22,342)
	prompt.add_theme_color_override("font_color",Color("f8e4bd"))
	prompt.add_theme_color_override("font_shadow_color",Color("15212a"))
	prompt.add_theme_constant_override("shadow_offset_x",2)
	prompt.add_theme_constant_override("shadow_offset_y",2)
	canvas.add_child(prompt)
	load_all()
	set_village_active(not host._remote())
func _create_cultivation_site(site: Dictionary) -> void:
	var marker := Node3D.new()
	marker.name = str(site.id)
	var xy: Array = site.position
	marker.position = Vector3(float(xy[0]),host._terrain_height(float(xy[0]),float(xy[1]))+.05,float(xy[1]))
	add_child(marker)
	for radius in [2.1,2.7]:
		var circle := MeshInstance3D.new()
		circle.name = "QiTrainingCircle"
		var mesh := TorusMesh.new()
		mesh.inner_radius = radius-.035
		mesh.outer_radius = radius+.035
		circle.mesh = mesh
		var ink := StandardMaterial3D.new()
		ink.albedo_color = Color(.22,.53,.6,.72)
		ink.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		ink.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		circle.material_override = ink
		marker.add_child(circle)
	cultivation_sites.append(marker)
func _process(delta: float) -> void:
	if not village_active: return
	visibility_timer -= delta
	if visibility_timer <= 0:
		visibility_timer = .45
		for npc in residents.values():
			var near: bool = npc.body.global_position.distance_to(host.actor.global_position) < 68.0
			if npc.active_in_village != near: npc.set_village_active(near)
	for npc in residents.values():
		if not npc.active_in_village: npc.clock_minutes = fmod(npc.clock_minutes+delta*4.0,1440.0)
	save_timer += delta
	if save_timer >= 15.0: save_timer = 0;save_all()
	var nearest = nearest_resident(3.0)
	if nearest != null:
		if prompt.has_meta("talk_until") and Time.get_ticks_msec() < int(prompt.get_meta("talk_until")): return
		prompt.text = "[T] Conversar: %s" % nearest.record.label
	else: prompt.text = ""
func nearest_resident(max_distance: float):
	var best
	var distance := max_distance
	for npc in residents.values():
		if npc.hp <= 0 or not npc.visible: continue
		var found: float = host.actor.global_position.distance_to(npc.body.global_position)
		if found < distance: best = npc;distance = found
	return best
func talk() -> bool:
	var npc = nearest_resident(3.0)
	if npc == null: return false
	var line: String = str(npc.record.dialogue)
	if host.cultivation_path != null: host.cultivation_path.on_talk(str(npc.record.id))
	if npc.hp < npc.maximum/2: line = "Preciso me recuperar antes de voltar ao trabalho."
	elif str(npc.record.get("role","")) == "mestre de cultivo":
		if host.cultivation_path != null and host.cultivation_path.rank == 0:
			line = "Primeiro aprenda a postura. Complete dois ciclos no circulo para despertar o Qi."
		elif Time.get_ticks_msec() >= int(npc.get_meta("training_next",0)):
			host.skills.qi = minf(host.skills.maximum_qi,host.skills.qi+12)
			npc.set_meta("training_next",Time.get_ticks_msec()+90000)
			line = "Ajuste a respiração. +12 Qi; volte depois para outro treino."
		else: line = "Deixe o qi circular antes da próxima lição."
	prompt.text = "%s: %s" % [npc.record.label,line]
	prompt.set_meta("talk_until",Time.get_ticks_msec()+4300)
	return true
func set_village_active(value: bool) -> void:
	if value == village_active: return
	village_active = value
	for npc in residents.values(): npc.set_village_active(value)
	for marker in cultivation_sites: marker.visible = value
	if not value and prompt != null: prompt.text = ""
func use_slot(slot: int) -> void:
	save_path = "user://exo_village_npcs_slot_%d.json" % clampi(slot,1,3)
	if slot == 1 and not FileAccess.file_exists(save_path) and FileAccess.file_exists(LEGACY_SAVE_PATH):
		DirAccess.copy_absolute(ProjectSettings.globalize_path(LEGACY_SAVE_PATH),ProjectSettings.globalize_path(save_path))
	for npc in residents.values(): npc.reset_life()
	load_all()
func reset_all() -> void:
	for npc in residents.values(): npc.reset_life()
	save_all()
func save_all() -> void:
	var states := {}
	for id in residents: states[id] = residents[id].save_state()
	var file := FileAccess.open(save_path,FileAccess.WRITE)
	if file == null: push_error("NPC_SAVE_FAILED "+str(FileAccess.get_open_error()));return
	file.store_string(JSON.stringify({"version":1,"region":"HWA-02","states":states},"\t"))
	file.close()
func load_all() -> void:
	if not FileAccess.file_exists(save_path): return
	var state: Variant = JSON.parse_string(FileAccess.get_file_as_string(save_path))
	if not state is Dictionary or state.get("version",0) != 1 or state.get("region","") != "HWA-02": return
	var entries: Dictionary = state.get("states",{})
	for id in residents:
		if entries.has(id): residents[id].load_state(entries[id])
