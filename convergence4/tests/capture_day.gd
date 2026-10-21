extends SceneTree
var w:Node3D
var records:Array=[]
func _initialize():call_deferred("run")
func shot(label:String,focus:Vector3,size:float):
 w.camera.size=size;w.camera.position=focus+Vector3(size*.7,size*.95,size*.65);w.camera.look_at(focus)
 for i in range(5):await process_frame
 await RenderingServer.frame_post_draw
 var path:String="res://CONVERGENCIA_V4/evidence/"+label+".png"
 var result:int=root.get_texture().get_image().save_png(path)
 records.append({"image":path,"result":result,"region":w.current_region,"hour":12,"city":w.active_region.get_meta("city_forge_physical",{}),"pavements":w.active_region.get_meta("terrain_r3_pavements",{}),"interiors":w.active_region.get_meta("interior_forge_physical",{}),"crowd":w.exo_core.services.invoke("crowd.illusion","status"),"teachers":w.active_region.get_meta("city_forge_teachers",[])})
 print("DAY_CAPTURE ",JSON.stringify(records.back()))
func run():
 w=preload("res://convergence/game.gd").new();w.load_on_start=false;w.save_path="user://capture_day_v4.json";root.add_child(w);await process_frame
 w.flow.phase="creator";w.flow.create_character({"name":"V4 captura","race":0,"path":0,"robe":1,"hair":0,"skin":0,"style":0,"weapon":"sword","outfit":0},101)
 for i in range(1800):
  await physics_frame
  if w.current_region>=0 and not w.changing_region:break
 w.ui.resume();w.simulation_enabled=false;w.extension().clock=1080.0
 for rid in [7,15,14,78]:
  if not await w.change_region(rid):push_error("Capture region refused "+str(rid));quit(1);return
  w.simulation_enabled=false;w.ui.resume()
  var focus:=Vector3.ZERO
  for lot in w.active_region.data.lots:focus+=Vector3(lot.p.x,w.active_region.data.center_h,lot.p.y)
  focus/=float(w.active_region.data.lots.size())
  await shot("CityForgeR4-r"+str(rid)+"-dia",focus,240.0)
  var lot:Dictionary=w.active_region.data.lots[0]
  var at:=Vector3(lot.p.x,w.active_region.data.center_h,lot.p.y)
  await shot("CityForgeR4-r"+str(rid)+"-rua",at,55.0)
 var actor:Node3D=w.residents[0]
 var near:Vector3=w.regional_spawn(w.active_region,actor.position+Vector3(1.5,0,0))
 if near.is_finite():w.player.position=near
 w.simulation_enabled=true
 for i in range(90):await physics_frame
 w.simulation_enabled=false
 await shot("CityForgeR4-NPC03-Crowd",actor.position,35.0)
 w.ui.dialogue(str(actor.identity.display_name),w.activation_v4.npc_dialogue(actor))
 await shot("Biblioteca-NPC-dialogo",actor.position,35.0)
 w.ui.resume()
 if not w.active_region.monument_portals.is_empty():
  for portal in w.active_region.monument_portals:
   if portal.get("source")!="interior_forge_r2":continue
   w.player.position=portal.entrance_world
   var entered:Dictionary=w._enter_institutional_interior(portal)
   print("CAPTURE_INTERIOR_ENTRY ",entered)
   if entered.get("ok",false):
    await shot("InteriorForgeR2-fisico",w.institutional_root.global_position+Vector3(0,0,0),22.0)
    w.save_progress()
   break
 FileAccess.open("res://CONVERGENCIA_V4/evidence/captures.json",FileAccess.WRITE).store_string(JSON.stringify(records,"  "))
 print("CAPTURE_SAVE ",w.journey.path)
 w.queue_free();await process_frame;await process_frame;quit()
