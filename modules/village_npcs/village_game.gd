extends "res://modules/coracao_01/heart_game.gd"
const Manager = preload("res://modules/village_npcs/village_manager.gd")
const TitleFlow = preload("res://modules/title_flow/title_flow.gd")
const WildlifeManager = preload("res://modules/village_life/wildlife_manager.gd")
const CultivationDistortion = preload("res://modules/village_life/cultivation_distortion.gd")
const CultivationPath = preload("res://modules/cultivation_path/progression.gd")
var title_flow: Control
var qi_indicator: Label
var village_npcs
var wildlife
var cultivation_distortion
var cultivation_path
func _ready() -> void:
	super._ready()
	village_npcs = Manager.new()
	village_npcs.name = "HaneulLivingResidents"
	village_npcs.configure(self)
	add_child(village_npcs)
	wildlife = WildlifeManager.new()
	wildlife.name = "HaneulWildlife"
	wildlife.configure(self)
	add_child(wildlife)
	cultivation_distortion = CultivationDistortion.new()
	cultivation_distortion.configure(self)
	add_child(cultivation_distortion)
	cultivation_path = CultivationPath.new()
	cultivation_path.name = "PlayerCultivationPath"
	cultivation_path.configure(self)
	add_child(cultivation_path)
	actor.collision_mask |= 128
	actor.collision_mask |= 64
	if skills != null and skills.ui != null: skills.ui.bar.visible = false
	qi_indicator = Label.new()
	qi_indicator.position = Vector2(22,198)
	qi_indicator.add_theme_font_size_override("font_size",18)
	qi_indicator.add_theme_color_override("font_color",Color("b9e9ec"))
	qi_indicator.add_theme_color_override("font_shadow_color",Color.BLACK)
	qi_indicator.add_theme_constant_override("shadow_offset_x",2)
	qi_indicator.add_theme_constant_override("shadow_offset_y",2)
	hud.get_parent().add_child(qi_indicator)
	var title_layer := CanvasLayer.new()
	title_layer.layer = 40
	title_layer.name = "DaxzinTitleLayer"
	add_child(title_layer)
	title_flow = TitleFlow.new()
	title_flow.host = self
	title_layer.add_child(title_flow)
func _sync_regions(force := false):
	super._sync_regions(force)
	if village_npcs != null: village_npcs.set_village_active(not _remote())
	if wildlife != null: wildlife.set_active(not _remote())
func _unhandled_input(event: InputEvent) -> void:
	if title_flow != null and title_flow.visible: return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_C: cultivation_path.toggle_cultivate();get_viewport().set_input_as_handled();return
			KEY_J: cultivation_path.toggle_panel();get_viewport().set_input_as_handled();return
			KEY_X: cultivation_path.breakthrough();get_viewport().set_input_as_handled();return
	if village_npcs != null and event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_T:
		if village_npcs.talk():
			get_viewport().set_input_as_handled()
			return
	super._unhandled_input(event)
func reset_cultivation() -> void:
	if cultivation_path != null: cultivation_path.reset_state()
func reset_village_npcs() -> void:
	if village_npcs != null: village_npcs.reset_all()
	if wildlife != null: wildlife.reset_all()
func query_blade(controller,weapon,base: Vector3,tip: Vector3,defender) -> void:
	super.query_blade(controller,weapon,base,tip,defender)
	if controller != self or village_npcs == null or not village_npcs.village_active: return
	var capsule := CapsuleShape3D.new()
	capsule.radius = weapon.definition.query_radius
	capsule.height = base.distance_to(tip)+capsule.radius*2
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = capsule
	query.transform = Transform3D(Basis(Quaternion(Vector3.UP,(tip-base).normalized())),(base+tip)*.5)
	query.collision_mask = 32
	query.collide_with_areas = true
	query.collide_with_bodies = false
	for hit in get_world_3d().direct_space_state.intersect_shape(query,12):
		var area: Area3D = hit.collider
		if not area.has_meta("village_npc"): continue
		var npc = area.get_meta("village_npc")
		if npc.hp <= 0 or weapon.victims.has(npc.get_instance_id()): continue
		if not can_see(actor,npc.body): continue
		weapon.victims[npc.get_instance_id()] = true
		var damage: int = weapon.definition.damage_for_clip(action_kind)
		npc.take_hit(damage,actor.global_position)
		fx.impact(npc.body.global_position+Vector3(0,1.35,0),(npc.body.global_position-actor.global_position).normalized())
	if wildlife != null and wildlife.active:
		query.collision_mask = 256
		for hit in get_world_3d().direct_space_state.intersect_shape(query,12):
			var area: Area3D = hit.collider
			if not area.has_meta("wildlife"): continue
			var creature = area.get_meta("wildlife")
			if creature.hp <= 0 or weapon.victims.has(creature.get_instance_id()): continue
			if not can_see(actor,creature.body): continue
			weapon.victims[creature.get_instance_id()] = true
			creature.take_hit(weapon.definition.damage_for_clip(action_kind),actor.global_position)
			fx.impact(creature.body.global_position+Vector3.UP,(creature.body.global_position-actor.global_position).normalized())

func _physics_process(delta: float) -> void:
	if cultivation_path != null and cultivation_path.cultivating:
		neutral = true
		tree.active = false
	super._physics_process(delta)
	if cultivation_path != null and cultivation_path.cultivating:
		actor.velocity.x = 0
		actor.velocity.z = 0
		tree.active = false
func finish_frame(delta: float) -> void:
	super.finish_frame(delta)
	if hud != null: hud.text = "" # No bottom control tips in the title/game HUD.
	if qi_indicator != null: qi_indicator.text = "QI %d/%d" % [int(skills.qi),int(skills.maximum_qi)]
	if skills != null and skills.ui != null and skills.ui.bar != null:
		skills.ui.bar.text = "QI %d/%d" % [int(skills.qi),int(skills.maximum_qi)]
