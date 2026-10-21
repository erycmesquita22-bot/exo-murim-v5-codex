extends RefCounted
# Fortificações owns external city rings; Forja keeps existing lot courtyards.
# V03 flat compounds are never inferred from 11m Genesis house parcels.
const Planner=preload("res://fortifications/planner.gd")
const Kit=preload("res://godot/modular_kit.gd")
const RiverGate=preload("res://fortifications/river_gate.gd")
static func box(parent: Node3D,center: Vector3,size: Vector3) -> void:
 var body:=StaticBody3D.new();body.collision_layer=4;parent.add_child(body)
 var cs:=CollisionShape3D.new();cs.shape=BoxShape3D.new();cs.shape.size=size;cs.position=center;body.add_child(cs)
static func apply(region: Node3D) -> Dictionary:
 var data: RefCounted=region.data
 if data.spec.kind!="settlement":return {"status":"not_applicable"}
 if data.spec.settlement_scale!="city":return {"status":"existing_courtyards","owner":"forja","external_ring":false}
 var begin: int=Time.get_ticks_usec()
 var plan: Dictionary=Planner.plan_region(data)
 if plan.status!="ready":
  return {"status":"BLOCKED","planner_status":plan.status,"owner":"fortifications","reason":"incomplete_perimeter","rendered":false}
 var holder:=Node3D.new();holder.name="EXOCityPerimeter";region.add_child(holder)
 Kit.ensure()
 for wall in plan.segments:
  var a: Vector2=wall.a;var b: Vector2=wall.b;var d: Vector2=b-a
  var base: float=float(wall.base);var h: float=float(wall.top)-base
  var visual: Node3D=Kit.place(holder,"city_wall_stone_2m",Vector3((a.x+b.x)*.5,base,(a.y+b.y)*.5),-atan2(d.y,d.x),"",false)
  visual.scale=Vector3(d.length()/2.22,h/3.3,1.0)
  var body:=StaticBody3D.new();body.collision_layer=4;holder.add_child(body)
  var shape:=CollisionShape3D.new();shape.shape=BoxShape3D.new();shape.shape.size=Vector3(d.length(),h,.62)
  body.add_child(shape);shape.position=Vector3((a.x+b.x)*.5,base+h*.5,(a.y+b.y)*.5);shape.rotation.y=-atan2(d.y,d.x)
 for tower in plan.towers:
  var visual: Node3D=Kit.place(holder,"watchtower_stone_4m",Vector3(tower.p.x,tower.height,tower.p.y),0,"",false)
  # Collider footprint excludes roof overhang; towers are closed volumes.
  var body:=StaticBody3D.new();body.collision_layer=4;visual.add_child(body)
  var cs:=CollisionShape3D.new();cs.shape=BoxShape3D.new();cs.shape.size=Vector3(4,6.4,4);cs.position.y=3.2;body.add_child(cs)
 for gate in plan.openings:
  if gate.type!="gate":continue
  var center: Vector2=gate.point;var tangent: Vector2=gate.tangent
  if float(gate.width)<=8.5:
   var visual: Node3D=Kit.place(holder,"gate_stone_6m",Vector3(center.x,data.height_at(center),center.y),-atan2(tangent.y,tangent.x),"",false)
   visual.scale.x=maxf(1.0,float(gate.width)/4.2)
   visual.set_meta("opening_width_m",float(gate.width))
   box(visual,Vector3(-3,2.2,0),Vector3(1.5,4.4,2.0))
   box(visual,Vector3(3,2.2,0),Vector3(1.5,4.4,2.0))
   box(visual,Vector3(0,5.1,0),Vector3(7.65,.65,2.0))
  else:
   # Oblique roads can require a long opening. Use two original towers, never stretch a roof 15x.
   for side in [-1.0,1.0]:
    var point: Vector2=center+tangent*side*(float(gate.width)*.5+2.2)
    var post: Node3D=Kit.place(holder,"watchtower_stone_4m",Vector3(point.x,data.height_at(point),point.y),-atan2(tangent.y,tangent.x),"",false)
    box(post,Vector3(0,3.2,0),Vector3(4,6.4,4))

 # The physical bridges are part of the atomic city acceptance gate.
 var built_river: Array=[]
 for river_plan in plan.get("river_gates",[]):
  var river_result: Dictionary=RiverGate.build(holder,river_plan)
  if not bool(river_result.get("ok",false)):
   holder.queue_free()
   return {"status":"BLOCKED","owner":"fortifications","reason":"river_gate_build_failed","rendered":false}
  built_river.append({"variant":river_result.kind,"chunks":river_result.chunks,"arches":river_result.arches})
 for mesh in holder.find_children("*","MeshInstance3D",true,false):mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 preload("res://convergence/batch.gd").apply(holder)
 return {"status":"ready","owner":"fortifications","rendered":true,"segments":plan.segments.size(),"gates":plan.openings.size(),"river_gates":built_river,"ms":(Time.get_ticks_usec()-begin)/1000.0,"plan":plan}
