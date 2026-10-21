extends Node
## Session-local presentation only. No writes to progression, discovery or save.
## Compatibility: small CPU line-of-sight mask, no compute/volumetric fog.
const GRID:int=25
const RADIUS:float=12.0
const INTERVAL:float=0.2
var world:Node3D
var actor:Node3D
var dungeon:Node3D
var camera:Camera3D
var original_size:float
var original_environment:Environment
var mask:Image
var texture:ImageTexture
var overlay:ShaderMaterial
var origin:Vector2
var timer:float=0.0
var restored:bool=false
var overlays:Array=[]
var overlay_ids:Dictionary={}
var ray_count:int=0
var geometry_id:int=0
func initialize(host:Node3D,player:Node3D,instance:Node3D)->void:
 world=host;actor=player;dungeon=instance
 camera=host.get("camera") as Camera3D
 if not is_instance_valid(camera):set_physics_process(false);return
 original_size=camera.size;original_environment=camera.environment
 var source:Environment=original_environment if original_environment!=null else host.get("environment") as Environment
 var environment:Environment=source.duplicate() if source!=null else Environment.new()
 environment.background_mode=Environment.BG_COLOR
 environment.background_color=Color(0.008,0.009,0.014)
 environment.fog_enabled=false
 camera.environment=environment
 mask=Image.create(GRID,GRID,false,Image.FORMAT_R8)
 mask.fill(Color.BLACK);texture=ImageTexture.create_from_image(mask)
 overlay=ShaderMaterial.new();overlay.shader=preload("res://exo_dungeon/runtime/vision_overlay.gdshader")
 overlay.set_shader_parameter("visibility_mask",texture)
 overlay.set_shader_parameter("mask_width",float(GRID))
 _attach_overlays(dungeon)
 var geometry:Node=dungeon.get("geometry")
 if is_instance_valid(geometry):geometry_id=geometry.get_instance_id()
 refresh_visibility()
func _attach_overlays(root:Node)->void:
 for mesh in root.find_children("*","MeshInstance3D",true,false):
  var id:int=mesh.get_instance_id()
  if overlay_ids.has(id):continue
  overlays.append({"mesh":weakref(mesh),"previous":mesh.material_overlay})
  overlay_ids[id]=true;mesh.material_overlay=overlay
func _physics_process(delta:float)->void:
 if restored or not is_instance_valid(camera) or not is_instance_valid(actor):return
 camera.size=move_toward(camera.size,minf(original_size,11.5),delta*12.0)
 timer-=delta
 if timer<=0.0:
  timer=INTERVAL;refresh_visibility()
func refresh_visibility()->void:
 if restored or overlay==null or not is_instance_valid(actor) or not is_instance_valid(dungeon):return
 var eye:Vector3=actor.global_position+Vector3.UP*1.1
 var forward:Vector3=world.get("facing")
 forward.y=0.0
 if forward.length_squared()<0.001:forward=Vector3.FORWARD
 forward=forward.normalized()
 # World-aligned cells keep the mask stable while walking.
 origin=Vector2(floorf(eye.x)-12.5,floorf(eye.z)-12.5)
 mask.fill(Color.BLACK);ray_count=0
 var space:PhysicsDirectSpaceState3D=world.get_world_3d().direct_space_state
 for z in range(GRID):
  for x in range(GRID):
   var target:Vector3=Vector3(origin.x+x+0.5,eye.y,origin.y+z+0.5)
   var offset:Vector3=target-eye
   var distance:float=offset.length()
   if distance>RADIUS:continue
   if distance>2.0 and forward.dot(offset.normalized())<0.26:continue
   var strength:float=1.0-smoothstep(9.5,RADIUS,distance)
   if distance>0.75:
    var ray:PhysicsRayQueryParameters3D=PhysicsRayQueryParameters3D.create(eye,target,1|4)
    if actor is CollisionObject3D:ray.exclude=[actor.get_rid()]
    ray_count+=1
    if not space.intersect_ray(ray).is_empty():strength=0.0
   mask.set_pixel(x,z,Color(strength,strength,strength))
 texture.update(mask);overlay.set_shader_parameter("mask_origin",origin)
 overlay.set_shader_parameter("actor_height",eye.y)
 # Loot/key geometry may be rebuilt after a save rollback.
 var geometry:Node=dungeon.get("geometry")
 if is_instance_valid(geometry) and geometry.get_instance_id()!=geometry_id:
  geometry_id=geometry.get_instance_id();_attach_overlays(dungeon)
 # These are existing official combat actors; fog does not alter their AI.
 for enemy in world.get("enemies"):
  if is_instance_valid(enemy) and enemy.has_meta("exo_dungeon_id"):_attach_overlays(enemy)
func visibility_at(point:Vector3)->float:
 if mask==null:return 0.0
 if is_instance_valid(actor) and absf(point.y-actor.global_position.y)>6.0:return 0.0
 var x:int=floori(point.x-origin.x);var z:int=floori(point.z-origin.y)
 if x<0 or z<0 or x>=GRID or z>=GRID:return 0.0
 return mask.get_pixel(x,z).r
func restore()->void:
 if restored:return
 restored=true
 if is_instance_valid(camera):camera.size=original_size;camera.environment=original_environment
 for entry in overlays:
  var mesh:MeshInstance3D=entry.mesh.get_ref() as MeshInstance3D
  if is_instance_valid(mesh) and mesh.material_overlay==overlay:mesh.material_overlay=entry.previous
 overlays.clear();overlay_ids.clear()
func _exit_tree()->void:restore()
