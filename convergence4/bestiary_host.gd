extends RefCounted
# Bestiary proposes roles/slots; existing physical actors and PlayerCombat execute.
var w:Node3D
var accepted:int=0
var released:int=0
var orders:Dictionary={}
var next_plan:float=-1.0
const EXECUTORS=["short_slash","quick_slash","spear_thrust","arrow","qi_palm","counter"]
func _init(world:Node3D):w=world
func visible(a:Node3D)->bool:
 var ray:=PhysicsRayQueryParameters3D.create(a.position+Vector3.UP,w.player.position+Vector3.UP,1|4)
 ray.exclude=[a.get_rid(),w.player.get_rid()]
 return w.get_world_3d().direct_space_state.intersect_ray(ray).is_empty()
func _plan()->void:
 if float(w.elapsed)<next_plan:return
 next_plan=float(w.elapsed)+0.12;orders.clear()
 if w.current_region<0:return
 var nearby:Array=[]
 for actor in w.enemies:
  if is_instance_valid(actor) and actor.hp>0 and actor.has_meta("bestiary03_profile") and actor.position.distance_to(w.player.position)<16:nearby.append(actor)
 nearby.sort_custom(func(a,b):return a.position.distance_squared_to(w.player.position)<b.position.distance_squared_to(w.player.position))
 var members:Array=[]
 for actor in nearby.slice(0,8):
  members.append({"uid":str(actor.uid),"profile_id":str(actor.get_meta("bestiary03_profile")),"region_id":w.current_region,"position":actor.position,"hp_ratio":float(actor.hp)/maxf(1.0,float(actor.max_hp)),"attack_ready":actor.cooldown<=0 and actor.attack_time<0 and actor.stagger<=0 and actor.root_timer<=0,"target_visible":true,"line_of_sight":visible(actor)})
 if members.is_empty():return
 var result:Dictionary=w.exo_core.services.invoke("bestiary.tactics","plan_group",[{"group_id":"physical/r"+str(w.current_region),"region_id":w.current_region,"target_position":w.player.position,"combat_seconds":float(w.elapsed),"max_attackers":2,"target_in_safe_zone":w.is_safe(w.player.position),"members":members}])
 if result.get("status")=="PROPOSED":orders=result.get("orders",{})
func _order(a:Node3D)->Dictionary:
 _plan()
 return orders.get(str(a.uid),{})
func tactical_velocity(a:Node3D)->Vector3:
 if not a.has_meta("bestiary03_profile") or not bool(ProjectSettings.get_setting("exo_murim/convergence4/bestiary_tactics",true)):return Vector3.INF
 var order:Dictionary=_order(a)
 if order.is_empty():return Vector3.ZERO
 var profile:Dictionary=w.exo_core.services.invoke("bestiary.catalog","get_profile",[str(a.get_meta("bestiary03_profile"))])
 var toward:Vector3=w.player.position-a.position;toward.y=0
 var distance:float=toward.length()
 var ranged:bool=str(order.get("role","")) in ["ranged","support"]
 var attack_range:float=2.0
 for id in profile.get("attacks",[]):
  if id not in EXECUTORS:continue
  var attack:Dictionary=w.exo_core.services.invoke("bestiary.combat","attack_profile",[str(id)])
  attack_range=maxf(attack_range,float(attack.get("range",0.0)))
 var preferred:Array=profile.get("preferred_distance",[1.5,2.5])
 var radius:float=minf((float(preferred[0])+float(preferred[1]))*.5,attack_range-.16)
 if str(order.get("role",""))=="flanker":radius=minf(radius,1.18)
 var hint:Vector3=order.get("position_hint",w.player.position)
 var radial:Vector3=hint-w.player.position;radial.y=0
 hint=w.player.position+radial.normalized()*radius
 a.set_meta("tactical_role",str(order.get("role","pressure")))
 a.set_meta("tactical_destination",hint)
 if ranged and distance<float(preferred[0]):return -toward.normalized()*3.4
 var drift:Vector3=hint-a.position;drift.y=0
 var desired:Vector3=drift.normalized()*2.65 if drift.length()>.45 else Vector3.ZERO
 # Local separation prevents actors sharing a ring point or blocking the shooter.
 for other in w.enemies:
  if other==a or not is_instance_valid(other) or other.hp<=0:continue
  var away:Vector3=a.position-other.position;away.y=0
  if away.length_squared()>.001 and away.length()<1.05:desired+=away.normalized()*(1.05-away.length())*3.0
 return desired.limit_length(3.6)
func can_begin(a:Node3D)->bool:
 if not a.has_meta("bestiary03_profile") or not bool(ProjectSettings.get_setting("exo_murim/convergence4/bestiary_tactics",true)):return true
 if w.current_region<0 or a.hp<=0 or not a.enabled or w.changing_region or w.health<=0 or w.is_safe(w.player.position):return false
 if a.root_timer>0 or a.stagger>0 or a.cooldown>0 or a.attack_time>=0 or not visible(a):return false
 var winding:int=0
 for other in w.enemies:
  if is_instance_valid(other) and other.hp>0 and other.attack_time>=0:winding+=1
 if winding>=2:return false
 var order:Dictionary=_order(a)
 if order.is_empty():return false
 var hint:Vector3=a.get_meta("tactical_destination",a.position)
 var snapshot:Dictionary={"hp_ratio":float(a.hp)/maxf(1.0,float(a.max_hp)),"territory_exists":true,"outside_territory":a.leashing,"safe_zone":false,"target_visible":true,"target_defeated":false,"distance":a.position.distance_to(w.player.position),"attack_ready":true,"line_of_sight":true,"flank_reached":a.position.distance_to(hint)<1.2}
 var decision:Dictionary=w.exo_core.services.invoke("bestiary.tactics","plan_actor",[str(a.get_meta("bestiary03_profile")),snapshot,order])
 if decision.get("intent")!="attack" or str(decision.get("attack_id","")) not in EXECUTORS:return false
 a.set_meta("bestiary03_attack",str(decision.attack_id));a.set_meta("bestiary03_accepted",int(a.get_meta("bestiary03_accepted",0))+1)
 accepted+=1;return true
func can_release(a:Node3D)->bool:
 if not a.has_meta("bestiary03_profile") or not bool(ProjectSettings.get_setting("exo_murim/convergence4/bestiary_tactics",true)):return true
 if w.current_region<0 or a.hp<=0 or w.health<=0 or w.is_safe(w.player.position) or a.leashing or a.stagger>0 or a.root_timer>0 or not visible(a):return false
 var attack:Dictionary=w.exo_core.services.invoke("bestiary.combat","attack_profile",[str(a.get_meta("bestiary03_attack",""))])
 if attack.is_empty() or a.position.distance_to(w.player.position)>float(attack.range):return false
 released+=1;return true
