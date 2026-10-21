extends SceneTree
var w:Node3D
var failures:Array=[]
func check(ok:bool,label:String):
 print("PONTAS_DUNGEON_CHECK ",label," ",ok)
 if not ok:failures.append(label)
func _initialize():call_deferred("run")
func shot(label:String):
 w.update_camera()
 var directory:String=OS.get_environment("EXO_AUDIT_CAPTURE_DIR")
 if directory.is_empty():return
 DirAccess.make_dir_recursive_absolute(directory)
 for i in range(8):await process_frame
 await RenderingServer.frame_post_draw
 check(root.get_texture().get_image().save_png(directory.path_join(label+".png"))==OK,"capture/"+label)
func settle():
 for i in range(30):
  await physics_frame
  w.player.velocity=Vector3(0,-6,0);w.player.move_and_slide();w.player.apply_floor_snap()
func run():
 w=preload("res://convergence/game.gd").new();w.load_on_start=false;w.save_path="user://pontas_dungeon.json";root.add_child(w);await process_frame
 w.flow.phase="creator"
 check(w.flow.create_character({"name":"Pontas Soltas QA","race":0,"path":0,"robe":1,"hair":0,"skin":0,"style":0,"weapon":"sword","outfit":0},101),"create")
 for i in range(1800):
  await physics_frame
  if w.current_region>=0 and not w.changing_region:break
 check(await w.change_region(10),"approach")
 w.ui.resume();w.simulation_enabled=false
 var entrance:Dictionary={}
 for holder in w.active_region.props:
  if holder.has_meta("exo_dungeon_location_id"):
   w.player.global_position=holder.to_global(Vector3(0,1.2,3));entrance=w._near_dungeon_entrance();break
 check(not entrance.is_empty(),"physical_entrance")
 if entrance.is_empty():quit(1);return
 await settle()
 var old_size:float=w.camera.size
 var old_environment:Environment=w.camera.environment
 w.gate_cooldown=0;w.interaction_cooldown=0;w.interact()
 check(w._dungeon_inside(),"E_entry")
 await settle()
 for i in range(30):await process_frame
 var module:RefCounted=w.exo_core.instances.dungeon_genesis
 var presentation:Node=module.transition.current.get_node_or_null("DungeonPresentation")
 check(w.camera.size<old_size,"automatic_closer_camera")
 check(w.camera.projection==Camera3D.PROJECTION_ORTHOGONAL,"orthographic_preserved")
 check(is_instance_valid(presentation),"visibility_controller")
 var state_before_map:Dictionary=w.journey.data.duplicate(true)
 var map_state:Dictionary=w.exo_core.services.invoke("dungeons","map_snapshot")
 check(w.journey.data==state_before_map,"map_read_does_not_mutate_save")
 check(map_state.get("active",false) and map_state.get("owner","")=="dungeon_genesis","map_uses_dungeon_owner")
 check(not map_state.has("lots") and not map_state.has("residents"),"map_has_no_exterior_markers")
 check(w.objective().begins_with("Explore a masmorra"),"interior_objective")
 if is_instance_valid(presentation):
  presentation.refresh_visibility()
  check(presentation.visibility_at(w.player.global_position)>0.9,"player_cell_visible")
  var behind:Vector3=w.player.global_position-w.facing.normalized()*8.0
  check(presentation.visibility_at(behind)<0.1,"behind_facing_dark")
  check(presentation.visibility_at(w.player.global_position+Vector3.UP*12.0)<0.1,"other_floor_dark")
  var prior_facing:Vector3=w.facing
  for direction in [Vector3.FORWARD,Vector3.BACK,Vector3.LEFT,Vector3.RIGHT]:
   w.set_facing(direction);presentation.refresh_visibility()
   check(presentation.visibility_at(w.player.global_position-direction*8.0)<0.1,"turning_updates_visibility/"+str(direction))
  w.set_facing(prior_facing)
  var saved_position:Vector3=w.player.global_position
  var old_origin:Vector2=presentation.origin
  w.player.global_position+=Vector3(2,0,0);presentation.refresh_visibility()
  check(presentation.origin!=old_origin and presentation.visibility_at(w.player.global_position)>0.9,"movement_updates_visibility")
  w.player.global_position=saved_position;presentation.refresh_visibility()
  var obstacle:=StaticBody3D.new();obstacle.collision_layer=4;w.add_child(obstacle)
  obstacle.global_position=w.player.global_position+w.facing.normalized()*3.0+Vector3.UP
  var col:=CollisionShape3D.new();var box:=BoxShape3D.new();box.size=Vector3(4,4,4);col.shape=box;obstacle.add_child(col)
  await physics_frame;await physics_frame
  presentation.refresh_visibility()
  check(presentation.visibility_at(w.player.global_position+w.facing.normalized()*7)<0.1,"solid_occludes_vision")
  obstacle.queue_free();await physics_frame;await physics_frame
  presentation.refresh_visibility()
 if "capture" in OS.get_cmdline_user_args():await shot("dungeon-"+("after" if is_instance_valid(presentation) else "before"))
 check(w.save_progress(),"save_inside")
 w.gate_cooldown=0;w.interaction_cooldown=0;w.interact()
 check(not w._dungeon_inside(),"E_exit")
 check(not w.exo_core.services.invoke("dungeons","map_snapshot").get("active",true),"map_returns_to_exterior")
 check(is_equal_approx(w.camera.size,old_size) and w.camera.environment==old_environment,"camera_restored_on_exit")
 await settle();w.gate_cooldown=0;w.interaction_cooldown=0;w.interact()
 check(w._dungeon_inside(),"E_reentry")
 if w._dungeon_inside():
  module.transition.abort()
  check(is_equal_approx(w.camera.size,old_size) and w.camera.environment==old_environment,"camera_restored_on_abort")
 print("PONTAS_DUNGEON_RESULT ",JSON.stringify({"failures":failures}))
 w.queue_free();await process_frame;await process_frame;quit(0 if failures.is_empty() else 1)
