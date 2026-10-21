extends RefCounted
## One-frame snapshot of the real rig during a dodge: never copies collision, scripts or input.
static func spawn(world: Node3D) -> void:
 var quality: int=int(world.graphics.values.afterimages)
 if quality<=0 or not is_instance_valid(world.model):return
 var root:=Node3D.new()
 root.name="EXOVisualAfterimage"
 world.add_child(root)
 var material:=StandardMaterial3D.new()
 material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
 material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
 material.albedo_color=Color(0.34,0.80,0.95,0.14 if quality==1 else 0.31)
 material.cull_mode=BaseMaterial3D.CULL_DISABLED
 var count:=0
 for src in world.model.find_children("*","MeshInstance3D",true,false):
  if not src.is_visible_in_tree() or src.mesh==null:continue
  var echo:=MeshInstance3D.new()
  echo.mesh=src.mesh
  echo.material_override=material
  echo.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
  root.add_child(echo)
  echo.global_transform=src.global_transform
  count+=1
  if count>=28:break
 if count==0:root.queue_free();return
 world.effects.append({"node":root,"time":0.15 if quality==1 else 0.28})
