extends RefCounted
## Renderiza a camada já validada. Propriedade do EXO Core; sem segundo gerador.
const Kit=preload("res://godot/modular_kit.gd")
const Planner=preload("res://cidade_viva/planner.gd")
static var garden_material: StandardMaterial3D

static func garden_ground(layer: Node3D,obj: Dictionary,data: RefCounted) -> void:
 var radius: float=float(obj.get("terrain_radius",0.0))
 if radius<=0:return
 var mesh:=MeshInstance3D.new();mesh.name="UrbanGardenGround"
 var surface:=SurfaceTool.new();surface.begin(Mesh.PRIMITIVE_TRIANGLES)
 var step:=1.0;var n: int=int(ceil(radius))
 for z in range(-n,n):
  for x in range(-n,n):
   for delta in [Vector2(0,0),Vector2(1,0),Vector2(0,1),Vector2(1,0),Vector2(1,1),Vector2(0,1)]:
    var local: Vector2=Vector2(float(x),float(z))+delta
    var p: Vector2=obj.p+local
    var alpha: float=1.0-smoothstep(radius*.62,radius,local.length())
    surface.set_color(Color(1,1,1,alpha))
    surface.set_uv(p*.45);surface.set_normal(Vector3.UP)
    surface.add_vertex(Vector3(p.x,float(data.height_at(p))+.025,p.y))
 if garden_material==null:
  garden_material=StandardMaterial3D.new()
  garden_material.albedo_texture=load("res://textures/terrain_approved/grama_prado.png")
  garden_material.vertex_color_use_as_albedo=true;garden_material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
  garden_material.texture_filter=BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS;garden_material.roughness=1.0
 surface.set_material(garden_material);mesh.mesh=surface.commit();mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 layer.add_child(mesh)

static func apply(region: Node3D,fortification: Dictionary={}) -> Dictionary:
 var existing: Node=region.get_node_or_null("EXOCidadeViva01")
 if existing!=null:existing.free()
 var started: int=Time.get_ticks_usec()
 var urban: Dictionary=Planner.plan(region.data,fortification)
 if urban.status!="ready":return {"status":urban.status,"reason":urban.reason,"rendered":false}
 var defects: Array=Planner.validate(urban,region.data,fortification)
 if not defects.is_empty():return {"status":"BLOCKED","issues":defects,"rendered":false}
 Kit.ensure()
 var layer:=Node3D.new();layer.name="EXOCidadeViva01";region.add_child(layer)
 var count:=0
 var lamp_count:=0
 var lamp_limit: int=12 if region.data.spec.settlement_scale=="city" else 5 if region.data.spec.settlement_scale=="town" else 2
 for obj in urban.visuals:
  if not Kit.catalog.has(str(obj.asset_id)):
   layer.free();return {"status":"BLOCKED","reason":"asset_missing:"+str(obj.asset_id),"rendered":false}
  # Decorativos pequenos sem colisores extras; anexos maiores recebem colisor simples.
  # Objetos não são atores nem entram no registro persistente.
  var center:=Vector3(obj.p.x,float(obj.y),obj.p.y)
  garden_ground(layer,obj,region.data)
  var node: Node3D=Kit.place(layer,str(obj.asset_id),center,float(obj.yaw),"",false)
  if obj.asset_id in ["street_lamp_post","stone_garden_lantern"] and lamp_count<lamp_limit:
   var light:=OmniLight3D.new();node.add_child(light);light.position.y=1.7
   light.light_color=Color("ffbd73");light.light_energy=.85;light.omni_range=6.0
   light.shadow_enabled=false;light.visible=false;light.add_to_group("exo_urban_lamps");lamp_count+=1
  node.set_meta("urban_purpose",str(obj.purpose))
  node.set_meta("urban_owner_lot",str(obj.lot_id))
  for mesh in node.find_children("*","MeshInstance3D",true,false):
   mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
   if mesh.name=="PaintedShadow":mesh.position.y=.06
  if str(obj.asset_id).begins_with("tree_") or str(obj.asset_id).begins_with("bamboo_"):
   var trunk:=StaticBody3D.new();node.add_child(trunk);trunk.collision_layer=4;trunk.set_meta("urban_solid",true)
   var trunk_shape:=CollisionShape3D.new();var cylinder:=CylinderShape3D.new();cylinder.radius=.22;cylinder.height=2.2
   trunk_shape.shape=cylinder;trunk_shape.position.y=1.1;trunk.add_child(trunk_shape)
  elif obj.asset_id in ["open_pavilion_6m","training_pavilion_6m"]:
   for corner in [Vector2(-2.6,-2.6),Vector2(-2.6,2.6),Vector2(2.6,-2.6),Vector2(2.6,2.6)]:
    var pillar:=StaticBody3D.new();node.add_child(pillar);pillar.collision_layer=4;pillar.set_meta("urban_solid",true)
    var shape:=CollisionShape3D.new();var box:=BoxShape3D.new();box.size=Vector3(.32,3.2,.32)
    shape.shape=box;shape.position=Vector3(corner.x,1.6,corner.y);pillar.add_child(shape)
  elif obj.asset_id not in ["vegetable_field_4m","rice_field_4m","garden_bed_2x2","herbalist_garden_box","tea_garden_bush"]:
   var bounds: Array=Kit.catalog[str(obj.asset_id)].get("bounds",[])
   if bounds.size()==2:
    var low:=Vector3(float(bounds[0][0]),float(bounds[0][1]),float(bounds[0][2]))
    var high:=Vector3(float(bounds[1][0]),float(bounds[1][1]),float(bounds[1][2]))
    var body:=StaticBody3D.new();node.add_child(body);body.collision_layer=4;body.set_meta("urban_solid",true)
    var shape:=CollisionShape3D.new();body.add_child(shape)
    var rect:=BoxShape3D.new();rect.size=(high-low).max(Vector3(.1,.1,.1))
    shape.shape=rect;shape.position=(low+high)*.5
  count+=1
 preload("res://convergence/batch.gd").apply(layer)
 region.set_meta("cidade_viva_plan",urban)
 region.set_meta("cidade_viva_pois",urban.activity_pois)
 region.set_meta("cidade_viva_districts",urban.districts)
 var report: Dictionary={"status":"ready","version":Planner.VERSION,"rendered":true,"objects":count,"night_lamps":lamp_count,"districts":urban.districts,"metrics":urban.metrics,"ms":(Time.get_ticks_usec()-started)/1000.0}
 region.set_meta("cidade_viva",report)
 return report
