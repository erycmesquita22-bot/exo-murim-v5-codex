extends "res://exo_bestiary/creatures/creature_actor.gd"
# R5: ator R4 com harmonizacao opcional de visuais; gameplay continua no host.
# Nenhuma segunda fonte de spawn, loot, experiência ou save.
var world: Node3D
var uid: String = ""
var kind: String = "fauna"
var display_name: String = "Fera selvagem"
var hp: int = 1
var max_hp: int = 1
var slow:float=0.0
var stagger:float=0.0
var root_timer:float=0.0
var cooldown: float = 0.0
var attack_time: float = -1.0
var interest_seconds: float = 0.0
var enabled: bool = true
var _fatal_pending: bool = false
const R5VisualBinding = preload("res://exo_creature_harmonizacao02/integration/runtime_visual_binding.gd")
var _r5_visual: Dictionary = {}
var _r5_visual_lock: float = 0.0

func setup_regional(owner: Node3D, persistent_id: String, profile: Dictionary, point: Vector3, variant: int) -> void:
    world=owner
    uid=persistent_id
    position=point
    home=point
    max_hp=maxi(1,int(profile.get("stats",{}).get("hp",20)))
    hp=max_hp
    kind="fauna"
    display_name=str(profile.get("name","Fera selvagem"))
    collision_layer=4
    collision_mask=1 | 2 | 4
    set_meta("ecology_species",str(profile.get("id","")))
    configure(profile,variant)
    _install_harmonized_visual(str(profile.get("id", "")))
    # Host central aplica dano apenas após validação da distância e do ataque.
    attack_requested.connect(_execute_authorized_attack)

func step(_delta: float) -> void:
    # O CreatureActor já usa _physics_process, portanto não executar uma segunda vez.
    pass

func _physics_process(delta: float) -> void:
    if hp<=0 or not enabled or not is_instance_valid(world) or not is_instance_valid(world.player):return
    if world.changing_region or not world.simulation_enabled or world.get_tree().paused:return
    if world.flow.phase!="adventure" or world.flow.lab_mode or world.trial_mode:return
    if not is_instance_valid(world.active_region) or int(world.current_region)!=int(get_meta("ecology_region",-999)):return
    slow=maxf(0.0,slow-delta);stagger=maxf(0.0,stagger-delta);root_timer=maxf(0.0,root_timer-delta)
    if stagger>0 or root_timer>0:
        velocity.x=move_toward(velocity.x,0.0,delta*16.0);velocity.z=move_toward(velocity.z,0.0,delta*16.0)
        velocity.y=velocity.y-18.0*delta if not is_on_floor() else -0.1
        move_and_slide();_r5_visual_tick(delta);return
    cooldown=maxf(0.0,cooldown-delta)
    interest_seconds=maxf(0.0,interest_seconds-delta)
    if cooldown>0.0:
        external_target=null
        attack_delay=maxf(attack_delay,cooldown)
    else:
        var d: float=global_position.distance_to(world.player.global_position)
        var temperament: String=str(species.get("behavior",""))
        # Herbívoros fogem do jogador; predadores e territoriais reagem de perto.
        if d<12.0 and temperament in ["predator","territorial","prey"] and not world.is_safe(world.player.position):
            external_target=world.player
        elif external_target==world.player:
            external_target=null
    super._physics_process(delta)
    _r5_visual_tick(delta)

func _install_harmonized_visual(species_id: String) -> void:
    # Opt-out global e fallback: zero alteracao no catalogo, hitbox ou save.
    if not bool(ProjectSettings.get_setting("exo_murim/r5/harmonized_creatures_enabled", true)):
        return
    if species_id.is_empty() or world == null or world.exo_core == null:
        return
    if not world.exo_core.services.has_service("creatures.visuals"):
        return
    var descriptor: Variant = world.exo_core.services.invoke("creatures.visuals", "get_visual", [species_id])
    if not descriptor is Dictionary or descriptor.is_empty():
        return
    _r5_visual = R5VisualBinding.attach_visual(visual, descriptor)
    if not _r5_visual.is_empty():
        set_meta("harmonized_visual_r5", species_id)
        R5VisualBinding.play_action(_r5_visual, "idle")

func _r5_visual_tick(delta: float) -> void:
    if _r5_visual.is_empty():
        return
    _r5_visual_lock = maxf(0.0, _r5_visual_lock - delta)
    if _r5_visual_lock > 0.0:
        return
    var planar_speed: float = Vector2(velocity.x, velocity.z).length()
    var max_speed: float = maxf(0.1, float(species.get("stats", {}).get("speed", 3.5)))
    var anim: String = "idle"
    if planar_speed > max_speed * 0.7:
        anim = "run"
    elif planar_speed > 0.15:
        anim = "walk"
    R5VisualBinding.play_action(_r5_visual, anim)

func _r5_play_action(anim: String, hold_seconds: float) -> void:
    if _r5_visual.is_empty():
        return
    if R5VisualBinding.play_action(_r5_visual, anim):
        _r5_visual_lock = maxf(_r5_visual_lock, hold_seconds)

func hurt(amount: int, impulse: Vector3, _slow_seconds: float=0.0, _context: Dictionary={}) -> bool:
    if hp<=0 or _fatal_pending or not enabled or world==null:return false
    if world.current_region!=int(get_meta("ecology_region",-999)):return false
    slow=maxf(slow,_slow_seconds)
    hp=maxi(0,hp-maxi(0,amount))
    world.target=self
    world.combat_timer=4
    set_life_fraction(float(hp)/float(max_hp))
    if hp>0:
        _r5_play_action("hit", 0.22)
        velocity+=Vector3(impulse.x,0,impulse.z)*0.2
        interest_seconds=6.0
        return true
    _fatal_pending=true
    visible=false
    collision_layer=0
    set_physics_process(false)
    world.enemy_defeated(self) # único dono dos recibos e da transação
    return true

func revive_after_failed_commit() -> void:
    hp=maxi(1,hp)
    _fatal_pending=false
    set_life_fraction(float(hp)/float(max_hp))
    visible=true
    collision_layer=4
    attack_delay=3.0
    cooldown=3.0
    set_physics_process(true)

func restore(defeated: bool) -> void:
    _fatal_pending=defeated
    hp=0 if defeated else max_hp
    set_life_fraction(float(hp)/float(max_hp))
    position=home
    velocity=Vector3.ZERO
    visible=not defeated
    collision_layer=0 if defeated else 4
    set_physics_process(not defeated)

func _execute_authorized_attack(source: Node3D, target: Node3D, attack_id: String) -> void:
    if source!=self or hp<=0 or _fatal_pending or cooldown>0 or not is_instance_valid(target):return
    if world==null or target!=world.player or world.flow.phase!="adventure":return
    if world.is_safe(world.player.position) or world.current_region!=int(get_meta("ecology_region",-999)):return
    if attack_id not in species.get("attacks",[]):return
    # Catálogo carregado por EXO Core; nunca aceitar dano para ataque desconhecido.
    var catalog: Variant=world.exo_core.services.invoke("bestiary.catalog","get_profile",[str(species.get("id",""))])
    if not catalog is Dictionary or catalog.is_empty():return
    var allowed: Dictionary=world.exo_core.services.invoke("bestiary.combat","attack_profile",[attack_id])
    if allowed.is_empty():return
    var distance: float=float(allowed.get("range",0.0))
    var to_player: Vector3=world.player.position-position
    to_player.y=0
    if distance<=0 or to_player.length()>distance+0.25:return
    if not world.can_hit(position,world.player.position,to_player.normalized(),distance+0.25,-1):return
    # Animacao nao dispara dano: evento e alcance ja foram autorizados pelo host.
    _r5_play_action("attack", 0.34)
    # Dano de fauna validado pelo combate do jogador (esquiva, defesa e escudo).
    var damage: int=int(allowed.get("damage",5))
    world.damage_player(damage,{"family":"fauna","species":str(species.get("id",""))})

func movement_multiplier()->float:return .45 if slow>0 else 1.0
func apply_control(force:Vector3,root_seconds:float):
    velocity+=force
    root_timer=maxf(root_timer,root_seconds)
