from pathlib import Path
root=Path('project/EXO-Murim-EXO-Visual-01')
p=root/'cidade_viva/planner.gd'
s=p.read_text().replace('const MAX_VISUALS := {"village":12,"town":36,"city":82}','const MAX_VISUALS := {"village":14,"town":42,"city":96}\nconst Kit=preload("res://godot/modular_kit.gd")\nconst Architecture=preload("res://convergence/architecture.gd")')
anchor='static func district_of('
helpers='''static func radius_for(asset_id: String) -> float:
 Kit.ensure()
 var bounds: Array=Kit.catalog.get(asset_id,{}).get("bounds",[])
 if bounds.size()!=2:return float(FOOTPRINTS.get(asset_id,1.0))
 var extent_x: float=maxf(absf(float(bounds[0][0])),absf(float(bounds[1][0])))
 var extent_z: float=maxf(absf(float(bounds[0][2])),absf(float(bounds[1][2])))
 return maxf(float(FOOTPRINTS.get(asset_id,1.0)),Vector2(extent_x,extent_z).length())

static func reservations(data: RefCounted) -> Array:
 var result: Array=[]
 for lot in data.lots:
  var expanded: bool=lot.function in ["martial_school","shrine"] and Architecture.can_expand(data,lot)
  result.append({"p":lot.p,"yaw":lot.yaw,"min":Vector2(-5.45,-13.8 if expanded else -5.45),"max":Vector2(5.45,5.45)})
  # Facade stations in two wings, including the extended courtyard approach.
  var approach: float=4.7
  var outcome: Dictionary=Architecture.plan(data,lot)
  if outcome.ok:approach=float(outcome.plan.approach_local[2])
  result.append({"p":lot.p,"yaw":lot.yaw,"min":Vector2(-5.3,approach-.1),"max":Vector2(5.3,approach+1.45)})
 return result

static func distance_to_reservation(p: Vector2,box: Dictionary) -> float:
 var local: Vector2=(p-box.p).rotated(float(box.yaw))
 return local.distance_to(local.clamp(box.min,box.max))

'''
s=s.replace(anchor,helpers+anchor)
s=s.replace('placed: Array, ring: Array) -> bool:','placed: Array, ring: Array, reserved: Array=[]) -> bool:')
s=s.replace(' # Portas, estradas', ' for area in reserved:\n  if distance_to_reservation(p,area)<r+.35:return false\n # Portas, estradas')
s=s.replace('ring: Array,cap: int) -> bool:', 'ring: Array,cap: int,reserved: Array=[]) -> bool:')
s=s.replace('var radius: float=float(FOOTPRINTS.get(record.asset_id,1.0))','var radius: float=radius_for(str(record.asset_id))')
s=s.replace('_safe(p,radius,data,placed,ring)', '_safe(p,radius,data,placed,ring,reserved)')
s=s.replace(' var placed: Array=[]',' var reserved: Array=reservations(data)\n var placed: Array=[]')
s=s.replace(' if rng.randi_range(0,1)==1:sides.reverse()',' if rng.randi_range(0,1)==1:sides.reverse()')
a=s.index('  for sign_value in sides:');b=s.index('  # Pequenos objetos',a)
s=s[:a]+'''  var local_budget: int=3 if district in ["commerce","martial"] else 2 if scale!="village" else 1
  var accepted_for_lot:=0
  for sign_value in sides:
   for attempt in range(7):
    if placed.size()>=cap or accepted_for_lot>=local_budget:break
    var asset_id: String=str(choices[(attempt+rng.randi_range(0,choices.size()-1))%choices.size()])
    var radius: float=radius_for(asset_id)
    var pos: Vector2=lot.p+side*sign_value*(6.0+radius+float(attempt%3)*1.8)+front*(-3.0+float(attempt/3)*3.4)
    var record: Dictionary={"asset_id":asset_id,"p":pos,"yaw":float(lot.yaw),"lot_id":str(lot.id),"district":district,"purpose":"annex"}
    if _add(placed,record,data,ring,cap,reserved):
     accepted_for_lot+=1
     if district not in ["commerce","martial"]:break
''' + s[b:]
s=s.replace('data,ring,cap)', 'data,ring,cap,reserved)')
s=s.replace(' var accepted: Array=[]',' var reserved: Array=reservations(data)\n var accepted: Array=[]')
s=s.replace('_safe(obj.p,float(obj.radius),data,accepted,ring)', '_safe(obj.p,float(obj.radius),data,accepted,ring,reserved)')
s=s.replace('  accepted.append(obj)','  if float(obj.radius)+.001<radius_for(str(obj.asset_id)):issues.append("undersized_footprint:"+str(obj.asset_id))\n  accepted.append(obj)')
# Empty street plans are explicitly rejected instead of modulo by zero.
s=s.replace(' var cap_civic: int=', ' if data.settlement_roads.is_empty():cap=placed.size()\n var cap_civic: int=0 if data.settlement_roads.is_empty() else ')
p.write_text(s)
# Use the actual asset bounds for physical collision and batch the static visual layer.
p=root/'cidade_viva/renderer.gd';s=p.read_text()
a=s.index('  if float(obj.radius)>=1.4');b=s.index('  count+=1',a)
s=s[:a]+'''  if obj.asset_id not in ["vegetable_field_4m","rice_field_4m","garden_bed_2x2","herbalist_garden_box","tea_garden_bush"]:
   var bounds: Array=Kit.catalog[str(obj.asset_id)].get("bounds",[])
   if bounds.size()==2:
    var low:=Vector3(float(bounds[0][0]),float(bounds[0][1]),float(bounds[0][2]))
    var high:=Vector3(float(bounds[1][0]),float(bounds[1][1]),float(bounds[1][2]))
    var body:=StaticBody3D.new();node.add_child(body);body.collision_layer=4
    var shape:=CollisionShape3D.new();body.add_child(shape)
    var rect:=BoxShape3D.new();rect.size=(high-low).max(Vector3(.1,.1,.1))
    shape.shape=rect;shape.position=(low+high)*.5
''' + s[b:]
s=s.replace(' region.set_meta("cidade_viva_pois"',' preload("res://convergence/batch.gd").apply(layer)\n region.set_meta("cidade_viva_plan",urban)\n region.set_meta("cidade_viva_pois"')
# Reapplying the urban adapter is reversible and cannot stack duplicate objects.
s=s.replace(' var started:', ' var existing: Node=region.get_node_or_null("EXOCidadeViva01")\n if existing!=null:existing.free()\n var started:')
p.write_text(s)
