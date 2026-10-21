extends "res://validation_r3/support.gd"
var captures: Array=[]
var out: String="res://cidade_viva/evidence/"
func _initialize():call_deferred("run_capture")
func lot_focus(role: String) -> Vector3:
 for lot in w.active_region.data.lots:
  if lot.function==role:return Vector3(lot.p.x,float(lot.height),lot.p.y)+Vector3(sin(lot.yaw),0,cos(lot.yaw))*6.5
 return Vector3(0,w.active_region.data.center_h,0)
func screen(label: String,focus: Vector3,zoom: float,offset: Vector3=Vector3(25,32,27)):
 RenderingServer.render_loop_enabled=true
 w.camera.size=zoom;w.camera.far=900
 w.camera.position=focus+offset;w.camera.look_at(focus)
 var visible_people:=0
 for actor in w.residents:
  actor.presentation_visible=w.resident_is_visible(actor)
  actor.rig.visible=not actor.sheltered and actor.presentation_visible
  actor.caption.visible=false
  if actor.rig.visible:visible_people+=1
 await process_frame;await process_frame
 await RenderingServer.frame_post_draw
 var path: String=out+label+".png"
 var result: int=w.get_viewport().get_texture().get_image().save_png(path)
 RenderingServer.render_loop_enabled=false
 check(result==OK,"capture_"+label)
 captures.append({"file":path,"seed":101,"region":w.current_region,"clock":float(w.extension().clock),"visible_npcs":visible_people,"camera_size":zoom,"camera_position":str(w.camera.position),"camera_rotation":str(w.camera.rotation),"urban":w.active_region.get_meta("cidade_viva",{}),"flat_collision_chunks":w.active_region.flat_collision_chunks,"visual_settings":w.graphics.values.duplicate(true),"renderer":RenderingServer.get_current_rendering_method()})
func run_capture():
 RenderingServer.render_loop_enabled=false
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
 await boot("user://cidade_viva_capture_r2.json")
 check(await w.change_region(78),"load_city_78")
 w.graphics.select(2);w.graphics.set_option("shadow_quality",0);w.graphics.set_option("vsync",0);w.graphics.set_option("fps_limit",0)
 w.extension().clock=900.0
 await frames(600)
 w.set_physics_process(false)
 for canvas in w.find_children("*","CanvasLayer",true,false):canvas.hide()
 var focus:=Vector3(0,w.active_region.data.center_h,0)
 var layer: Node3D=w.active_region.get_node("EXOCidadeViva01")
 layer.hide();await screen("01-cidade-antes",focus,240,Vector3(105,145,125))
 layer.show();await screen("02-cidade-integrada",focus,240,Vector3(105,145,125))
 await screen("03-mercado",lot_focus("market"),48)
 await screen("04-escola-marcial",lot_focus("martial_school"),48)
 await screen("05-hospedaria",lot_focus("inn"),44)
 await screen("06-medicina",lot_focus("herbalist"),42)
 await screen("07-moradias",lot_focus("residence"),58)
 await screen("08-ferraria",lot_focus("smithy"),38)
 await screen("09-rua-central",focus,66)
 w.extension().clock=1800;w.set_physics_process(true)
 await frames(120);w.set_physics_process(false);w.graphics.apply()
 await screen("10-cidade-noite",lot_focus("market"),66)
 w.extension().clock=900;w.set_physics_process(true)
 check(await w.change_region(26),"load_river_city_26")
 await frames(120);w.set_physics_process(false)
 var wall: Dictionary=w.active_region.get_meta("exo_architecture",{}).get("plan",{})
 check(not wall.get("river_gates",[]).is_empty(),"real_river_gate")
 if not wall.get("river_gates",[]).is_empty():
  var gate: Dictionary=wall.river_gates[0]
  var p: Vector2=gate.get("point",gate.get("center",Vector2.ZERO))
  await screen("11-passagem-fluvial",Vector3(p.x,w.active_region.data.height_at(p),p.y),96)
 await screen("12-cidade-ribeirinha",Vector3(0,w.active_region.data.center_h,0),240,Vector3(105,145,125))
 FileAccess.open(out+"captures.json",FileAccess.WRITE).store_string(JSON.stringify(captures,"  "))
 await finish("cidade_viva_capture")
