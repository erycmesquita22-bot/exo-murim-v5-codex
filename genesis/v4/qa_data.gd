extends SceneTree
const Old=preload("res://genesis/world_planner.gd")
const Plan=preload("res://genesis/v4/world_plan.gd")
const Data=preload("res://genesis/region_data.gd")
var failures:Array=[]
var rows:Array=[]
func _initialize():call_deferred("run")
func run():
 var host:Node3D=preload("res://convergence/game.gd").new();host.load_on_start=false;host.save_path="user://data_host.json";root.add_child(host);await process_frame
 host.simulation_enabled=false
 var total_reduction:float=0.0;var gate_count:int=0;var poi_count:int=0;var water_conflicts:int=0
 for seed_text in ["101","816204","707","18026"]:
  var old:Dictionary=Old.read_atlas("res://genesis/atlas_seed_"+seed_text+".json") if seed_text in ["101","816204"] else Old.plan(seed_text)
  var atlas:Dictionary=Plan.decorate(old,"qa-world-"+seed_text,host.exo_core)
  if not Old.validate(atlas).is_empty() or not Plan.valid_atlas(atlas):failures.append(seed_text+" atlas")
  if atlas!=Plan.decorate(old,"qa-world-"+seed_text,host.exo_core):failures.append(seed_text+" determinism")
  if atlas.portals!=Plan.freeze(old).portals or atlas.rivers_macro!=Plan.freeze(old).rivers_macro:failures.append(seed_text+" topology")
  var forms:Dictionary={};var count:Dictionary={}
  var delta:float=0.0;var trees_c3:int=0;var trees_v4:int=0;var families:Dictionary={}
  for rid in range(88):
   var d:RefCounted=Data.new(atlas,rid)
   var c3:RefCounted=Data.new(old,rid)
   trees_c3+=c3.plants.size();trees_v4+=d.plants.size()
   for monument in d.monumental_plans:families[monument.kind]=int(families.get(monument.kind,0))+1
   for x in [-180,-90,0,90,180]:
    for z in [-180,-90,0,90,180]:delta+=absf(d.height_at(Vector2(x,z))-c3.height_at(Vector2(x,z)))
   var errors:Array=d.validate()
   if not errors.is_empty():failures.append({"seed":seed_text,"region":rid,"errors":errors})
   if d.plants.size()>200:failures.append("tree_budget")
   if d.spec.kind!="settlement":
    for gate in d.gates:
     for k in range(1,32):
      var at:Vector2=d.handoff_point(gate)*float(k)/32.0
      for river in d.rivers:
       if at.distance_to(Geometry2D.get_closest_point_to_segment(at,d.river_hub,river.p))<d.river_half_width(river) and d.height_at(at)<d.river_level(river,at)+.15:water_conflicts+=1
   count[str(d.spec.kind)]=int(count.get(str(d.spec.kind),0))+1
   forms[str(d.worldgen_profile.form)]=true
   poi_count+=d.landmarks.size()
   var before:Array=[];var after:Array=[]
   for g in d.gates:
    before.append(g.p.length());after.append(d.handoff_point(g).length())
    if d.spec.kind!="settlement":total_reduction+=g.p.length()-d.handoff_point(g).length();gate_count+=1
   rows.append({"seed":seed_text,"region":rid,"biome":d.spec.biome,"kind":d.spec.kind,"profile":d.worldgen_profile.form,"plants":d.plants.size(),"landmarks":d.landmarks.size(),"center_gate_c3_m":before,"center_gate_v4_m":after,"errors":errors})
  if count.get("settlement")!=23 or count.get("ruins")!=12 or count.get("dungeon_approach")!=10 or count.get("wild")!=43:failures.append("quota")
  if forms.size()<10:failures.append("profile_diversity")
  print("WG4_COMPARE ",JSON.stringify({"seed":seed_text,"profiles":forms.size(),"legacy_trees":trees_c3,"v4_trees":trees_v4,"mean_height_delta_m":delta/2200.0,"monuments":families}))
 if water_conflicts>0:failures.append("road_water_conflicts")
 var report:Dictionary={"regions":rows.size(),"road_water_conflicts":water_conflicts,"failures":failures,"landmarks_proposed":poi_count,"mean_open_gate_shortening_m":total_reduction/maxi(1,gate_count),"topology":"88 nodes, original portal/rivers preserved","rows":rows}
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://WORLDGENESIS_V4/evidence"))
 FileAccess.open("res://WORLDGENESIS_V4/evidence/seed-data.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
 print("WG4_DATA_RESULT ",JSON.stringify({"regions":rows.size(),"road_water_conflicts":water_conflicts,"failures":failures,"landmarks":poi_count,"shortening_m":total_reduction/maxi(1,gate_count)}))
 host.queue_free();await process_frame;await process_frame
 quit(0 if failures.is_empty() else 1)
