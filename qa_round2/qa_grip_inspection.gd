extends SceneTree
func _initialize() -> void:
    call_deferred("run")
func run() -> void:
    var failures: int=0
    var holder:=Node3D.new();root.add_child(holder)
    var rig:=preload("res://rig.gd").new();holder.add_child(rig)
    var catalog=preload("res://catalog.gd")
    var arsenal=preload("res://arsenal.gd")
    for id in ["sword","katana","greatsword","dagger","spear","halberd","quarterstaff","arcane_staff","bow","crossbow"]:
        arsenal.equip(rig,id)
        for progress in [-1.0,0.25,0.75]:
            rig.pose(0.5,false,false,true)
            arsenal.animate(rig,catalog.weapon(id),0,progress)
            var hand_left:Vector3=rig.forearms[0].to_global(Vector3(0,-0.375,0))
            var hand_right:Vector3=rig.forearms[1].to_global(Vector3(0,-0.375,0))
            var weapon_root:Node3D=rig.get_meta("weapon_root")
            var target:Vector3=weapon_root.global_position
            if int(catalog.weapon(id).get("hands",1))==2 and str(catalog.weapon(id).get("pose", "")) in ["heavy","thrust","pole","reap","staff","focus"]:
                var shaft_world: Vector3=weapon_root.to_global(Vector3(0,0,-0.21))
                var support_distance: float=hand_right.distance_to(shaft_world)
                print("EXO_GRIP_SUPPORT ",id," phase=",progress," support_gap=",support_distance)
                if support_distance>0.075 or hand_left.distance_to(target)>0.075:
                    failures+=1
                    push_error("EXO_GRIP_TEST_FAILED "+id+" left="+str(hand_left.distance_to(target))+" support="+str(support_distance))
            print("EXO_GRIP ",id," phase=",progress," handL=",hand_left," handR=",hand_right," grip=",target," left_distance=",hand_left.distance_to(target)," right_distance=",hand_right.distance_to(target))
    print("EXO_GRIP_QA ",JSON.stringify({"passed":failures==0,"failures":failures}))
    holder.free();quit(0 if failures==0 else 1)
