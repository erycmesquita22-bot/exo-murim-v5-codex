extends CharacterBody3D
# ATOR FÍSICO APENAS DE FAUNA. Não substitui enemy.gd ou PlayerCombat.
# Ataques são sinais de INTENÇÃO. A gameplay autoritativa decide execução/dano.
signal attack_requested(source: Node3D, target: Node3D, attack_id: String)
const Visuals=preload("res://exo_bestiary/rendering/creature_visuals.gd")
const Animate=preload("res://exo_bestiary/rendering/animation_profiles.gd")
const AI=preload("res://exo_bestiary/ai/behavior_controller.gd")
var species: Dictionary = {}
var controller
var visual
var home: Vector3
var life: float = 1.0
var is_hungry: bool = true
var external_target: Node3D
var think_delay: float = .0
var attack_delay: float = .0
var clock: float = .0
var intent: Dictionary={"state":"IDLE","intent":"none"}
func configure(profile: Dictionary, palette_index: int=0) -> void:
    species=profile.duplicate(true)
    home=global_position
    if controller==null:controller=AI.new()
    controller.configure(species)
    if visual==null:
        visual=Visuals.new();add_child(visual)
        var collision:=CollisionShape3D.new();collision.name="VoxelCollision"
        var shape:=CapsuleShape3D.new();shape.radius=.45;shape.height=1.8
        collision.position.y=.9;collision.shape=shape;add_child(collision)
    visual.build(species,palette_index)
    add_to_group("exo_wildlife")
func _physics_process(delta: float) -> void:
    if species.is_empty() or controller==null:return
    clock+=delta;think_delay-=delta;attack_delay=maxf(0.0,attack_delay-delta)
    if think_delay<=0.0:
        think_delay=.25
        if not is_instance_valid(external_target): _auto_select_target()
        _decide()
    var direction:=Vector3.ZERO
    var target: Node3D=external_target if is_instance_valid(external_target) else null
    var action: String=str(intent.get("intent","none"))
    var delta_target:=Vector3.ZERO
    if target!=null:
        delta_target=target.global_position-global_position;delta_target.y=0.0
    if action in ["approach","attack"] and delta_target.length()>.8:direction=delta_target.normalized()
    elif action in ["flee","retreat","position"] and delta_target.length()>.2:direction=-delta_target.normalized()
    elif action=="go_home":
        direction=home-global_position;direction.y=0.0
        if direction.length()>.3:direction=direction.normalized()
    elif action=="patrol":
        var desired:=home+Vector3(cos(clock*.5)*2.0,0,sin(clock*.5)*2.0)
        direction=desired-global_position;direction.y=0.0
        if direction.length()>.5:direction=direction.normalized()
    var top_speed: float=float(species.get("stats",{}).get("speed",3.5))*movement_multiplier()
    velocity.x=move_toward(velocity.x,direction.x*top_speed,delta*12.0)
    velocity.z=move_toward(velocity.z,direction.z*top_speed,delta*12.0)
    velocity.y=velocity.y-18.0*delta if not is_on_floor() else -0.1
    move_and_slide()
    var horizontal:=Vector3(velocity.x,0,velocity.z)
    if horizontal.length()>.2:visual.rotation.y=lerp_angle(visual.rotation.y,atan2(-horizontal.x,-horizontal.z),minf(delta*8.0,1.0))
    Animate.pose(visual.leg_pivots,visual.tail_pivot,clock,horizontal.length()/maxf(.1,top_speed),str(intent.get("state","IDLE")))
    if action=="attack" and target!=null and attack_delay<=0.0 and not species.get("attacks",[]).is_empty():
        attack_delay=1.35
        attack_requested.emit(self,target,str(species.attacks[0]))
func _decide() -> void:
    var target: Node3D=external_target if is_instance_valid(external_target) else null
    var d:=INF
    var seen:=false
    if target!=null:
        d=global_position.distance_to(target.global_position)
        seen=d<=float(species.get("stats",{}).get("perception",14.0))
        if seen:
            var from: Vector3=global_position+Vector3.UP*.9
            var to: Vector3=target.global_position+Vector3.UP*.9
            var query:=PhysicsRayQueryParameters3D.create(from,to)
            query.exclude=[get_rid()]
            var hit: Dictionary=get_world_3d().direct_space_state.intersect_ray(query)
            seen=hit.is_empty() or hit.get("collider")==target
    var outside:=global_position.distance_to(home)>float(species.get("territory_radius",24.0))
    var prey: bool=str(species.get("behavior",""))=="prey"
    var ctx: Dictionary={"hp_ratio":life,"territory_exists":true,"outside_territory":outside,"target_visible":seen,"distance":d,"attack_ready":attack_delay<=0.0,"line_of_sight":seen,"predator_visible":prey and seen,"target_threat":prey and seen,"intruding":seen,"hungry":is_hungry,"allies":0}
    intent=controller.step(ctx,.25)
    if str(intent.get("intent",""))=="attack" and d>_range():intent={"state":"APPROACH","intent":"approach"}
func _range() -> float:
    return 1.55 if str(species.get("visual_family",""))!="serpent" else 1.0

func _auto_select_target() -> void:
    # Busca local somente no nível de simulação física (região ativa).
    # Não simula as 88 regiões nem executa consultas globais por quadro.
    var behavior: String=str(species.get("behavior",""))
    if behavior not in ["prey","predator"]:return
    var best_distance: float=float(species.get("stats",{}).get("perception",12.0))
    var best: Node3D=null
    for item in get_tree().get_nodes_in_group("exo_wildlife"):
        if item==self or not item is Node3D:continue
        var other: Node3D=item
        var other_species: Variant=other.get("species")
        if not other_species is Dictionary:continue
        var other_type: String=str(other_species.get("behavior",""))
        if behavior=="prey" and other_type!="predator":continue
        if behavior=="predator" and other_type!="prey":continue
        var distance: float=global_position.distance_to(other.global_position)
        if distance<best_distance:
            best_distance=distance
            best=other
    external_target=best
func set_life_fraction(value: float) -> void:
    # Apenas recebe saúde do proprietário do combate; sem novo cálculo de dano.
    life=clampf(value,0.0,1.0)
func on_region_unload() -> void:
    # O Regional Ecology administra persistência, geração, e descarregamento.
    set_physics_process(false)
    external_target=null
    queue_free()

func movement_multiplier()->float:return 1.0
