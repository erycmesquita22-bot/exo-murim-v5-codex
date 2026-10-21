extends SceneTree
const Pavement=preload("res://exo_city_forge/runtime/pavement.gd")
const Planner=preload("res://exo_crowd_illusion/runtime/planner.gd")
const Renderer=preload("res://exo_crowd_illusion/runtime/zone_renderer.gd")
var failures:Array=[]
var checks:int=0
func check(ok:bool,label:String):
	checks+=1
	if not ok and label not in failures:failures.append(label);print("FAIL ",label)
func _initialize():call_deferred("run")
func run():
	for value in [NAN,INF,-INF]:
		check(not Pavement.safe_strip({"a":Vector2.ZERO,"b":Vector2(20,0),"width":value},256).ok,"nonfinite_width")
		check(not Pavement.safe_strip({"a":Vector2(value,0),"b":Vector2(20,0),"width":4},256).ok,"nonfinite_endpoint")
		check(not Pavement.safe_strip({"a":Vector2.ZERO,"b":Vector2(20,0),"width":4},value).ok,"nonfinite_half")
	check(not Pavement.safe_strip({"a":Vector2.ZERO,"b":Vector2.ZERO,"width":4},256).ok,"degenerate")
	check(not Pavement.safe_strip({"a":Vector2.ZERO,"b":Vector2(20,0),"width":512},256).ok,"oversize_width")
	check(not Pavement._clip_segment(Vector2.ZERO,Vector2.ONE,0).ok,"invalid_limit")
	var rng:=RandomNumberGenerator.new();rng.seed=20261021
	var accepted:int=0
	for i in range(3000):
		var road:Dictionary={"a":Vector2(rng.randf_range(-500,500),rng.randf_range(-500,500)),"b":Vector2(rng.randf_range(-500,500),rng.randf_range(-500,500)),"width":rng.randf_range(.25,45)}
		var strip:Dictionary=Pavement.safe_strip(road,256)
		if not strip.ok:continue
		accepted+=1
		for point in [strip.a-strip.side,strip.a+strip.side,strip.b-strip.side,strip.b+strip.side]:
			check(point.is_finite() and absf(point.x)<=255.751 and absf(point.y)<=255.751,"full_strip_inside")
	var points:Array=[]
	for i in range(49):points.append([float(i)*.25,0.0,0.0])
	var zone:Dictionary={"id":"certified_12m","points":points,"capacity":6,"lateral":.25,"activity":"walk"}
	var plan:Dictionary=Planner.plan(zone,"101")
	check(plan.ok and plan.agents.size()==6,"densely_sampled_lane_not_blocked")
	check(plan==Planner.plan(zone,"101"),"deterministic")
	var renderer:Node3D=Renderer.new()
	var stopped:int=0
	for actor in plan.agents:
		check(actor.route_length>=8.999 and actor.route_length<=12.001,"route_9_to_12m")
		var previous:Vector3=actor.a
		for k in range(1201):
			renderer.elapsed=k*.25
			var at:Vector3=renderer._actor_pos(actor)
			check(at.is_finite() and (at-previous).dot(actor.b-actor.a)>=-.00001,"300s_no_reverse")
			check(at.x>=-.001 and at.x<=12.001 and absf(at.z)<=.251,"certified_lane_bounds")
			previous=at
		check(previous.distance_to(actor.b)<.001,"stays_at_destination")
		stopped+=1
	var bent:Array=[[0,0,0],[10,0,0],[10,0,10]]
	var route:Array=Planner._subroute(bent,1.0,19.0)
	check(route.size()==3 and route[1]==Vector3(10,0,0),"retains_polyline_corner")
	var reserved:Dictionary=Planner.plan(zone,"101",1.0,[Vector3(6,0,0)])
	check(reserved.agents.is_empty(),"reserved_door_blocks_crossing")
	var director=preload("res://exo_crowd_illusion/runtime/director.gd").new()
	var parent:=Node3D.new();root.add_child(parent)
	check(not director.attach_region(parent,78,[zone],"101").ok,"no_demo_fallback")
	renderer.configure(plan,null,false,2.2,null)
	renderer.set_max_visible(60)
	check(renderer.agents.is_empty() and renderer.get_child_count()==0,"renderer_missing_atlas_fail_closed")
	parent.free();renderer.free()
	var result:Dictionary={"checks":checks,"failures":failures,"accepted_strips":accepted,"walkers":stopped,"simulated_seconds":300,"mode":"native_Godot_numeric_not_gameplay"}
	print("NUMERIC_RESULT ",JSON.stringify(result))
	FileAccess.open("res://REPARACAO_CHAT_V4/evidence/numeric.json",FileAccess.WRITE).store_string(JSON.stringify(result,"  "))
	quit(0 if failures.is_empty() else 1)
