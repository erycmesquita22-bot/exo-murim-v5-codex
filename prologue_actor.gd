extends "res://enemy.gd"
const Arsenal=preload("res://arsenal.gd")
const Catalog=preload("res://catalog.gd")
var faction:=0
var victim:Node3D
var color:=Color.WHITE
var clashes:=0
var technique_clock:=1.0
var technique_windup:=-1.0
var technique_target:=Vector3.ZERO
var skill_data:Dictionary={}
var skills_released:int=0
var projectiles_released:int=0
var travelled:float=0.0
var projectiles:Array=[]
var retarget_clock:float=0.0
var guard_left:float=0.0
var guardian:CharacterBody3D
var guardian_rig:Node3D
var guardian_life:float=0.0
var guardian_cooldown:float=0.0
var fields:Array=[]
var channel_left:float=0.0
var channel_delay:float=0.0

func _opponents()->Array:
    var result:Array=[]
    for actor in world.enemies:
        if actor!=self and is_instance_valid(actor) and actor.hp>0 and actor.faction!=faction:result.append(actor)
    result.append(world.player)
    return result
func _hit(target:Node3D,damage:int,force:Vector3,root_seconds:float=0.0)->void:
    if target==world.player:world.damage_player(damage,{"family":"qi","magic":true})
    else:
        target.hurt(damage,force,0.0,{"family":"qi","magic":true})
        if root_seconds>0:target.apply_control(force,root_seconds)
func _shoot(direction:Vector3,damage:int)->void:
    var node:MeshInstance3D=world.techniques.sphere(.16,color)
    node.position=position+Vector3.UP
    projectiles.append({"node":node,"direction":direction,"remaining":1.6,"damage":damage})
    world.effects.append({"node":node,"time":1.7})
    projectiles_released+=1
func _projectiles(delta:float)->void:
    for index in range(projectiles.size()-1,-1,-1):
        var shot:Dictionary=projectiles[index]
        if not is_instance_valid(shot.node):projectiles.remove_at(index);continue
        shot.remaining-=delta
        var distance:float=delta*12.0
        var struck:bool=false
        for substep in range(maxi(1,ceili(distance/.25))):
            var from:Vector3=shot.node.position
            var to:Vector3=from+shot.direction*minf(.25,distance)
            var ray:=PhysicsRayQueryParameters3D.create(from,to,1|4)
            ray.exclude=[get_rid()]
            var wall:Dictionary=world.get_world_3d().direct_space_state.intersect_ray(ray)
            if not wall.is_empty() and wall.collider not in _opponents():struck=true;break
            shot.node.position=to
            for target in _opponents():
                if target.position.distance_to(to-Vector3.UP)<.85:
                    _hit(target,int(shot.damage),shot.direction*1.8)
                    world.techniques.burst(to,color,5);struck=true;break
            if struck:break
            distance-=minf(.25,distance)
        if struck or shot.remaining<=0:
            shot.node.hide()
            projectiles.remove_at(index)
func _clear_guardian()->void:
    if is_instance_valid(guardian):guardian.queue_free()
    guardian=null;guardian_rig=null
func _exit_tree()->void:_clear_guardian()
func _summon_guardian()->void:
    _clear_guardian()
    guardian=CharacterBody3D.new();guardian.collision_layer=8;guardian.collision_mask=1|4
    var collision:=CollisionShape3D.new();var shape:=CapsuleShape3D.new();shape.radius=.28;shape.height=1.9
    collision.shape=shape;collision.position.y=.95;guardian.add_child(collision)
    world.add_child(guardian);guardian.position=position+Vector3(1.0,.05,0)
    guardian_rig=world.Rig.new();guardian.add_child(guardian_rig)
    preload("res://wardrobe.gd").apply(guardian_rig,{"race":0,"robe":3,"hair":2,"skin":3,"style":2,"weapon":"spear"})
    guardian_life=5.0;guardian_cooldown=0
    world.techniques.ring(guardian.position,1.0,color,.4)
func _persistent_skills(delta:float)->void:
    if is_instance_valid(guardian):
        guardian_life-=delta;guardian_cooldown-=delta
        var target:Node3D=null;var nearest:float=INF
        for candidate in _opponents():
            var d:float=guardian.position.distance_to(candidate.position)
            if d<nearest:nearest=d;target=candidate
        if target!=null:
            var toward:Vector3=target.position-guardian.position;toward.y=0
            guardian.velocity.x=toward.normalized().x*3.5 if nearest>1.7 else 0.0
            guardian.velocity.z=toward.normalized().z*3.5 if nearest>1.7 else 0.0
            guardian.velocity.y=guardian.velocity.y-20*delta if not guardian.is_on_floor() else -.1
            guardian.move_and_slide()
            guardian_rig.rotation.y=atan2(-toward.x,-toward.z)
            guardian_rig.pose(world.elapsed,false,false,guardian.is_on_floor())
            guardian_rig.locomotion(guardian.get_real_velocity(),delta,false,guardian.is_on_floor(),true)
            if guardian_cooldown<=0 and world.can_hit(guardian.position,target.position,toward.normalized(),2.3,-1):
                _hit(target,8,toward.normalized());guardian_cooldown=.75
                world.spawn_arc(guardian.position,toward.normalized(),2.3,color,.16)
        if guardian_life<=0:_clear_guardian()
    for index in range(fields.size()-1,-1,-1):
        var field:Dictionary=fields[index];field.life-=delta;field.cooldown-=delta
        if field.cooldown<=0:
            field.cooldown=.65
            for target in _opponents():
                if world.can_hit(field.point,target.position,Vector3.FORWARD,2.4,-1):_hit(target,6,Vector3.ZERO,.25)
            world.techniques.burst(field.point+Vector3.UP*.2,color,4)
        if field.life<=0:fields.remove_at(index)
    channel_left=maxf(0.0,channel_left-delta);channel_delay-=delta
    if channel_left>0 and channel_delay<=0 and is_instance_valid(victim):
        var direction:Vector3=victim.position-position;direction.y=0
        _shoot(direction.normalized(),6);channel_delay=.18
func _release_skill(direction:Vector3)->void:
    skills_released+=1
    var kind_name:String=str(skill_data.kind)
    var damage:int=clampi(int(skill_data.get("damage",18)),10,30)
    world.audio_fx.skill(skill_data,false)
    world.techniques.burst(position+Vector3.UP,color,8)
    if world.get("vfx_host_v5")!=null:world.vfx_host_v5.release_prologue_actor(self,skill_data,skills_released,direction)
    if kind_name=="projectile":_shoot(direction,damage);return
    if kind_name=="channel":channel_left=.85;channel_delay=0;return
    if kind_name=="summon":_summon_guardian();return
    if kind_name=="trap":
        if fields.size()<2:fields.append({"point":technique_target,"life":2.5,"cooldown":0.0})
        world.techniques.ring(technique_target,2.4,color,2.5);return
    if kind_name=="shield":guard_left=2.2;world.techniques.ring(position,1.0,color,.7);return
    if kind_name=="heal":hp=mini(max_hp,hp+20);world.techniques.ring(position,1.2,color,.5);return
    if kind_name in ["dash","leap"]:forced_velocity+=direction*7.0
    if kind_name=="leap" and is_on_floor():velocity.y=5.0
    var center:Vector3=technique_target if kind_name in ["area","trap","summon"] else position
    world.techniques.ring(center,2.4,color,.3)
    for target in _opponents():
        if not world.can_hit(center,target.position,direction,3.0 if center!=position else 4.5,-1 if kind_name in ["area","repel","pull","root","trap"] else -.15):continue
        var force:Vector3=(target.position-position).normalized()*2.8
        if kind_name=="pull":force=-force
        _hit(target,damage,force,0.6 if kind_name in ["root","trap"] else 0.0)
func step(delta:float)->void:
    if hp<=0 or not enabled:return
    _projectiles(delta)
    _persistent_skills(delta)
    technique_clock-=delta;guard_left=maxf(0.0,guard_left-delta)
    cooldown=maxf(0.0,cooldown-delta);slow=maxf(0.0,slow-delta);stagger=maxf(0.0,stagger-delta)
    retarget_clock-=delta
    if retarget_clock<=0 or not is_instance_valid(victim) or (victim!=world.player and victim.hp<=0):
        retarget_clock=.45
        victim=null
        var nearest:float=INF
        for target in _opponents():
            var distance:float=position.distance_squared_to(target.position)
            if distance<nearest:nearest=distance;victim=target
        # Rotating pressure breaks isolated duels and brings the war into the
        # player's view, while the remaining heroes keep fighting one another.
        if faction%3==int(floor(world.flow.clock/4.0))%3 and position.distance_to(world.player.position)<25.0:
            victim=world.player
    if not is_instance_valid(victim):return
    var offset:Vector3=victim.position-position;offset.y=0
    var direction:Vector3=offset.normalized()
    var distance:float=offset.length()
    var spec:Dictionary=Catalog.weapon(str(rig.get_meta("weapon_id","sword")))
    var reach:float=7.5 if bool(spec.ranged) else float(spec.reach)
    if technique_clock<=0 and technique_windup<0 and stagger<=0:
        var skills:Array=Catalog.HEROES[faction].skills
        skill_data=Catalog.skill(str(skills[skills_released%skills.size()]))
        technique_target=victim.position;technique_windup=0.0
        world.techniques.ring(technique_target,2.4,color.darkened(.25),.48)
        world.audio_fx.skill(skill_data,true)
    if technique_windup>=0:
        technique_windup+=delta
        if technique_windup>=.48:
            _release_skill(direction);technique_windup=-1
            technique_clock=2.1+float(faction%4)*.23
    var tangent:=Vector3(-direction.z,0,direction.x)*(1.0 if faction%2==0 else -1.0)
    var movement:=Vector3.ZERO
    if bool(spec.ranged):
        movement=-direction*3.8 if distance<4.0 else direction*3.4 if distance>7.0 else tangent*1.8
    else:
        movement=direction*3.5 if distance>reach*.76 else tangent*1.65
    # All twelve have distinct approach angles instead of stacking at one target.
    for ally in world.enemies:
        if ally==self or ally.hp<=0:continue
        var away:Vector3=position-ally.position;away.y=0
        if away.length()>.01 and away.length()<1.0:movement+=away.normalized()*(1.0-away.length())*4
    if attack_time>=0:
        attack_time+=delta
        movement*=.55
        if attack_time>=.25 and not attack_done:
            attack_done=true;clashes+=1
            world.audio_fx.play_event("arrow" if spec.ranged else "punch" if spec.pose=="unarmed" else "swing","combat",.35)
            if spec.ranged:_shoot(attack_direction,7)
            else:
                world.spawn_arc(position,attack_direction,reach,color,.16)
                if world.can_hit(position,victim.position,attack_direction,reach,.15):
                    _hit(victim,7,attack_direction*1.4)
                    world.techniques.burst(victim.position+Vector3.UP,color,4)
        if attack_time>=.47:attack_time=-1;cooldown=.38
    elif cooldown<=0 and distance<reach and stagger<=0:
        attack_time=0;attack_done=false;attack_direction=direction;pattern+=1
    if stagger>0:movement*=.35
    if movement.length()>.01:movement=steer(movement)
    velocity.x=movement.x*(.45 if slow>0 else 1.0)
    velocity.z=movement.z*(.45 if slow>0 else 1.0)
    if not is_on_floor():velocity.y-=20*delta
    root_timer=maxf(0,root_timer-delta)
    if root_timer>0:velocity.x=0;velocity.z=0
    velocity+=forced_velocity;forced_velocity=forced_velocity.move_toward(Vector3.ZERO,delta*16)
    var before:Vector3=position;move_and_slide();travelled+=position.distance_to(before)
    rig.rotation.y=atan2(-direction.x,-direction.z)
    rig.pose(world.elapsed,false,false,is_on_floor())
    rig.locomotion(get_real_velocity(),delta,false,is_on_floor(),attack_time<0)
    Arsenal.animate(rig,spec,pattern%3,attack_time/.47 if attack_time>=0 else -1)
    if technique_windup>=0:rig.skill_pose(1,technique_windup,false,0)
    world.Anatomy.animate(rig,world.elapsed,velocity.length(),is_on_floor())
func hurt(amount:int,impulse:Vector3,slow_seconds:float=0.0,context:Dictionary={})->bool:
    if hp<=0:return false
    hp=maxi(0,hp-int(round(float(amount)*(.45 if guard_left>0 else 1.0))))
    slow=maxf(slow,slow_seconds);stagger=.08;forced_velocity+=impulse
    world.hits+=1;world.target=self
    world.audio_fx.impact(rig.get_meta("surface","body"),context)
    if hp==0:
        visible=false;collision_layer=0;_clear_guardian();fields.clear();channel_left=0
    return true
