extends SceneTree
const Game=preload("res://convergence/game.gd")
var w: Node3D
var failures: Array=[]
var walks: Array=[]
var seen: Dictionary={}
const PILOT=[32,46,52,61,63,78,86]
func _initialize():call_deferred("run")
func run():
 w=Game.new();w.load_on_start=false;w.world_seed_override=101;w.save_path="user://convergence_walk.json";root.add_child(w);await process_frame
 w.flow.phase="creator";w.flow.create_character({"name":"Walk QA","race":0,"path":0,"robe":1,"hair":0,"skin":0,"style":0});w.ui.resume()
 w.simulation_enabled=false
 if await w.change_region(86):
  w.simulation_enabled=false
  await visit(86,-1)
 else:failures.append("boot")
 var report={"visited":seen,"failures":failures,"walks":walks,"fixture":"Original player capsule, move_and_slide at 60Hz; direct velocity, no teleport except verified region arrival. All pilot portal edges both directions; integrated buildings checked separately."}
 FileAccess.open("res://convergence/pilot_walk_result.json",FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
 print("PILOT_WALK_RESULT ",JSON.stringify(report))
 w.set_paused(false);w.audio_fx.shutdown();w.free();quit(0 if failures.is_empty() and seen.size()==7 else 1)
func walk_to(p: Vector2,label: String) -> bool:
 var start: Vector3=w.player.position;var stalled:=0;var previous: Vector3=start
 for step in range(6500):
  var offset:=Vector3(p.x-w.player.position.x,0,p.y-w.player.position.z)
  if offset.length()<.6:
   walks.append({"region":w.current_region,"label":label,"frames":step,"distance":start.distance_to(w.player.position)});print("WALK ",w.current_region," ",label);return true
  w.player.velocity=offset.normalized()*6.5+Vector3(0,w.player.velocity.y-20.0/60,0)
  w.player.move_and_slide();await physics_frame
  if w.player.position.distance_to(previous)<.001:stalled+=1
  else:stalled=0
  previous=w.player.position
  if stalled>120:break
 failures.append({"rid":w.current_region,"label":label,"position":str(w.player.position),"target":str(p)});return false
func visit(rid: int,parent: int) -> void:
 seen[str(rid)]=true
 if not await walk_to(Vector2.ZERO,"arrival_to_center"):return
 var targets: Array=[]
 for gate in w.active_region.data.gates:
  if int(gate.neighbor) in PILOT and int(gate.neighbor)!=parent and not seen.has(str(int(gate.neighbor))):targets.append(gate.duplicate())
 for gate in targets:
  var point: Vector2=gate.p-gate.p.normalized()*4
  if not await walk_to(point,"center_to_gate"):return
  if not await w.change_region(int(gate.neighbor),gate.id):failures.append("transition");return
  w.simulation_enabled=false
  await visit(int(gate.neighbor),rid)
  var reciprocal: Dictionary={}
  for back in w.active_region.data.gates:
   if back.id==gate.id:reciprocal=back
  if not await walk_to(reciprocal.p-reciprocal.p.normalized()*4,"return_to_gate"):return
  if not await w.change_region(rid,gate.id):failures.append("return_transition");return
  w.simulation_enabled=false
  if not await walk_to(Vector2.ZERO,"return_to_center"):return
