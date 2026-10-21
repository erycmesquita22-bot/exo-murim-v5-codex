extends RefCounted
## Applies visual-only settings to the existing world and spawned regions.
const Spec=preload("res://exo_visual/spec.gd")
var world: Node3D
var last_region_id: int=-999
var applied_materials: Dictionary={}
var last_stats: Dictionary={}
var visual_tick: float=0.0
var current_settings: Dictionary={}
func _init(owner: Node3D) -> void:
 world=owner
func apply(settings: Dictionary) -> void:
 current_settings=settings.duplicate(true)
 var viewport: Viewport=world.get_viewport()
 var forward: bool=Spec.renderer_is_forward()
 var msaa: Array=[Viewport.MSAA_DISABLED,Viewport.MSAA_2X,Viewport.MSAA_4X,Viewport.MSAA_8X]
 viewport.msaa_3d=msaa[int(settings.msaa)]
 viewport.screen_space_aa=Viewport.SCREEN_SPACE_AA_FXAA if int(settings.fxaa)>0 else Viewport.SCREEN_SPACE_AA_DISABLED
 viewport.mesh_lod_threshold=[2.0,1.0,0.55][int(settings.detail_distance)]
 if world.get("camera")!=null:world.camera.far=[155.0,345.0,650.0][int(settings.detail_distance)]
 if forward:
  viewport.scaling_3d_scale=[0.70,0.85,1.0,1.25][int(settings.render_scale)]
  viewport.scaling_3d_mode=Viewport.SCALING_3D_MODE_FSR if int(settings.upscaler)==1 else Viewport.SCALING_3D_MODE_BILINEAR
 else:viewport.scaling_3d_scale=1.0
 _apply_display(settings)
 _apply_lighting(settings,forward)
 _apply_region(settings)
func _apply_display(settings: Dictionary) -> void:
 Engine.max_fps=[0,30,60,90,120,144][int(settings.fps_limit)]
 if DisplayServer.get_name()=="headless":return
 DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if int(settings.vsync)>0 else DisplayServer.VSYNC_DISABLED)
 var window: Window=world.get_window()
 var mode: int=int(settings.window_mode)
 if mode==0:
  window.mode=Window.MODE_WINDOWED
  var target: Vector2i=Spec.DISPLAY_RESOLUTIONS[int(settings.resolution)]
  if window.size!=target:window.size=target
 elif mode==1:window.mode=Window.MODE_EXCLUSIVE_FULLSCREEN
 else:window.mode=Window.MODE_MAXIMIZED
func _apply_lighting(settings: Dictionary,forward: bool) -> void:
 var sunlight: DirectionalLight3D=world.sun
 var env: Environment=world.environment
 # Painted contact shadows remain visible at every preset.
 for node in world.find_children("SoftGroundShadow*","MeshInstance3D",true,false):node.visible=true
 var shadows: int=int(settings.shadow_quality)
 sunlight.shadow_enabled=shadows>0
 sunlight.shadow_bias=0.20
 sunlight.shadow_normal_bias=3.0
 sunlight.directional_shadow_mode=DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
 sunlight.directional_shadow_max_distance=[22.0,34.0,58.0][int(settings.shadow_distance)]
 world.get_viewport().positional_shadow_atlas_size=[0,1024,2048,4096][shadows]
 sunlight.rotation_degrees=Vector3(-48,-33,0)
 sunlight.light_color=Color("ffd1a1")
 sunlight.light_energy=0.95
 env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
 env.ambient_light_color=Color("91abc3")
 env.ambient_light_energy=[0.43,0.52,0.62][int(settings.ambient_light)]
 env.tonemap_mode=Environment.TONE_MAPPER_FILMIC
 env.tonemap_exposure=1.03
 env.adjustment_enabled=true
 env.adjustment_contrast=1.07
 env.adjustment_saturation=1.08
 env.adjustment_brightness=1.0
 env.fog_enabled=int(settings.fog)>0
 env.fog_density=[0.0,0.0015,0.003][int(settings.fog)]
 env.fog_light_color=Color("66888a")
 env.glow_enabled=int(settings.glow)>0
 env.glow_intensity=[0.0,0.18,0.36][int(settings.glow)]
 env.glow_bloom=[0.0,0.035,0.10][int(settings.glow)]
 env.ssao_enabled=int(settings.ssao)>0
 env.ssao_intensity=[0.0,0.55,1.0][int(settings.ssao)]
 env.ssao_radius=0.9
 env.ssil_enabled=forward and int(settings.ssil)>0
 env.ssil_intensity=0.65
 env.ssr_enabled=forward and int(settings.ssr)>0
 _apply_biome(env)
 _apply_clock(env,sunlight)
 for light in world.get_tree().get_nodes_in_group("profile_lights"):
  if not light is Light3D:continue
  light.visible=int(settings.ambient_light)>=int(light.get_meta("minimum_quality",0))
  light.shadow_enabled=false
func _apply_biome(env: Environment) -> void:
 var biome: String=""
 if world.get("active_region")!=null:
  var region: Node3D=world.get("active_region")
  if is_instance_valid(region) and region.get("data")!=null:
   biome=str(region.data.spec.biome)
 var lookup: Dictionary={"bamboo_forest":Color("8ca2a0"),"temperate_forest":Color("8c9eb3"),"rocky_highlands":Color("a4b4bc"),"wetland":Color("90aaa1"),"dry_valley":Color("b9a995"),"alpine":Color("a4b9d2")}
 if lookup.has(biome):env.ambient_light_color=lookup[biome]
func tick(delta: float) -> void:
 visual_tick+=delta
 if visual_tick<2.5 or current_settings.is_empty():return
 visual_tick=0.0
 _apply_clock(world.environment,world.sun)
func _apply_clock(env: Environment,sunlight: DirectionalLight3D) -> void:
 # A pure presentation of the already-persisted WorldClock: no time advance or RNG.
 if world.get("journey")==null:return
 var state: Dictionary=world.journey.data.get("convergence",{})
 var hour: float=fposmod(float(state.get("clock",900.0))/90.0,24.0)
 var daylight: float=smoothstep(5.5,8.0,hour)*(1.0-smoothstep(17.0,20.0,hour))
 for lamp in world.get_tree().get_nodes_in_group("exo_urban_lamps"):
  if lamp is Light3D:lamp.visible=daylight<.5
 sunlight.light_energy=lerpf(0.16,0.95,daylight)
 sunlight.light_color=Color("8a9ec4").lerp(Color("ffd1a1"),daylight)
 env.ambient_light_energy=[0.43,0.52,0.62][int(current_settings.get("ambient_light",1))]*lerpf(0.52,1.0,daylight)
func _apply_region(settings: Dictionary) -> void:
 var density: float=[0.0,0.25,0.5,0.75,1.0][int(settings.grass_density)]
 for node in world.get_tree().get_nodes_in_group("exo_visual_grass"):
  if not node is MultiMeshInstance3D or not is_instance_valid(node):continue
  var mesh: MultiMesh=node.multimesh
  if mesh==null:continue
  mesh.visible_instance_count=int(round(float(mesh.instance_count)*density))
  node.visibility_range_end=[30.0,65.0,110.0][int(settings.detail_distance)]
  var mat: Material=mesh.mesh.surface_get_material(0)
  if mat is ShaderMaterial:
   mat.set_shader_parameter("wind_strength",[0.0,0.065,0.14][int(settings.wind)])
   mat.set_shader_parameter("wind_speed",[0.0,0.8,1.3][int(settings.wind)])
 for node in world.get_tree().get_nodes_in_group("exo_visual_water"):
  if not node is MeshInstance3D or not is_instance_valid(node):continue
  var mat: Material=node.material_override
  if mat is ShaderMaterial:
   var quality: int=int(settings.water_quality)
   mat.set_shader_parameter("motion_strength",[0.0,0.22,0.55,0.88][quality])
   mat.set_shader_parameter("foam_strength",[0.0,0.06,0.20,0.38][quality])
   mat.set_shader_parameter("glint_strength",[0.0,0.08,0.20,0.43][quality])
   mat.set_shader_parameter("opacity",[1.0,0.98,0.95,0.91][quality])
 var filter_setting: int=int(settings.texture_filter)
 var terrain_shader: Shader=preload("res://exo_visual/shaders/terrain_pixel.gdshader") if filter_setting==0 else preload("res://exo_visual/shaders/terrain_pixel_mips.gdshader") if filter_setting==1 else preload("res://exo_visual/shaders/terrain_linear.gdshader")
 var touched: Dictionary={}
 for node in world.get_tree().get_nodes_in_group("exo_visual_terrain"):
  if not node is MeshInstance3D or not is_instance_valid(node):continue
  var mat: Material=node.material_override
  if mat is ShaderMaterial and not touched.has(mat.get_instance_id()):
   touched[mat.get_instance_id()]=true
   if mat.shader!=terrain_shader:
    var previous_params: Dictionary={}
    for uniform_name in ["forge_grass_dirt_mask","forge_dirt_stone_mask","forge_stone_grass_mask","natural_rock_tex","forge_r3_indices","ground_tex","road_tex","blend0","blend1","blend2","blend3","foliage_uv_scale","macro_seed","forge_grass_atlas","forge_dirt_atlas","forge_stone_atlas","forge_detail_atlas","forge_enabled","forge_region_offset","forge_world_seed","forge_biome_mode","forge_stone_road","forge_mix_strength"]:
     previous_params[uniform_name]=mat.get_shader_parameter(uniform_name)
    mat.shader=terrain_shader
    for uniform_name in previous_params:
     if previous_params[uniform_name]!=null:mat.set_shader_parameter(uniform_name,previous_params[uniform_name])
   mat.set_shader_parameter("exo_microvariation",[0.0,0.02,0.05][int(settings.material_detail)])
   mat.set_shader_parameter("exo_edge_irregularity",[0.07,0.11,0.15][int(settings.material_detail)])
   # Shaders can be swapped repeatedly; texture bindings must survive every switch.
   var available:bool=mat.get_shader_parameter("forge_grass_atlas") is Texture2D and mat.get_shader_parameter("forge_dirt_atlas") is Texture2D and mat.get_shader_parameter("forge_stone_atlas") is Texture2D
   var active:bool=int(settings.get("terrain_forge_enabled",1))==1 and available
   mat.set_shader_parameter("forge_enabled",active)
   mat.set_shader_parameter("forge_mix_strength",[0.35,0.61,0.86][clampi(int(settings.get("terrain_forge_mix",2)),0,2)])
 # Cosmetic MultiMesh foliage never owns collision, spawn or persistent geometry.
 for node in world.get_tree().get_nodes_in_group("exo_visual_forge_foliage"):
  if not node is MultiMeshInstance3D or not is_instance_valid(node):continue
  var active_foliage:bool=int(settings.get("terrain_forge_enabled",1))==1
  var fraction:float=[0.0,0.35,0.68,1.0][clampi(int(settings.get("terrain_forge_vegetation",2)),0,3)]
  node.visible=active_foliage and fraction>0.0
  if node.multimesh!=null:node.multimesh.visible_instance_count=int(round(float(node.multimesh.instance_count)*fraction))
  node.visibility_range_end=[35.0,70.0,100.0][clampi(int(settings.detail_distance),0,2)]
 var material_seen: Dictionary={}
 for node in world.get_tree().get_nodes_in_group("exo_visual_architecture"):
  if not node is MeshInstance3D or not is_instance_valid(node):continue
  node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_ON if int(settings.shadow_quality)>=2 else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
  var mat: Material=node.material_override
  if mat is BaseMaterial3D and not material_seen.has(mat.get_instance_id()):
   material_seen[mat.get_instance_id()]=true
   mat.texture_filter=[BaseMaterial3D.TEXTURE_FILTER_NEAREST,BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS,BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS][filter_setting]
 _apply_character_shadows(settings)
 for node in world.get_tree().get_nodes_in_group("profile_detail"):
  if node is VisualInstance3D:node.visible=int(settings.detail_distance)>=int(node.get_meta("minimum_quality",1))
 last_stats={"river_meshes":world.get_tree().get_nodes_in_group("exo_visual_water").size(),"grass_groups":world.get_tree().get_nodes_in_group("exo_visual_grass").size(),"terrain_meshes":world.get_tree().get_nodes_in_group("exo_visual_terrain").size()}
func _apply_character_shadows(settings: Dictionary) -> void:
 var enabled: bool=int(settings.character_shadows)>0 and int(settings.shadow_quality)>0
 var rigs: Array=[]
 if world.get("model")!=null:rigs.append(world.model)
 if world.get("npc")!=null:rigs.append(world.npc)
 if world.get("residents")!=null:
  for actor in world.residents:
   if is_instance_valid(actor) and actor.get("rig")!=null:rigs.append(actor.rig)
 for rig in rigs:
  if not is_instance_valid(rig):continue
  for part in rig.find_children("*","MeshInstance3D",true,false):
   part.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_ON if enabled else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
func capture_diagnostics() -> Dictionary:
 return {"fps":Performance.get_monitor(Performance.TIME_FPS),"frame_ms":Performance.get_monitor(Performance.TIME_PROCESS)*1000.0,"physics_ms":Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)*1000.0,"memory_static_bytes":Performance.get_monitor(Performance.MEMORY_STATIC),"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"objects_drawn":Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME),"triangles":Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),"visible_3d":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"renderer":RenderingServer.get_current_rendering_method(),"visual_counts":last_stats.duplicate(true)}
