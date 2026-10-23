extends SceneTree
const Npc = preload("res://npc_system04/actor.gd")
const Crowd = preload("res://exo_crowd_illusion/visuals/real_npc_visual.gd")
const Wardrobe = preload("res://wardrobe.gd")
var failures:Array[String]=[]
func check(cond:bool,msg:String)->void:
    if not cond:
        failures.append(msg)
        push_error("EXO_REFIT_INTEGRATION_FAIL "+msg)
func _initialize()->void:call_deferred("run")
func run()->void:
    var person:Dictionary={"id":"npc/r02/character_qa_11","role":"resident","home_slot":"home1","display_name":"Teste Murim","appearance":{}}
    var points:Array=[Vector3(0,0,0),Vector3(1,0,0)]
    var routes:Dictionary={"home1>home1":points}
    var npc:CharacterBody3D=Npc.new()
    root.add_child(npc)
    npc.setup(person,points,{},routes,900.0,"101")
    check(npc.setup_error.is_empty(),"real NPC setup")
    check(npc.rig!=null,"NPC visual constructed")
    if npc.rig!=null:
        check(npc.rig.get_meta("exo_character_refit_version",0)==1,"NPC uses new refit")
        check(npc.rig.get_meta("exo_humanoid_r2_roots",[]).is_empty(),"NPC old R2 geometry removed")
        check(npc.rig.get_meta("garments",[]).size()>0,"NPC clothing generated")
        npc.rig.pose(2.0,true,false,true)
    var crowd:=Crowd.new()
    root.add_child(crowd)
    var bool_result:bool=crowd.configure({"id":"npc/r02/character_qa_11","role":"resident","appearance":{"robe":3,"outfit":0}},"npc/r02/crowd_refit_9","101")
    check(bool_result,"Crowd configured")
    if bool_result:
        check(crowd.rig.get_meta("exo_character_refit_version",0)==1,"crowd uses new refit")
        check(crowd.rig.get_meta("exo_humanoid_r2_roots",[]).is_empty(),"crowd R2 geometry removed")
    print("EXO_REFIT_INTEGRATION ",JSON.stringify({"failures":failures,"npc":npc.rig!=null,"crowd":bool_result}))
    quit(0 if failures.is_empty() else 1)
