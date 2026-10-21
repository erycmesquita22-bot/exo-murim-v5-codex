extends SceneTree
const Game=preload("res://convergence/game.gd")
const Data=preload("res://genesis/region_data.gd")
var failures:Array=[]
var checks:int=0
func check(ok:bool,label:String):
 checks+=1;print("WG4_NEW_CHECK ",label," ",ok)
 if not ok:failures.append(label)
func _initialize():call_deferred("run")
func run():
 var seed_value:int=707
 var reopen:bool="--reopen" in OS.get_cmdline_user_args()
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--seed="):seed_value=int(arg.trim_prefix("--seed="))
 if reopen:ProjectSettings.set_setting("exo_murim/worldgen_v4/new_campaigns_enabled",false)
 var w:Node3D=Game.new();w.load_on_start=reopen;w.save_path="user://wg4_seed_%d.json"%seed_value;w.settings_path="user://wg4_seed.cfg";root.add_child(w);await process_frame
 check(w.exo_core.ready,"core")
 if not reopen:
  w.flow.phase="creator"
  check(w.flow.create_character({"name":"WG4 seed proof","race":0,"path":0,"robe":1,"hair":0,"skin":0,"style":0,"weapon":"sword","outfit":0},seed_value),"actual_creator")
 if not failures.is_empty():quit(1);return
 for i in range(2000):
  await physics_frame
  if w.current_region>=0 and not w.changing_region:break
 w.ui.resume();w.simulation_enabled=false
 check(w.current_region>=0 and not w.changing_region,"physical_boot")
 if w.current_region<0:quit(1);return
 check(w.extension().has("worldgen_v4") and int(w.extension().regional_version)==7,"campaign_pinned_v4")
 check(int(w.atlas.seed)==seed_value and w.atlas.regions.size()==88,"seed_and_graph")
 check(w.active_region.data.worldgen_v4 and w.atlas.worldgen_v4.generator==4,"physical_generator_v4")
 var corrupt:Dictionary=w.extension().duplicate(true);corrupt.erase("worldgen_v4")
 check(not preload("res://convergence/state.gd").valid(corrupt),"stripped_version_rejected")
 var path:String="user://wg4_expected_%d.json"%seed_value
 if not reopen:
  var target:int=-1
  for spec in w.atlas.regions:
   if spec.kind!="settlement" and spec.biome in ["rocky_highlands","alpine"]:target=int(spec.id);break
  check(target>=0 and await w.change_region(target),"new_seed_mountain_scene")
  var old:Dictionary=w.atlas.duplicate(true);old.erase("worldgen_v4")
  for spec in old.regions:spec.erase("worldgen_v4")
  check(not preload("res://genesis/v4/world_plan.gd").valid_atlas(old),"legacy_atlas_rejected")
  check(w.active_region.has_meta("terrain_forge"),"terrain_forge_executed")
  var forge_material:bool=false
  for child in w.active_region.get_children():
   if child is MeshInstance3D and child.is_in_group("exo_visual_terrain") and child.material_override is ShaderMaterial:
    forge_material=bool(child.material_override.get_shader_parameter("forge_enabled"));break
  check(forge_material,"terrain_forge_material_enabled")
  print("WG4_NEW_TERRAIN ",w.active_region.get_meta("terrain_forge",{}))
  check(w.save_progress(),"save")
  FileAccess.open(path,FileAccess.WRITE).store_string(JSON.stringify({"region":w.current_region,"digest":w.active_region.data.digest(),"atlas":JSON.stringify(w.atlas).sha256_text()}))
 else:
  var expected:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(path))
  check(w.current_region==int(expected.region),"reopen_region")
  check(w.active_region.data.digest()==str(expected.digest),"reopen_physical_digest")
  check(JSON.stringify(w.atlas).sha256_text()==str(expected.atlas),"reopen_frozen_atlas")
 print("WG4_NEW_CAMPAIGN_RESULT ",JSON.stringify({"checks":checks,"failures":failures,"seed":seed_value,"reopen":reopen,"region":w.current_region,"generator":4}))
 w.queue_free();await process_frame;await process_frame;quit(0 if failures.is_empty() else 1)
