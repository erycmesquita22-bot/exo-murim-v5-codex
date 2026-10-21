extends SceneTree
## Capturas reais APENAS ao executar a Godot com renderização gráfica.
## godot --path . --script res://cidade_viva/tests/capture_cidade_viva.gd
const World=preload("res://genesis/world_planner.gd")
const Data=preload("res://genesis/region_data.gd")
const Scene=preload("res://convergence/region.gd")
var camera: Camera3D
var region: Node3D
var files: Array=[]
func _initialize() -> void:
 call_deferred("capture_all")
func screen(name: String,focus: Vector3,offset: Vector3,zoom: float) -> void:
 camera.size=zoom
 camera.position=focus+offset
 camera.look_at(focus)
 await process_frame
 await process_frame
 await RenderingServer.frame_post_draw
 var img: Image=root.get_texture().get_image()
 var path: String="user://cidade_viva_%s.png"%name
 var result: int=img.save_png(path)
 if result!=OK:push_error("Falha ao salvar "+path)
 else:files.append(ProjectSettings.globalize_path(path))
func load_region(seed: String,id: int,urban: bool) -> bool:
 if is_instance_valid(region):region.free()
 var atlas: Dictionary=World.read_atlas("res://genesis/atlas_seed_"+seed+".json")
 var data:=Data.new(atlas,id)
 region=Scene.new();region.urban_enabled=urban
 root.add_child(region);region.build(data,range(88));region.integrate_perimeter()
 if not region.build_errors.is_empty():push_error(str(region.build_errors));return false
 return true
func capture_all() -> void:
 root.size=Vector2i(1280,800)
 var sky:=WorldEnvironment.new();sky.environment=Environment.new()
 sky.environment.background_mode=Environment.BG_COLOR;sky.environment.background_color=Color("394d58")
 sky.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;sky.environment.ambient_light_color=Color("abb5bc");root.add_child(sky)
 var sun:=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-52,-28,0);sun.shadow_enabled=false;root.add_child(sun)
 camera=Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.current=true;camera.far=900;root.add_child(camera)
 var looks: Array=[
  ["01_original",Vector3.ZERO,Vector3(105,145,125),250],
  ["02_refinada",Vector3.ZERO,Vector3(105,145,125),250],
  ["03_entrada",Vector3(60,8,0),Vector3(70,70,72),94],
  ["04_comercio",Vector3(0,8,0),Vector3(58,75,55),85],
  ["05_residencias",Vector3(-38,8,38),Vector3(45,56,48),75],
  ["06_marcial",Vector3(22,8,36),Vector3(45,57,48),75],
  ["07_periferia",Vector3(-95,8,-80),Vector3(55,68,65),100],
  ["08_rio",Vector3(60,8,60),Vector3(85,95,90),160],
  ["09_exploracao",Vector3(8,8,10),Vector3(25,32,29),39],
  ["10_panorama",Vector3.ZERO,Vector3(125,156,150),280]]
 for k in range(looks.size()):
  var seed: String="101";var rid: int=78
  if k==7:rid=26 # verificar rio efetivo nos logs; sem rio o caso não é aceito
  if not load_region(seed,rid,k!=0):break
  var info: Array=looks[k]
  await screen(str(info[0]),info[1],info[2],float(info[3]))
 print("CIDADE_VIVA_CAPTURAS_REAIS ",JSON.stringify(files))
 quit()
