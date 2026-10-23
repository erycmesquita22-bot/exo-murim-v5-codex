extends SceneTree
const Portal=preload("res://exo_settlement_forge/runtime/portal_controller.gd")
var failures:Array[String]=[]
func check(ok:bool,key:String)->void:
    if not ok:
        failures.append(key)
        push_error("EXO_RESUME_QA_FAIL "+key)
    else:print("EXO_RESUME_QA_PASS "+key)
func _initialize()->void:call_deferred("run")
func run()->void:
    var scene:=Node3D.new();root.add_child(scene)
    var exterior:=Node3D.new();exterior.name="RegionExterior";scene.add_child(exterior)
    var stage:=Node3D.new();stage.name="InteriorStaging";scene.add_child(stage)
    var player:=CharacterBody3D.new();scene.add_child(player)
    var camera:=Camera3D.new();scene.add_child(camera)
    var first=Portal.new();scene.add_child(first)
    var record:Dictionary={"building_id":"building/test_01","region_id":"86", "interior_id":"casa_campesina_01", "exterior_door":[0.0,0.0,0.0],"return_anchor":[1.0,0.0,2.0],"accessible":true,"access_state":"open","enabled_floors":1}
    player.global_position=Vector3.ZERO
    var entered:bool=first.enter(player,exterior,stage,camera,record,true)
    check(entered,"interior_enter")
    if not entered:quit(1);return
    check(first.inside and player.global_position.x>9990,"interior_instanced")
    var save_inside:Vector3=player.global_position+Vector3(0.3,0.0,0.0)
    player.global_position=save_inside
    var snap:Dictionary=first.snapshot_for_core()
    check(bool(snap.get("inside",false)) and snap.get("building_id")==record.building_id,"interior_snapshot_identity")
    var was_inside=first.inside
    check(first.interrupt("qa_close"),"leave_interior_before_reopen")
    first.queue_free()
    await process_frame
    var second=Portal.new();scene.add_child(second)
    var closed:Dictionary=record.duplicate(true)
    closed["accessible"]=false;closed["access_state"]="closed"
    player.global_position=Vector3(9,0,9)
    var restored:bool=second.restore_from_core(player,exterior,stage,camera,closed,snap,true)
    check(restored,"restore_closed_business_from_save")
    check(second.inside,"inside_after_reopen")
    check(player.global_position.distance_to(save_inside)<0.02,"exact_saved_inside_position")
    check(not exterior.visible,"exterior_hidden_while_inside")
    check(second.interrupt("qa_exit"),"restored_interior_has_exit")
    check(player.global_position.distance_to(Vector3(1.0,0.0,2.0))<0.05,"exterior_return_anchor")
    check(exterior.visible,"exterior_shown_after_exit")
    print("EXO_RESUME_INTERIOR_QA ",JSON.stringify({"passed":failures.is_empty(),"failures":failures,"saved":str(save_inside),"restored":restored}))
    scene.free()
    quit(0 if failures.is_empty() else 1)
