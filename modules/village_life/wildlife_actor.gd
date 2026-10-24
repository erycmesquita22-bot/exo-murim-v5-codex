extends Node3D
## Data-driven quadruped body. Imported skeleton and clips remain inside the source glTF.
signal life_changed(id: String, hp: int)
var spec: Dictionary
var host: Node3D
var body: CharacterBody3D
var visual: Node3D
var animator: AnimationPlayer
var hurtbox: Area3D
var plate: Label3D
var home: Vector3
var hp: int
var state := "IDLE"
var elapsed := 0.0
var combo_index := 0
var hit_done := false
var active := true
var wandering := Vector3.ZERO
var decision_timer := 0.0
var rng := RandomNumberGenerator.new()
var qi_ring: MeshInstance3D
func configure(data: Dictionary, world: Node3D, rig_path: String) -> void:
 spec = data
 host = world
 visual = load(rig_path).instantiate()
 hp = int(spec.hp)
 rng.seed = hash(str(spec.id))
func _ready() -> void:
 body = CharacterBody3D.new()
 body.name = str(spec.id)+"_Body"
 body.collision_layer = 128
 body.collision_mask = 1|2
 body.floor_snap_length = .65
 add_child(body)
 var collision := CollisionShape3D.new()
 var capsule := CapsuleShape3D.new()
 var size: float = float(spec.scale)
 capsule.radius = .77*size
 capsule.height = 4.1*size
 collision.shape = capsule
 collision.position.y = 2.05*size
 body.add_child(collision)
 visual.name = "SkinnedQuadrupedRig"
 visual.scale = Vector3.ONE*size
 body.add_child(visual)
 animator = _find_anim(visual)
 assert(animator != null and animator.has_animation("Idle"))
 hurtbox = Area3D.new()
 hurtbox.name = "WildlifeHurtbox"
 hurtbox.collision_layer = 256
 hurtbox.collision_mask = 0
 hurtbox.monitorable = true
 hurtbox.monitoring = false
 hurtbox.set_meta("wildlife",self)
 var hs := CollisionShape3D.new()
 var hcap := CapsuleShape3D.new()
 hcap.radius = .96*size
 hcap.height = 3.8*size
 hs.shape = hcap
 hs.position.y = 1.9*size
 hurtbox.add_child(hs)
 body.add_child(hurtbox)
 plate = Label3D.new()
 plate.name = "WildlifeName"
 plate.position.y = 4.1*size
 plate.pixel_size = .0038
 plate.font_size = 32
 plate.billboard = BaseMaterial3D.BILLBOARD_ENABLED
 body.add_child(plate)
 var pos: Array = spec.at
 home = Vector3(float(pos[0]),host._terrain_height(float(pos[0]),float(pos[1]))+.4,float(pos[1]))
 body.position = home
 if str(spec.kind) == "beast": _add_murim_mark()
 _refresh_plate()
 animator.play("Idle")
func _find_anim(node: Node) -> AnimationPlayer:
 if node is AnimationPlayer: return node
 for child in node.get_children():
  var found := _find_anim(child)
  if found != null: return found
 return null
func _add_murim_mark() -> void:
 qi_ring = MeshInstance3D.new()
 qi_ring.name = "MurimQiSigil"
 var mesh := TorusMesh.new()
 mesh.inner_radius = 1.15
 mesh.outer_radius = 1.21
 qi_ring.mesh = mesh
 qi_ring.position.y = .12
 qi_ring.rotation.x = PI/2
 var mat := StandardMaterial3D.new()
 mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
 mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
 mat.albedo_color = Color(.23,.75,.89,.30) if str(spec.rig)=="horned" else Color(.92,.34,.24,.27)
 mat.emission_enabled = true
 mat.emission = mat.albedo_color
 qi_ring.material_override = mat
 body.add_child(qi_ring)
func _refresh_plate() -> void:
 plate.text = "%s\n%d/%d" % [str(spec.label),hp,int(spec.hp)]
 plate.modulate = Color("f2d6c5") if str(spec.kind)=="beast" else Color("ddd7b7")
func set_active(value: bool) -> void:
 active = value
 visible = value
 set_physics_process(value)
 body.collision_layer = 128 if value and hp > 0 else 0
 hurtbox.collision_layer = 256 if value and hp > 0 else 0
func take_hit(damage: int, from_position: Vector3) -> int:
 if hp <= 0 or not active: return 0
 var dealt := mini(hp,maxi(0,damage))
 hp -= dealt
 elapsed = 0
 if hp == 0:
  state = "DOWN"
  body.collision_layer = 0
  hurtbox.collision_layer = 0
  _play("Death",.08)
 else:
  state = "HURT"
  var away := (body.position-from_position)*Vector3(1,0,1)
  if away.length() > .01: body.velocity = away.normalized()*3
  _play("Idle_HitReact1",.08)
 _refresh_plate()
 life_changed.emit(str(spec.id),hp)
 return dealt
func _physics_process(delta: float) -> void:
 if not active or hp <= 0: return
 elapsed += delta
 decision_timer -= delta
 var player: Vector3 = host.actor.global_position
 var to_player := (player-body.global_position)*Vector3(1,0,1)
 var distance := to_player.length()
 var is_beast := str(spec.kind)=="beast"
 var from_home := (body.position-home)*Vector3(1,0,1)
 if qi_ring != null:
  qi_ring.rotate_z(delta*.7)
  var sigil: StandardMaterial3D = qi_ring.material_override
  var tone := sigil.albedo_color
  tone.a = .7 if state in ["WINDUP","STRIKE"] else .27
  sigil.albedo_color = tone
 if state == "HURT" and elapsed > .55: _change("RECOVER")
 elif state == "RECOVER" and elapsed > .55: _change("CHASE" if is_beast and distance < float(spec.aggro) else "IDLE")
 elif state == "WINDUP":
  _face(to_player,delta*9)
  if elapsed >= float(spec.windup[combo_index]): _change("STRIKE")
 elif state == "STRIKE":
  var hit_at: float = float(spec.hit_time[combo_index])
  if not hit_done and elapsed >= hit_at:
   hit_done = true
   _attack_area()
  if elapsed >= hit_at+.28:
   if combo_index+1 < spec.combo.size() and distance < 4.2:
    combo_index += 1
    _change("WINDUP")
   else:
    combo_index = 0
    _change("RECOVER")
 elif is_beast and state not in ["HURT","RECOVER"]:
  if from_home.length() > float(spec.leash): _change("RETURN")
  elif distance < float(spec.aggro) and distance > 3.5: _change("CHASE")
  elif distance <= 3.5 and state != "WINDUP": combo_index = 0; _change("WINDUP")
  elif state == "CHASE" and distance >= float(spec.aggro): _change("RETURN")
  elif state == "RETURN" and from_home.length() < 2: _change("IDLE")
 if decision_timer < 0:
  decision_timer = rng.randf_range(3,6)
  wandering = home+Vector3(rng.randf_range(-1,1),0,rng.randf_range(-1,1))*float(spec.get("home_radius",6))
 var desired := Vector3.ZERO
 if state == "CHASE" and distance > 1: desired = to_player.normalized()*5.2
 elif state == "RETURN" and from_home.length() > 1: desired = -from_home.normalized()*4
 elif state == "IDLE" and not is_beast:
  var to_wander := (wandering-body.position)*Vector3(1,0,1)
  if to_wander.length() > 1: desired = to_wander.normalized()*1.15
 body.velocity.x = move_toward(body.velocity.x,desired.x,delta*8)
 body.velocity.z = move_toward(body.velocity.z,desired.z,delta*8)
 body.velocity.y = -.3 if body.is_on_floor() else body.velocity.y-23*delta
 body.move_and_slide()
 if desired.length() > .15:
  _face(desired,delta*5)
  if state not in ["WINDUP","STRIKE"]: _play("Gallop" if desired.length()>3 else "Walk",.2)
 elif state == "IDLE": _play("Eating" if not is_beast and rng.randi()%3==0 else "Idle",.3)
func _attack_area() -> void:
 if not active or host.health.dead or host.dodge_invulnerable: return
 var forward := -visual.global_basis.z
 var player_delta: Vector3 = (host.actor.global_position-body.global_position)*Vector3(1,0,1)
 if player_delta.length() > 3.1 or forward.dot(player_delta.normalized()) < .15: return
 var space := get_world_3d().direct_space_state
 var sphere := SphereShape3D.new()
 sphere.radius = 1.45
 var query := PhysicsShapeQueryParameters3D.new()
 query.shape = sphere
 query.transform.origin = body.global_position+forward*1.65+Vector3(0,1.1,0)
 query.collision_mask = 2
 query.collide_with_bodies = true
 for hit in space.intersect_shape(query,8):
  if hit.collider != host.actor: continue
  host.health.hp = maxi(0,host.health.hp-int(spec.damage))
  host.health.stun = .35
  host.health.hurt_count += 1
  if host.health.hp == 0: host.health.dead = true
  host.hit_variant = "Hit_Reaction"
  host.start_action("Hit_Reaction")
  host.fx.impact(host.actor.global_position+Vector3.UP,player_delta.normalized())
  break
func _change(next: String) -> void:
 if state == next: return
 state = next
 elapsed = 0
 hit_done = false
 if next == "WINDUP": _play("Idle_2",.15)
 elif next == "STRIKE": _play(str(spec.combo[combo_index]),.06)
 elif next == "IDLE": _play("Idle",.2)
func _face(direction: Vector3, weight: float) -> void:
 if direction.length() > .01: visual.rotation.y = lerp_angle(visual.rotation.y,atan2(-direction.x,-direction.z),minf(1,weight))
func _play(clip: String, blend: float) -> void:
 if animator.has_animation(clip) and animator.current_animation != clip: animator.play(clip,blend)
func save_state() -> Dictionary:
 return {"hp":hp,"position":[body.position.x,body.position.y,body.position.z]}
func load_state(data: Dictionary) -> void:
 hp = clampi(int(data.get("hp",int(spec.hp))),0,int(spec.hp))
 var pos: Array = data.get("position",[])
 if pos.size()==3:
  var restored := Vector3(float(pos[0]),float(pos[1]),float(pos[2]))
  if restored.is_finite() and restored.distance_to(home)<float(spec.get("leash",20))+8: body.position = restored
 if hp==0: state="DOWN";body.collision_layer=0;hurtbox.collision_layer=0;_play("Death",.05)
 _refresh_plate()
