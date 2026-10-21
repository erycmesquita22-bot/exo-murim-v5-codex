extends RefCounted
# Trusted bridge: Bestiary 03 proposes; existing Combat executes hits and owns damage.
var w:Node3D
var accepted:int=0
var released:int=0
func _init(world:Node3D):w=world
func visible(a:Node3D)->bool:
 var ray:=PhysicsRayQueryParameters3D.create(a.position+Vector3.UP,w.player.position+Vector3.UP,1|4)
 ray.exclude=[a.get_rid(),w.player.get_rid()]
 return w.get_world_3d().direct_space_state.intersect_ray(ray).is_empty()
func can_begin(a:Node3D)->bool:
 if not a.has_meta("bestiary03_profile"):return true
 if not ProjectSettings.get_setting("exo_murim/convergence4/bestiary_tactics",true):return true
 if w.current_region<0 or a.hp<=0 or not a.enabled or w.changing_region or w.health<=0 or w.is_safe(w.player.position):return false
 if a.root_timer>0 or a.stagger>0 or a.cooldown>0 or a.attack_time>=0 or not visible(a):return false
 var members:Array=[];var winding:int=0
 for other in w.enemies:
  if not is_instance_valid(other) or other.hp<=0 or not other.has_meta("bestiary03_profile"):continue
  if other.position.distance_to(w.player.position)>12.0:continue
  if other.attack_time>=0:winding+=1
  if members.size()>=8:continue
  members.append({"uid":str(other.uid),"profile_id":str(other.get_meta("bestiary03_profile")),"region_id":w.current_region,"position":other.position,"hp_ratio":float(other.hp)/maxf(1.0,float(other.max_hp)),"attack_ready":other.cooldown<=0 and other.attack_time<0 and other.stagger<=0 and other.root_timer<=0,"target_visible":true,"line_of_sight":visible(other)})
 if winding>=2 or members.is_empty():return false
 var group:Dictionary=w.exo_core.services.invoke("bestiary.tactics","plan_group",[{"group_id":"physical/r"+str(w.current_region),"region_id":w.current_region,"target_position":w.player.position,"combat_seconds":float(w.elapsed),"max_attackers":2,"members":members}])
 if group.get("status")!="PROPOSED" or not group.get("orders",{}).has(str(a.uid)):return false
 var order:Dictionary=group.orders[str(a.uid)]
 var snapshot:Dictionary={"hp_ratio":float(a.hp)/maxf(1.0,float(a.max_hp)),"territory_exists":true,"outside_territory":a.leashing,"safe_zone":w.is_safe(w.player.position),"target_visible":true,"target_defeated":w.health<=0,"distance":a.position.distance_to(w.player.position),"attack_ready":true,"line_of_sight":visible(a),"flank_reached":false}
 var decision:Dictionary=w.exo_core.services.invoke("bestiary.tactics","plan_actor",[str(a.get_meta("bestiary03_profile")),snapshot,order])
 # Only these catalogue attacks have a verified existing physical swing executor.
 if decision.get("intent")!="attack" or str(decision.get("attack_id",""))!="short_slash":return false
 a.set_meta("bestiary03_attack",str(decision.attack_id));a.set_meta("bestiary03_accepted",int(a.get_meta("bestiary03_accepted",0))+1)
 accepted+=1;return true
func can_release(a:Node3D)->bool:
 if not a.has_meta("bestiary03_profile") or not ProjectSettings.get_setting("exo_murim/convergence4/bestiary_tactics",true):return true
 if w.current_region<0 or a.hp<=0 or w.health<=0 or w.is_safe(w.player.position) or a.leashing or a.stagger>0 or a.root_timer>0 or not visible(a):return false
 var attack:Dictionary=w.exo_core.services.invoke("bestiary.combat","attack_profile",[str(a.get_meta("bestiary03_attack",""))])
 if attack.is_empty() or a.position.distance_to(w.player.position)>float(attack.range):return false
 released+=1;return true
