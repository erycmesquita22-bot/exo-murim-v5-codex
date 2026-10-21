extends "res://validation_r3/support.gd"
func _initialize() -> void:call_deferred("run")
func run() -> void:
    await boot("user://v5-dungeon.json")
    for i in range(300):
        if w.current_region>=0 and not w.changing_region:break
        await physics_frame
    var rid: int=-1
    for row in w.atlas.regions:
        if row.kind=="dungeon_approach":rid=int(row.id);break
    check(rid>=0 and await w.change_region(rid),"dungeon_real_region")
    await frames(5)
    var holder: Node3D=null
    for prop in w.active_region.props:
        if prop.has_meta("exo_dungeon_location_id"):holder=prop;break
    check(holder!=null,"registered_physical_entrance")
    if holder!=null:
        var point: Vector3=holder.to_global(Vector3(0,1.2,3.0))
        var feet: Vector3=w.regional_spawn(w.active_region,point)
        check(feet.is_finite(),"entrance_safe_capsule")
        if feet.is_finite():
            w.player.position=feet;w.player.velocity=Vector3.ZERO
            await frames(8)
            var entrance: Dictionary=w._near_dungeon_entrance()
            check(not entrance.is_empty(),"worldgen_dungeon_contract")
            if not entrance.is_empty():
                w.gate_cooldown=0;w.interaction_cooldown=0
                w.interact();await frames(90)
                print("DUNGEON_PHYSICS ",JSON.stringify({"position":str(w.player.position),"velocity":str(w.player.velocity),"floor":w.player.is_on_floor(),"simulating":w.simulation_enabled,"paused":paused}))
                check(w._dungeon_inside(),"real_e_interaction_enters_dungeon")
                check(w.player.is_on_floor(),"dungeon_real_floor")
                if w._dungeon_inside():
                    check(w.save_progress(),"dungeon_core_checkpoint")
                    var module: Variant=w.exo_core.instances.dungeon_genesis
                    var room: Variant=module._instance()
                    check(is_instance_valid(room),"dungeon_instance_present")
                    w.player.global_position=room.to_global(room.exit_anchor())+Vector3.UP*.1
                    w.player.velocity=Vector3.ZERO;await frames(5)
                    check(module.leave_instance(),"dungeon_leave")
                    check(not w._dungeon_inside() and w.active_region.visible,"dungeon_exterior_restored")
    await finish("v5_dungeon")
