extends SceneTree
const Game=preload("res://convergence/game.gd")
var w:Node3D
var records:Array=[]
func _initialize():call_deferred("run")
func shot(label:String):
 for i in range(3):await process_frame
 await RenderingServer.frame_post_draw
 var path:String="res://V4_CHECKPOINT/evidence/"+label+".png"
 var result:int=root.get_texture().get_image().save_png(path)
 print("CAPTURE ",label," ",result)
 records.append({"file":path,"region":w.current_region,"seed":str(w.journey.data.world.seed),"camera_size":w.camera.size,"camera_position":str(w.camera.position),"renderer":RenderingServer.get_current_rendering_method()})
func run():
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://V4_CHECKPOINT/evidence"))
 w=Game.new();w.load_on_start=false;w.save_path="user://v4_capture.json";w.settings_path="user://v4_capture.cfg";root.add_child(w);await process_frame
 w.simulation_enabled=false
 await shot("01-inicio")
 w.flow.phase="creator";w.ui.show_creator()
 await shot("02-criador")
 w.flow.create_character({"name":"Murim","race":0,"path":0,"robe":1,"hair":0,"skin":0,"style":0,"weapon":"sword","outfit":0},101)
 for i in range(1600):
  await physics_frame
  if w.current_region>=0 and not w.changing_region:break
 w.simulation_enabled=false;w.ui.resume();w.graphics.set_option("vsync",0)
 await shot("03-campanha")
 await w.change_region(78);w.simulation_enabled=false
 for i in range(3):await physics_frame
 var focus:Vector3=Vector3(0,w.active_region.data.center_h,0)
 w.camera.size=80;w.camera.position=focus+Vector3(50,70,60);w.camera.look_at(focus)
 await shot("04-cidade78")
 await w.change_region(15);w.simulation_enabled=false
 for i in range(3):await physics_frame
 focus=w.active_region.monument_stations[0].world_position+Vector3(0,0,-20)
 w.camera.size=75;w.camera.position=focus+Vector3(40,55,45);w.camera.look_at(focus)
 await shot("05-escola-jade")
 FileAccess.open("res://V4_CHECKPOINT/evidence/captures.json",FileAccess.WRITE).store_string(JSON.stringify(records,"  "))
 w.queue_free();await process_frame;await process_frame;quit()
