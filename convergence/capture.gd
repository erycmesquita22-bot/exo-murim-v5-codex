extends SceneTree
const Game=preload("res://convergence/game.gd")
var w: Node3D
func _initialize():call_deferred("run")
func shot(name_value: String) -> void:
 w.ui.refresh()
 for i in range(4):await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://convergence/"+name_value+".png")
 print("CAPTURE ",name_value)
func run():
 root.size=Vector2i(1152,720)
 w=Game.new();w.load_on_start=false;w.world_seed_override=101;w.save_path="user://convergence_capture.json";root.add_child(w);await process_frame
 await shot("00-selecao-12-arquetipos")
 w.graphics.select(1);w.flow.phase="creator";w.flow.create_character({"name":"Eryc","race":0,"path":0,"robe":1,"hair":0,"skin":0,"style":0,"weapon":"sword"});w.ui.resume()
 for actor in w.enemies:actor.enabled=false
 await shot("01-recinto-inicial")
 for rid in [86,52,46,32,61,63,78]:
  if not await w.change_region(rid):print("CAPTURE_FAIL ",rid," ",w.generation_failure);continue
  for actor in w.enemies:actor.enabled=false
  w.simulation_enabled=false
  w.player.position=Vector3(0,w.active_region.data.center_h+.06,0);w.camera.size=170 if rid in [78,86] else 80;w.camera.position=w.player.position+Vector3(90,120,105);w.camera.look_at(w.player.position)
  await shot("regiao-%02d-panorama"%rid)
  if rid in [78,86]:
   var lot: Dictionary=w.active_region.data.lots[0];var focus:=Vector3(lot.p.x,lot.height+1,lot.p.y)
   w.player.position=w.active_region.station_points[lot.id]+Vector3(0,0,1)
   w.camera.size=22;w.camera.position=focus+Vector3(13,16,18);w.camera.look_at(focus)
   await shot("regiao-%02d-construcao"%rid)
   if rid==86:
    var holder: Node3D=w.active_region.props[0];var house: Node=holder.get_child(0)
    var entrance: Vector3=house.get_node("AnchorEntrance").position
    w.player.position=holder.global_transform*Vector3(entrance.x,.5,0)
    w.simulation_enabled=true
    for i in range(6):await physics_frame
    w.simulation_enabled=false;await shot("entrada-interior-visivel")
   if rid==86:
    w.ui.show_extra(true);await shot("mapa-regional");w.ui.exo.close_menu();w.set_paused(false)
    w.simulation_enabled=true
    for i in range(8):await physics_frame
    w.gate_cooldown=0;w.interaction_cooldown=0;w.player.position=w.residents[0].position+Vector3(0,0,.7)
    w.interact();await shot("morador-dialogo");w.ui.resume();w.simulation_enabled=false
 print("CAPTURE_DONE")
 w.set_paused(false);w.audio_fx.shutdown();w.free();quit()
