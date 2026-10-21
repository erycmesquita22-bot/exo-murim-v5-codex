extends SceneTree
func _initialize():call_deferred("run")
func run():
 var rig=load("res://rig.gd").new();root.add_child(rig)
 var A=load("res://arsenal.gd");var C=load("res://catalog.gd")
 for id in ["bow","crossbow"]:
  A.equip(rig,id)
  for progress in [-1.0,.2,.43,.7,.95]:
   rig.pose(1,false,false,true);A.animate(rig,C.weapon(id),0,progress)
   print(id," ",progress," grip_error=",rig.forearms[0].to_global(Vector3(0,-.375,0)).distance_to(rig.get_meta("weapon_root").global_position))
 rig.free();quit()
