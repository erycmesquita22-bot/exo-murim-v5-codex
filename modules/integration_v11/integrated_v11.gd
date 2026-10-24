extends "res://modules/sword_frenzy/village.gd"
const ClimateAdapter = preload("res://modules/integration_v11/climate_adapter.gd")
@export var enable_training_rival := true
var climate
var region_key := ""
var presets := ["clear","drizzle","rain","mist","storm","night"]
var preset_index := 0
func _ready():
	super._ready()
	climate = ClimateAdapter.new();add_child(climate);climate.attach_to_world(self,null)
	for pair in [["weather_cycle",KEY_F7],["training_rival",KEY_F9]]:
		if not InputMap.has_action(pair[0]): InputMap.add_action(pair[0])
		if InputMap.action_get_events(pair[0]).is_empty():
			var key := InputEventKey.new();key.physical_keycode = pair[1];InputMap.action_add_event(pair[0],key)
	_sync_regions(true)
func _remote() -> bool: return s07_active or not active_room_id.is_empty()
func _quiesce():
	if skills != null:
		skills.cancel("transição de região");skills.pending = null;skills.restore_requested = false
		for projectile in skills.projectiles: projectile.node.queue_free()
		skills.projectiles.clear()
	action_kind = "";attack_buffer = 0;dodge_buffer = 0;jump_buffer = 0;travel_mode = false;travel_pending = false;queued_after_draw = false;locked = false
	health.set_guard(false);actor.velocity = Vector3.ZERO
func _sync_regions(force := false):
	var current := ("road" if s07_active else ("room/"+active_room_id if not active_room_id.is_empty() else "village"))
	var key := current+str(enable_training_rival)
	if not force and key == region_key: return
	region_key = key
	var active := not _remote() and enable_training_rival
	enemy.set_physics_process(active);enemy.actor.visible = active;enemy.actor.collision_layer = 4 if active else 0;enemy.actor.collision_mask = (1|2) if active else 0
	enemy.sword.trail.visible = active;enemy.sword.active = false
	for child in enemy.actor.get_children():
		if child is Area3D and child.name == "CombatHurtbox": child.collision_layer = 16 if active else 0
	if not active: locked = false
	if climate != null:
		climate.set_suspended(not active_room_id.is_empty());climate.refresh_scene_bindings()
func _interaction_available() -> bool:
	if is_transitioning: return false
	if s07_active: return _on_route_return_gate() or _on_city_gate()
	if not active_room_id.is_empty(): return actor.position.distance_to(ISOLATED_ORIGIN+active_room.local_exit_position()) < 2.65
	return _on_haneul_road_gate() or nearest_exterior_door() != ""
func _unhandled_input(event: InputEvent):
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F and _interaction_available():
		Input.action_release("guard");_quiesce()
	super._unhandled_input(event)
func _physics_process(delta: float):
	if Input.is_action_just_pressed("weather_cycle"):
		preset_index = (preset_index+1)%presets.size();climate.set_weather(presets[preset_index])
	if Input.is_action_just_pressed("training_rival"):
		enable_training_rival = not enable_training_rival;_quiesce();_sync_regions(true)
	_sync_regions()
	if is_transitioning: Input.action_release("guard")
	super._physics_process(delta)
	_sync_regions()
func desired_direction() -> Vector3:
	if is_transitioning: return Vector3.ZERO
	return super.desired_direction()
func attack_request() -> void:
	if is_transitioning: return
	super.attack_request()
func can_lock_target() -> bool:
	return enable_training_rival and not _remote() and super.can_lock_target()
func reset_duel() -> void:
	var remote := _remote();var position: Vector3 = actor.position
	super.reset_duel()
	if remote: actor.position = position;pivot.position = actor.position+Vector3(0,1.65,0)
	_sync_regions(true)
func finish_frame(delta: float):
	super.finish_frame(delta)
	if climate == null: return
	var location := "ESTRADA DO VAU" if s07_active else ("INTERIOR "+active_room_id if not active_room_id.is_empty() else "HANEUL V11")
	hud.text = "EXO-MURIM / %s / SWORD FRENZY\nWASD mover · Espaço pular · Clique combo · E espada · Q esquiva · F interação/defesa\nV viagem · K catálogo · F7 clima: %s · F9 rival: %s" % [location,climate.weather_name+" (suspenso)" if not active_room_id.is_empty() else climate.weather_name,"ativo" if enable_training_rival and not _remote() else "suspenso"]
