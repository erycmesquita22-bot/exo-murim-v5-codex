extends SceneTree
const Catalog=preload("res://exo_interior_forge/runtime/interior_catalog.gd")
const Builder=preload("res://exo_interior_forge/runtime/interior_builder.gd")
const Bridge=preload("res://exo_interior_forge/adapters/c3_work_bridge.gd")
var errors:Array=[]
func _initialize():call_deferred("run")
func run():
 var rows:Array=Catalog.get_catalog().templates
 var built:int=0
 for row in rows:
  var prefab:Dictionary=Catalog.load_prefab(str(row.id))
  var scene:Node3D=Builder.build(prefab);root.add_child(scene)
  await physics_frame
  if prefab.is_empty() or scene.get_child_count()==0:errors.append(str(row.id))
  else:built+=1
  scene.free()
 var context:Dictionary={"world_id":"QA","world_seed":101,"region_id":78,"settlement_id":"city78","lot_instance_id":"lot1","building_local_id":"house1","template_id":"house1","function":"residence","max_width_tiles":1,"max_depth_tiles":1}
 if Catalog.select_or_reuse(context).get("ok",true):errors.append("undersized_building_not_rejected")
 context.max_width_tiles=20;context.max_depth_tiles=20
 var selection:Dictionary=Catalog.select_or_reuse(context)
 if not selection.get("ok",false):errors.append("valid_selection")
 elif Catalog.select_or_reuse(context,selection.receipt).get("receipt")!=selection.receipt:errors.append("receipt_reuse")
 if Bridge.prepare(context,{},selection.get("receipt",{}),{}).get("ok",false):errors.append("unapproved_portal")
 print("INTERIOR_V4_NATIVE ",JSON.stringify({"layouts":rows.size(),"built":built,"failures":errors,"coverage":"geometry instantiated, no host transition enabled"}))
 quit(0 if rows.size()==52 and built==52 and errors.is_empty() else 1)
