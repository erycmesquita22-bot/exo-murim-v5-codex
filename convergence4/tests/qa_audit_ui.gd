extends SceneTree
var failures:Array=[]
func capture_path(file_name:String)->String:
 var directory:String=OS.get_environment("EXO_AUDIT_CAPTURE_DIR")
 if directory.is_empty():directory="user://audit-captures"
 DirAccess.make_dir_recursive_absolute(directory)
 return directory.path_join(file_name)
func _initialize():call_deferred("run")
func check(ok:bool,label:String):
 print("AUDIT_UI_CHECK ",label," ",ok)
 if not ok:failures.append(label)
func collect(n:Node)->Array:
 var texts:Array=[]
 if n is Label:texts.append(n.text)
 if n is OptionButton:
  for i in n.item_count:texts.append(n.get_item_text(i))
 for c in n.get_children():texts.append_array(collect(c))
 return texts
func run():
 var w:Node3D=preload("res://convergence/game.gd").new();w.load_on_start=false;w.save_path="user://audit_ui.json";root.add_child(w);await process_frame
 w.flow.phase="creator";w.ui.creation_tab=1
 var creator:RefCounted=preload("res://ui/character_creation.gd").new(w.ui);creator.show_creator()
 if "capture" in OS.get_cmdline_user_args():
  for i in range(6):await process_frame
  await RenderingServer.frame_post_draw
  check(root.get_texture().get_image().save_png(capture_path("creator-final.png"))==OK,"creator_capture")
 var texts:Array=collect(w.ui.flow_screen)
 var technical:Array=[]
 for t in texts:
  if "Outer Layer" in t or "right_arm" in t or "left_leg" in t or "topknot" in t or "iron_helm" in t:technical.append(t)
 print("AUDIT_UI_TECHNICAL ",technical)
 check(technical.is_empty(),"no_technical_cosmetic_labels")
 # Exercise real callbacks; persisted IDs must stay canonical.
 var option:OptionButton
 for n in w.ui.flow_screen.find_children("*","OptionButton",true,false):
  if n.item_count>1 and n.get_item_text(1) in ["topknot","Coque marcial"]:option=n;break
 check(is_instance_valid(option),"hair_option_present")
 if is_instance_valid(option):
  option.select(1);option.item_selected.emit(1)
  check(w.ui.profile.skin3d.accessories.get("hair","")=="topknot","display_translation_preserves_id")
  check(preload("res://exo_skin3d/profile_codec.gd").valid(w.ui.profile.skin3d),"cosmetic_schema_preserved")
 w.flow.phase="adventure";w.graphics.hud.style=0;w.ui.refresh()
 check(not w.ui.quest.get_parent().get_parent().visible,"official_hud_owns_tracker")
 w.graphics.hud.style=1;w.ui.refresh()
 check(w.ui.quest.get_parent().get_parent().visible,"alternative_hud_keeps_tracker")
 print("AUDIT_UI_RESULT ",JSON.stringify({"failures":failures}))
 w.queue_free();await process_frame;await process_frame;quit(0 if failures.is_empty() else 1)
