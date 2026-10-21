extends SceneTree
## Work: godot --headless --path . --script res://fortifications/qa_native.gd
## Real planner/terrain consistency on a bounded seed sample; renderer requires display.
const WorldPlanner=preload("res://genesis/world_planner.gd")
const Region=preload("res://genesis/region_data.gd")
const FortPlanner=preload("res://fortifications/planner.gd")
var total:=0
var failures: Array=[]
var partial:=0
var skipped:=0
func _initialize() -> void:call_deferred("run")
func check(ok: bool,tag: String) -> void:
	total+=1
	if not ok:failures.append(tag);print("FAIL ",tag)
func run() -> void:
	for seed_value in ["101","707","816204","9007199254740993","9223372036854775807"]:
		var atlas: Dictionary=WorldPlanner.read_atlas("res://genesis/atlas_seed_%s.json"%seed_value) if seed_value in ["101","816204"] else WorldPlanner.plan(seed_value)
		check(atlas.get("regions",[]).size()==88,"atlas_"+seed_value)
		for spec in atlas.regions:
			if spec.kind!="settlement":continue
			var d: RefCounted=Region.new(atlas,int(spec.id))
			if d.settlement_plan.get("status")!="ready":continue
			var plan_a: Dictionary=FortPlanner.plan_region(d)
			var plan_b: Dictionary=FortPlanner.plan_region(d)
			var signature_a: String=JSON.stringify([plan_a.get("status"),plan_a.get("segments",[]),plan_a.get("openings",[])]).sha256_text()
			var signature_b: String=JSON.stringify([plan_b.get("status"),plan_b.get("segments",[]),plan_b.get("openings",[])]).sha256_text()
			check(signature_a==signature_b,"deterministic_%s_%s"%[seed_value,spec.id])
			check(plan_a.status in ["ready","partial","skipped"],"status_%s_%s"%[seed_value,spec.id])
			if plan_a.status=="skipped":skipped+=1;continue
			if plan_a.status=="partial":partial+=1
			var polygon: Array=plan_a.polygon
			for wall in plan_a.segments:
				var p: Vector2=wall.a;var q: Vector2=wall.b
				check(p.distance_to(q)<=2.801,"section_length_%s_%s"%[seed_value,spec.id])
				check(float(wall.base)<=float(d.height_at(p))-.59,"foundation_%s_%s"%[seed_value,spec.id])
				check(absf(p.x)<d.half-10 and absf(p.y)<d.half-10,"bounds_%s_%s"%[seed_value,spec.id])
				for access in d.gates:
					if d.spec.settlement_scale=="city":
						check(p.distance_to(Geometry2D.get_closest_point_to_segment(p,Vector2.ZERO,access.p))>float(access.width)*.5+.1 and q.distance_to(Geometry2D.get_closest_point_to_segment(q,Vector2.ZERO,access.p))>float(access.width)*.5+.1,"route_clearance_%s_%s"%[seed_value,spec.id])
			if d.spec.settlement_scale!="city":
				var open_gate:=false
				for gate in plan_a.openings:
					if gate.type=="gate":open_gate=true
				check(open_gate,"courtyard_entry_%s_%s"%[seed_value,spec.id])
	var summary={"status":"PASS" if failures.is_empty() else "FAIL","checks":total,"failures":failures.slice(0,40),"partial":partial,"skipped":skipped,"engine":Engine.get_version_info().string}
	print("FORTIFICATIONS_NATIVE_RESULT ",JSON.stringify(summary))
	quit(0 if failures.is_empty() else 1)
