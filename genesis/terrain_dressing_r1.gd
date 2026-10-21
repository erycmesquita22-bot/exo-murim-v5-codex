extends RefCounted
# EXO-MURIM / TERRENO 01 R1 — somente apresentação do exterior.
# Não altera seeds, atlas, entradas, saves, colisões do solo ou distância das estradas.
# Limites finais por região: 420 billboards + 90 rochas; grupos MultiMesh.
const ATLAS="res://genesis/dressing_r1/foliage_original.png"
const BILLBOARD_SHADER="res://genesis/dressing_billboard_r1.gdshader"
const MAX_FOLIAGE=420
const MAX_ROCKS=90
const ROCK_COLLIDER_LIMIT=10

static func build(region: Node3D, data: RefCounted) -> void:
 if not bool(ProjectSettings.get_setting("exo_murim/terrain_r1/enabled",true)):return
 var density_scale: float=clampf(float(ProjectSettings.get_setting("exo_murim/terrain_r1/density_scale",1.0)),0.0,1.0)
 if density_scale<=0.0:return
 var rng:=RandomNumberGenerator.new()
 rng.seed=preload("res://genesis/world_planner.gd").seed_mod(data.spec.region_seed,2147483647)+0x54726
 var biome: String=str(data.spec.biome)
 var density: float=1.0
 match biome:
  "grassland": density=1.12
  "temperate_forest", "mixed_woodland": density=1.03
  "bamboo_forest": density=0.78
  "wetland": density=1.05
  "dry_valley": density=0.46
  "rocky_highlands": density=0.38
  "alpine": density=0.28
 var fol: Array=[]
 var stones: Array=[]
 var solid_count:=0
 var seed_base: float=float(preload("res://genesis/world_planner.gd").seed_mod(data.spec.region_seed,100000))*0.00001
 # Grade só para organizar manchas naturais. Cada célula é deslocada e pode
 # conter grupos densos, intervalos vazios e variações, nunca uma fileira.
 for gz in range(-8,9):
  for gx in range(-8,9):
   var center:=Vector2(float(gx)*30.0+rng.randf_range(-14.0,14.0),float(gz)*30.0+rng.randf_range(-14.0,14.0))
   if absf(center.x)>242.0 or absf(center.y)>242.0:continue
   var organic: float=0.5+0.25*sin(center.x*0.026+seed_base)+0.25*sin(center.y*0.033-seed_base)
   if rng.randf()>clampf(density*organic*density_scale,0.0,0.96):continue
   var cluster_size:=rng.randi_range(2,6)
   for k in range(cluster_size):
    var point:=center+Vector2(rng.randf_range(-10.0,10.0),rng.randf_range(-10.0,10.0))
    if absf(point.x)>246.0 or absf(point.y)>246.0:continue
    # Reservas mais generosas que o gameplay: ruas/caminhos, águas, lotes,
    # portais, árvores e áreas centrais urbanas permanecem desobstruídos.
    var road: float=data.road_distance(point)
    if road<8.5:continue
    if data.pad_distance(point)<9.0 or data.river_distance(point)<11.0:continue
    if point.length()<13.0:continue
    if str(data.spec.kind)=="settlement" and point.length()<170.0:continue
    var nearby_tree:=false
    for p in data.plants:
     if point.distance_squared_to(p.p)<6.25:
      nearby_tree=true;break
    if nearby_tree:continue
    var y: float=_height(data,point)
    var slope: float=maxf(absf(_height(data,point+Vector2(0.8,0))-y),absf(_height(data,point+Vector2(0,0.8))-y))
    if slope>0.22:continue
    var rock_chance:=0.17 if biome!="rocky_highlands" and biome!="alpine" else 0.78
    if biome=="dry_valley":rock_chance=0.40
    if rng.randf()<rock_chance:
     if stones.size()>=MAX_ROCKS or road<11.0:continue
     var size: float=rng.randf_range(0.27,0.91)
     stones.append({"point":point,"y":y,"size":size,"rotation":rng.randf_range(0.0,TAU),"hue":rng.randf()})
    else:
     if fol.size()>=MAX_FOLIAGE:continue
     var type_id:=rng.randi_range(0,4)
     if rng.randf()<(0.20 if biome!="grassland" else 0.10):type_id=rng.randi_range(5,7)
     var w: float=rng.randf_range(0.44,0.81)
     var h: float=rng.randf_range(0.39,0.73)
     if type_id>=5:w*=1.35;h*=1.50
     fol.append({"point":point,"y":y,"type":type_id,"w":w,"h":h,"tint":rng.randf()})
 if not fol.is_empty():
  _build_billboards(region,fol,biome)
 if not stones.is_empty():
  solid_count=_build_stones(region,stones,biome)
 region.set_meta("dressing_r1",{"foliage":fol.size(),"rocks":stones.size(),"rock_colliders":solid_count,"biome":biome})

static func _height(data: RefCounted, point: Vector2) -> float:
 return data.terrain_height_at(point) if data.has_method("terrain_height_at") else data.height_at(point)

static func _build_billboards(region: Node3D, items: Array, biome: String) -> void:
 var quad:=QuadMesh.new();quad.size=Vector2(1.0,1.0)
 var shader_mat:=ShaderMaterial.new()
 shader_mat.shader=load(BILLBOARD_SHADER)
 shader_mat.set_shader_parameter("foliage_atlas",load(ATLAS))
 shader_mat.set_shader_parameter("wind_strength",0.022)
 quad.material=shader_mat
 var mm:=MultiMesh.new();mm.transform_format=MultiMesh.TRANSFORM_3D
 mm.use_colors=true;mm.use_custom_data=true
 mm.mesh=quad;mm.instance_count=items.size()
 for i in range(items.size()):
  var plant: Dictionary=items[i]
  var point: Vector2=plant["point"]
  var basis:=Basis.IDENTITY.scaled(Vector3(plant["w"],plant["h"],1.0))
  var transform_value:=Transform3D(basis,Vector3(point.x,float(plant["y"])-0.055,point.y))
  mm.set_instance_transform(i,transform_value)
  var t: float=float(plant["tint"])
  var color:=Color(0.92+0.13*t,0.93+0.09*t,0.88+0.09*t)
  if biome=="dry_valley":color=Color(1.08,0.94,0.76)
  if biome=="wetland":color=Color(0.82,1.02,0.97)
  mm.set_instance_color(i,color)
  mm.set_instance_custom_data(i,Color((float(plant["type"])+0.5)/8.0,0.0,0.0,1.0))
 var group:=MultiMeshInstance3D.new();group.name="EXO_Dressing_R1_Foliage"
 group.multimesh=mm;group.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 # O AABB evita culling por origem quando a câmera se move entre chunks.
 group.custom_aabb=AABB(Vector3(-254.0,-10.0,-254.0),Vector3(508.0,140.0,508.0))
 region.add_child(group)

static func _make_rock_mesh() -> ArrayMesh:
 # Malha voxel/lowpoly irregular feita em runtime, não asset de terceiros.
 var surface:=SurfaceTool.new();surface.begin(Mesh.PRIMITIVE_TRIANGLES)
 var top: Array=[];var low: Array=[]
 for i in range(7):
  var a:=float(i)*TAU/7.0
  var radius:=0.48+0.07*sin(a*3.0+0.7)
  low.append(Vector3(cos(a)*radius,-0.02,sin(a)*radius))
  top.append(Vector3(cos(a)*radius*0.68,0.30+0.035*sin(a*2.0),sin(a)*radius*0.68))
 for i in range(7):
  var next: int=(i+1)%7
  var tone:=Color(0.74+0.05*float(i%3),0.76+0.03*float(i%3),0.78+0.02*float(i%3))
  surface.set_color(tone);surface.add_vertex(low[i])
  surface.set_color(tone);surface.add_vertex(low[next])
  surface.set_color(tone);surface.add_vertex(top[i])
  surface.set_color(tone);surface.add_vertex(low[next])
  surface.set_color(tone);surface.add_vertex(top[next])
  surface.set_color(tone);surface.add_vertex(top[i])
  surface.set_color(Color(0.93,0.93,0.89));surface.add_vertex(Vector3(0.0,0.32,0.0))
  surface.set_color(Color(0.93,0.93,0.89));surface.add_vertex(top[i])
  surface.set_color(Color(0.93,0.93,0.89));surface.add_vertex(top[next])
 surface.generate_normals()
 return surface.commit()

static func _build_stones(region: Node3D, items: Array, biome: String) -> int:
 var mesh:=_make_rock_mesh()
 var mat:=StandardMaterial3D.new()
 mat.vertex_color_use_as_albedo=true;mat.roughness=1.0
 mat.cull_mode=BaseMaterial3D.CULL_DISABLED
 mesh.surface_set_material(0,mat)
 var mm:=MultiMesh.new();mm.transform_format=MultiMesh.TRANSFORM_3D;mm.use_colors=true
 mm.mesh=mesh;mm.instance_count=items.size()
 var colliders:=0
 for i in range(items.size()):
  var rock: Dictionary=items[i]
  var size: float=rock["size"]
  var point: Vector2=rock["point"]
  var basis:=Basis(Vector3.UP,float(rock["rotation"])).scaled(Vector3(size*1.25,size, size*(0.88+0.24*float(rock["hue"]))))
  var location:=Vector3(point.x,float(rock["y"])-0.065,point.y)
  mm.set_instance_transform(i,Transform3D(basis,location))
  var tint: float=0.80+0.22*float(rock["hue"])
  var c:=Color(tint,tint*1.02,tint*1.04)
  if biome=="dry_valley":c=Color(tint*1.12,tint*1.02,tint*0.84)
  if biome=="wetland":c=Color(tint*0.87,tint*0.96,tint*0.91)
  mm.set_instance_color(i,c)
  # Somente rochas perceptíveis (muito raras) recebem colisão simples.
  if size>0.83 and colliders<ROCK_COLLIDER_LIMIT:
   var body:=StaticBody3D.new();body.collision_layer=4
   var collision:=CollisionShape3D.new()
   var shape:=BoxShape3D.new();shape.size=Vector3(size*0.85,size*0.25,size*0.75)
   collision.shape=shape;body.add_child(collision)
   body.position=location+Vector3(0.0,size*0.15,0.0);region.add_child(body)
   colliders+=1
 var group:=MultiMeshInstance3D.new();group.name="EXO_Dressing_R1_Rocks"
 group.multimesh=mm;group.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 group.custom_aabb=AABB(Vector3(-254.0,-10.0,-254.0),Vector3(508.0,140.0,508.0))
 region.add_child(group)
 return colliders
