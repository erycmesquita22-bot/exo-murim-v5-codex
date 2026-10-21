extends SceneTree
# Native resource/parameter smoke. NOT a substitute for end-to-end terrain rendering on hardware.
const Forge=preload("res://exo_terrain_forge/worldgen/terrain_texture_adapter.gd")
const Spec=preload("res://exo_visual/spec.gd")
const Region=preload("res://genesis/region_scene.gd")
var failures: Array[String]=[]
var successes:int=0
func check(ok:bool,description:String)->void:
 if ok:successes+=1
 else:
  failures.append(description)
  push_error("R11 FAIL: "+description)
func _initialize()->void:
 check(Spec.OPTIONS.has("terrain_forge_enabled"),"settings in existing graphics")
 check(Spec.OPTIONS.has("terrain_forge_mix"),"mix control exists")
 check(Spec.OPTIONS.has("terrain_forge_vegetation"),"foliage control exists")
 var manifest:Dictionary=Forge.read_manifest()
 check(not manifest.is_empty(),"original forge manifest parse")
 for key in ["grass","dirt","stone","details","vegetation"]:
  var atlas:Dictionary=manifest.get("runtime_atlases",{}).get(key,{})
  var path:String=str(atlas.get("path",""))
  check(path.begins_with("res://exo_terrain_forge/") and ResourceLoader.exists(path),"atlas resource "+key)
 for path in ["res://genesis/terrain.gdshader","res://exo_visual/shaders/terrain_pixel.gdshader","res://exo_visual/shaders/terrain_pixel_mips.gdshader","res://exo_visual/shaders/terrain_linear.gdshader","res://exo_terrain_forge/shaders/foliage_billboard.gdshader"]:
  var shader:Shader=load(path) as Shader
  check(shader!=null and shader.code.find("shader_type spatial")>=0,"shader load "+path)
  if shader!=null and not path.ends_with("foliage_billboard.gdshader"):
   check(shader.code.find("forge_enabled")>=0,"Forge uniforms in "+path)
 var region:Node3D=Region.new()
 check(region!=null and region.has_method("build_ground"),"original worldgen region class")
 region.free()
 print(JSON.stringify({"test":"c03_r11_native","pass":successes,"fail":failures,"engine":Engine.get_version_info().get("string","")}))
 quit(0 if failures.is_empty() else 1)
