extends "res://validation_r3/support.gd"
func _initialize() -> void:call_deferred("run_capture")
func capture(label: String) -> void:
 RenderingServer.render_loop_enabled=true
 for i in range(5):await process_frame
 await RenderingServer.frame_post_draw
 check(root.get_texture().get_image().save_png("res://exo_core/evidence/"+label+".png")==OK,"capture_"+label)
 RenderingServer.render_loop_enabled=false
func run_capture() -> void:
 RenderingServer.render_loop_enabled=false
 await boot("user://core_city_capture.json")
 check(await w.change_region(78),"real_city")
 w.set_physics_process(false);w.ui.hide()
 w.camera.size=240;w.camera.position=Vector3(130,180,140);w.camera.look_at(Vector3(0,w.active_region.data.center_h,0))
 await capture("11-cidade-muralhas")
 var plan: Dictionary=w.exo_core.architecture_status().plan
 for gate in plan.openings:
  if gate.type!="gate":continue
  var point:=Vector3(gate.point.x,w.active_region.data.height_at(gate.point),gate.point.y)
  w.camera.size=45;w.camera.position=point+Vector3(26,34,29);w.camera.look_at(point+Vector3.UP*2)
  await capture("11b-portao-real");break
 w.ui.show()
 await finish("exo_core_city_capture")
