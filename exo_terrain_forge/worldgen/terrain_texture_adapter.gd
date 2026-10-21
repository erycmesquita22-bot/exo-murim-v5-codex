extends RefCounted
# EXO-MURIM TERRAIN TEXTURE FORGE 01; additive adapter for Convergencia 03 ALFA R6.
# No new WorldGen. Reads actual spec/height/river/road/lot APIs. No new saves.
const ROOT="res://exo_terrain_forge/"
const MANIFEST=ROOT+"worldgen/terrain_texture_manifest.json"
const ATLAS=ROOT+"textures/runtime_atlases/"
const SHADER=preload("res://exo_terrain_forge/shaders/foliage_billboard.gdshader")
const CAP=170
static var cached_manifest: Dictionary={}

static func enabled() -> bool:
 return bool(ProjectSettings.get_setting("exo_murim/terrain_forge/enabled",true))

static func apply_to_ground(mat: ShaderMaterial,data: RefCounted) -> void:
 if not enabled():
  mat.set_shader_parameter("forge_enabled",false)
  return
 # Resolve all runtime texture paths from the actual catalog, not guessed paths.
 var manifest: Dictionary=read_manifest()
 if manifest.is_empty():
  mat.set_shader_parameter("forge_enabled",false)
  return
 var atlas_paths: Dictionary=manifest.get("runtime_atlases",{})
 var grass: Texture2D=load(str(atlas_paths.get("grass",{}).get("path","")))
 var dirt: Texture2D=load(str(atlas_paths.get("dirt",{}).get("path","")))
 var stone: Texture2D=load(str(atlas_paths.get("stone",{}).get("path","")))
 if grass==null or dirt==null or stone==null:
  push_warning("Terrain Forge: atlas ausente; mantendo terreno aprovado legado")
  mat.set_shader_parameter("forge_enabled",false)
  return
 mat.set_shader_parameter("forge_grass_atlas",grass)
 mat.set_shader_parameter("forge_dirt_atlas",dirt)
 mat.set_shader_parameter("forge_stone_atlas",stone)
 mat.set_shader_parameter("forge_detail_atlas",load(str(atlas_paths.get("details",{}).get("path",""))))
 var biome: String=str(data.spec.biome)
 var indices:=Vector3.ZERO
 var profiles:Dictionary=manifest.get("biome_profiles",{}).get(biome,{})
 for gi in range(3):
  var key:String=["grass","dirt","stone"][gi]
  var choices:Array=profiles.get(key,[0])
  if not choices.is_empty():indices[gi]=float(choices[preload("res://genesis/world_planner.gd").seed_mod(data.spec.region_seed,choices.size())])
 mat.set_shader_parameter("forge_r3_indices",indices)
 var mode: float=float(manifest.get("biome_mode",{}).get(biome,0))
 mat.set_shader_parameter("forge_biome_mode",mode)
 mat.set_shader_parameter("forge_region_offset",Vector2(float(data.spec.center[0]),float(data.spec.center[1])))
 # seed must be WORLD seed, not a region-random per-vertex offset.
 mat.set_shader_parameter("forge_world_seed",float(preload("res://genesis/world_planner.gd").seed_mod(data.atlas.get("seed",0),8191)))
 mat.set_shader_parameter("forge_stone_road",1.0 if str(data.spec.kind)=="settlement" else 0.04)
 mat.set_shader_parameter("forge_mix_strength",clampf(float(ProjectSettings.get_setting("exo_murim/terrain_forge/mix_strength",0.86)),0.0,1.0))
 for transition_name in ["grass_dirt","dirt_stone","stone_grass"]:
  mat.set_shader_parameter("forge_"+transition_name+"_mask",load("res://exo_terrain_forge/textures/transitions/mask_"+transition_name+".png"))
 mat.set_shader_parameter("forge_enabled",true)

static func dress(region: Node3D,data: RefCounted) -> void:
 if not enabled():return
 var density: float=clampf(float(ProjectSettings.get_setting("exo_murim/terrain_forge/foliage_density",1.0)),0.0,1.0)
 if density<=0.0:return
 var config: Dictionary=read_manifest()
 var tex: Texture2D=load(str(config.get("runtime_atlases",{}).get("vegetation",{}).get("path","")))
 if tex==null:return
 var rand:=RandomNumberGenerator.new()
 rand.seed=preload("res://genesis/world_planner.gd").seed_mod(data.spec.region_seed,2147483647)+0x4e11c
 var samples: Array=[]
 var biome: String=str(data.spec.biome)
 var natural: float=0.40 if biome=="dry_valley" else 0.24 if biome=="alpine" or biome=="rocky_highlands" else 0.78 if biome=="bamboo_forest" else 1.0
 # Clustered distribution in the existing 512m region: bounded, sparse and deterministic.
 for cz in range(-9,10):
  for cx in range(-9,10):
   if samples.size()>=CAP:break
   var center:=Vector2(float(cx)*27.0+rand.randf_range(-9.0,9.0),float(cz)*27.0+rand.randf_range(-9.0,9.0))
   if center.length()>330.0 or rand.randf()>natural*density*0.59:continue
   for k in range(rand.randi_range(1,4)):
    if samples.size()>=CAP:break
    var p:=center+Vector2(rand.randf_range(-4.5,4.5),rand.randf_range(-4.5,4.5))
    if absf(p.x)>244.0 or absf(p.y)>244.0:continue
    var rd: float=data.road_distance(p)
    if rd<5.5 or data.pad_distance(p)<9.0 or data.river_distance(p)<11.0:continue
    if str(data.spec.kind)=="settlement" and p.length()<168.0:continue
    var y: float=data.terrain_height_at(p)
    var slope: float=maxf(absf(data.terrain_height_at(p+Vector2(0.5,0.0))-y),absf(data.terrain_height_at(p+Vector2(0.0,0.5))-y))
    if slope>0.28:continue
    var w: float=rand.randf_range(0.40,0.77)
    var h: float=rand.randf_range(0.41,0.89)
    var pick: int=rand.randi_range(0,15)
    if biome=="dry_valley" and pick==4:pick=1
    samples.append({"p":p,"y":y,"w":w,"h":h,"frame":pick,"hue":rand.randf()})
 if samples.is_empty():return
 var mesh:=QuadMesh.new();mesh.size=Vector2(1.0,1.0)
 var mat:=ShaderMaterial.new();mat.shader=SHADER;mat.set_shader_parameter("atlas",tex)
 mesh.material=mat
 var mm:=MultiMesh.new();mm.transform_format=MultiMesh.TRANSFORM_3D
 mm.use_colors=true;mm.use_custom_data=true;mm.mesh=mesh;mm.instance_count=samples.size()
 for i in range(samples.size()):
  var item: Dictionary=samples[i]
  var p: Vector2=item.p
  mm.set_instance_transform(i,Transform3D(Basis.IDENTITY.scaled(Vector3(float(item.w),float(item.h),1.0)),Vector3(p.x,float(item.y)-0.04,p.y)))
  mm.set_instance_custom_data(i,Color((float(item.frame)+0.5)/16.0,0.0,0.0,1.0))
  var t: float=float(item.hue)
  mm.set_instance_color(i,Color(0.89+0.13*t,0.95+0.08*t,0.88+0.14*t))
 var node:=MultiMeshInstance3D.new();node.name="EXO_Terrain_Forge_Foliage"
 node.add_to_group("exo_visual_forge_foliage")
 node.multimesh=mm;node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 node.custom_aabb=AABB(Vector3(-254.0,-10.0,-254.0),Vector3(508.0,140.0,508.0))
 node.visibility_range_end=92.0
 region.add_child(node)
 region.set_meta("terrain_forge",{"foliage":samples.size(),"biome":biome,"seed":preload("res://genesis/world_planner.gd").seed_mod(data.spec.region_seed,2147483647)})

static func read_manifest() -> Dictionary:
 if not cached_manifest.is_empty():return cached_manifest
 if not FileAccess.file_exists(MANIFEST):return {}
 var result=JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
 if result is Dictionary:
  cached_manifest=result
  return cached_manifest
 return {}
