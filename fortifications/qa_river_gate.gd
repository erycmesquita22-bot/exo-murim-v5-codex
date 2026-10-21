extends SceneTree
## Native Godot 4.6.2 QA: run --headless --path . --script res://fortifications/qa_river_gate.gd
## Synthetic geometry is a unit fixture ONLY. Acceptance also requires unmodified
## Genesis cities, real 3D instances, water/collider checks and rendered captures.
const RiverGate=preload("res://fortifications/river_gate.gd")
const Planner=preload("res://fortifications/planner.gd")
const Atlas=preload("res://genesis/world_planner.gd")
const Region=preload("res://genesis/region_data.gd")
var checks:=0
var failures: Array=[]
var facts: Dictionary={"variants":{},"real_river_cities":[],"blocked_river_cities":[],"city_78":{},"seed_checks":0,"engine":""}
func _initialize() -> void:call_deferred("run")
func check(pass_value: bool,label: String) -> void:
 checks+=1
 if not pass_value:failures.append(label);print("RIVER_FAIL ",label)
func dry_ground(_p: Vector2) -> float:return 11.0
func run() -> void:
 facts.engine=Engine.get_version_info().string
 # Three different vault footprints and invalid-bank rejection.
 for width in [26.0,38.0,55.0]:
  var opening: Dictionary={"point":Vector2(40,0),"tangent":Vector2(0,1),"width":width,"s":50.0,"source":"river:0","river_index":0}
  var river: Dictionary={"p":Vector2(100,0),"hub_height":5.0,"height":5.0}
  var plan: Dictionary=RiverGate.plan(opening,river,Vector2.ZERO,[],[0.0,100.0,200.0,300.0,400.0],400.0,Callable(self,"dry_ground"))
  var expected: String="small" if width<27 else "medium" if width<44 else "monumental"
  check(bool(plan.get("ok",false)),"synthetic_founded_%s"%expected)
  if not plan.ok:continue
  check(plan.variant==expected,"size_classification_%s"%expected)
  check(plan.banks.size()==2,"two_dry_banks_%s"%expected)
  check(JSON.stringify(plan)==JSON.stringify(RiverGate.plan(opening,river,Vector2.ZERO,[],[0.0,100.0,200.0,300.0,400.0],400.0,Callable(self,"dry_ground"))),"seed_independent_repeatability_%s"%expected)
  var holder:=Node3D.new();root.add_child(holder)
  var built: Dictionary=RiverGate.build(holder,plan)
  check(built.ok,"native_geometry_instanced_%s"%expected)
  var physics_nodes: Array=holder.find_children("*","CollisionShape3D",true,false)
  check(physics_nodes.size()>0,"native_collision_geometry_%s"%expected)
  check(holder.find_children("*","MultiMeshInstance3D",true,false).size()>=1,"batched_voxels_%s"%expected)
  facts.variants[expected]={"width":width,"chunks":built.chunks,"physics_shapes":physics_nodes.size()}
  # Shape intersection at the actual water level, beneath the hollow arches.
  await physics_frame
  for dz in [-2.0,0.0,2.0]:
   var query:=PhysicsShapeQueryParameters3D.new();var sphere:=SphereShape3D.new();sphere.radius=.35
   query.shape=sphere;query.transform=Transform3D(Basis.IDENTITY,Vector3(40,6.0,dz));query.collision_mask=4
   check(root.world_3d.direct_space_state.intersect_shape(query).is_empty(),"river_passage_clear_%s_%.0f"%[expected,dz])
  holder.queue_free();await physics_frame
 # Real Genesis seeds. No mock hydrology is used for acceptance candidate selection.
 for seed_value in ["101","707","816204","9007199254740993"]:
  var atlas: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://genesis/atlas_seed_%s.json"%seed_value)) if seed_value in ["101","816204"] else Atlas.plan(seed_value)
  check(atlas.regions.size()==88,"atlas_88_%s"%seed_value)
  for spec in atlas.regions:
   if spec.kind!="settlement" or spec.settlement_scale!="city":continue
   var region:=Region.new(atlas,int(spec.id))
   var a: Dictionary=Planner.plan_region(region)
   var b: Dictionary=Planner.plan_region(region)
   facts.seed_checks+=1
   check(JSON.stringify(a)==JSON.stringify(b),"river_plan_seed_determinism_%s_%d"%[seed_value,spec.id])
   if seed_value=="101" and int(spec.id)==78:
    facts.city_78={"status":a.status,"crossings":a.get("river_gates",[]).size()}
    check(a.status=="ready","regression_original_city_78")
   if not region.rivers.is_empty():
    if a.status=="ready" and a.get("river_gates",[]).size()>0:
     facts.real_river_cities.append({"seed":seed_value,"region":spec.id,"bridges":a.river_gates.size(),"variants":a.river_gates.map(func(g):return g.variant)})
    elif a.status!="ready":
     facts.blocked_river_cities.append({"seed":seed_value,"region":spec.id,"status":a.status,"errors":a.get("river_gate_errors",[]),"skipped":a.get("skipped",{})})
 # A suite without a real river city is NOT an integration acceptance certificate.
 check(not facts.real_river_cities.is_empty(),"real_genesis_river_city_accepted")
 var summary: Dictionary={"status":"PASS" if failures.is_empty() else "FAIL","checks":checks,"failures":failures,"facts":facts}
 DirAccess.make_dir_recursive_absolute("res://fortifications/results")
 FileAccess.open("res://fortifications/results/qa_river_gate.json",FileAccess.WRITE).store_string(JSON.stringify(summary,"  "))
 print("EXO_RIVER_GATE_NATIVE_QA ",JSON.stringify(summary))
 quit(0 if failures.is_empty() else 1)
