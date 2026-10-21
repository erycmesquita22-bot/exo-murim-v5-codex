extends SceneTree
var failures:Array=[]
func _initialize():call_deferred("run")
func run():
 var w:Node3D=preload("res://convergence/game.gd").new();w.load_on_start=false;w.save_path="user://library_ui_v4.json";root.add_child(w);await process_frame
 w.flow.phase="creator";w.flow.create_character({"name":"Biblioteca UI QA","race":0,"path":0,"robe":1,"hair":0,"skin":0,"style":0,"weapon":"sword","outfit":0},101)
 for i in range(1800):
  await physics_frame
  if w.current_region>=0 and not w.changing_region:break
 if not await w.change_region(78):failures.append("city");quit(1);return
 w.simulation_enabled=false;w.ui.resume()
 var shown:int=0
 for actor in w.residents:
  var text:String=w.activation_v4.npc_dialogue(actor)
  if text.is_empty():continue
  w.ui.dialogue(str(actor.identity.display_name),text);await process_frame
  if not w.ui.modal.visible:failures.append("dialogue_hidden")
  else:shown+=1
  w.ui.resume();w.journey_manager.options(actor.identity)
 if shown==0:failures.append("no_authorial_dialogue")
 if not w.save_progress():failures.append("save")
 var loaded:RefCounted=preload("res://journey_save.gd").new(w.journey.path);loaded.load_progress()
 if loaded.data.get("convergence",{}).get("activation_v4",{}).get("consumed",{})!=w.activation_v4.state().consumed:failures.append("consumption_reload")
 print("LIBRARY_UI_CONSUMED ",JSON.stringify(w.activation_v4.state().consumed))
 print("LIBRARY_UI_RESULT ",JSON.stringify({"failures":failures,"dialogues_rendered":shown,"consumed_records":w.activation_v4.state().consumed.size()}))
 w.queue_free();await process_frame;await process_frame;quit(0 if failures.is_empty() else 1)
