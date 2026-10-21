extends SceneTree
# C03 ALFA R2: execute with Godot 4.6.2 --headless --path ... --script res://convergence/tests/qa_rig01_eight_directions.gd
const Rig = preload("res://rig.gd")
var failure_count: int=0
func _initialize() -> void:
 call_deferred("_run")
func _run() -> void:
 var rig=Rig.new()
 root.add_child(rig)
 for k in range(8):
  var a: float=float(k)*TAU/8.0
  var motion:=Vector3(cos(a),0.0,sin(a)) * 2.0
  rig.rotation.y=atan2(-motion.x,-motion.z)
  rig.pose(0.1,false,false,true)
  rig.locomotion(motion,0.1,false,true,true)
  if str(rig.get_meta("motion_source",""))!="EXO_original_local_8directions":
   push_error("RIG01 missing animation metadata direction "+str(k));failure_count+=1
  if absf(rig.forearms[0].rotation.x+0.18)<0.001:
   push_error("RIG01 elbow did not bend direction "+str(k));failure_count+=1
  if not rig.arms[0].rotation.is_finite() or not rig.forearms[0].rotation.is_finite():
   push_error("RIG01 NaN direction "+str(k));failure_count+=1
 if failure_count>0:
  push_error("RIG01 native QA failed "+str(failure_count))
  quit(1)
 else:
  print("RIG01 eight directions: PASS (transform test, not visual clipping proof)")
  quit(0)
