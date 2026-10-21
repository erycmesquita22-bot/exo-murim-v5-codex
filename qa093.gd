extends SceneTree
# Independent structural tests for Godot 4.x. Run with: godot --headless --path . --script res://qa093.gd
var passed:=0
var failed:=0
func check(ok: bool,description: String) -> void:
    if ok:passed+=1
    else:failed+=1
    print(("OK • " if ok else "FAIL • ")+description)
func _initialize() -> void:call_deferred("run")
func run() -> void:
    var r: Node3D=load("res://rig.gd").new()
    root.add_child(r)
    await process_frame
    check(r.arms.size()==2 and r.forearms.size()==2 and r.legs.size()==2 and r.calves.size()==2,"Dois cotovelos e dois joelhos")
    check(not r.has_meta("reference_visual"),"Nenhuma sobreposição de modelo externo")
    var profile: Dictionary={"race":0,"robe":0,"hair":0,"skin":0,"style":0,"weapon":"sword"}
    preload("res://wardrobe.gd").apply(r,profile)
    check(r.torso.get_child(0).visible,"Tronco Minecraft é visível")
    check(r.torso.get_child(1).get_child(0).visible,"Cabeça Minecraft é visível")
    check(r.skin.albedo_texture.get_image().get_size() in [Vector2i(64,64),Vector2i(256,256)],"Skin Minecraft 64x64 ou paleta EXO 256x256")
    var sword: Node3D=r.get_meta("weapon_root")
    check(sword.get_parent()==r.forearms[0],"Espada acompanha o antebraço direito")
    var sheath: Node3D=r.get_meta("carry_sheath")
    check(is_instance_valid(sheath) and sheath.get_parent()==r.torso,"Bainha presa ao tronco que gira")
    r.pose(0,true,true,true)
    var elbow_before: float=r.forearms[0].rotation.x
    r.locomotion(Vector3(0,0,-5),.12,true,true,true)
    check(absf(r.forearms[0].rotation.x-elbow_before)>.01,"Corrida altera a flexão do cotovelo")
    r.pose(.7,false,false,true,-1,.3,1)
    check(absf(r.calves[0].rotation.x)>.5,"Rolagem flexiona os joelhos")
    preload("res://arsenal.gd").equip(r,"dagger")
    check(r.get_meta("weapon_id")=="dagger" and (r.get_meta("carry_sheath") if r.has_meta("carry_sheath") else null)==null,"Adaga não reutiliza bainha longa")
    preload("res://arsenal.gd").equip(r,"gauntlets")
    check(r.get_meta("fist_forearms").size()==2,"Manoplas reutilizam juntas permanentes")
    check(r.get_meta("weapon_nodes").size()==5,"Manoplas não duplicam corpo")
    r.queue_free()
    await process_frame
    print("QA093: %d passou/passaram; %d falhou/falharam"%[passed,failed]);quit(int(failed>0))
