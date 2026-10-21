extends SceneTree
const Data=preload("res://genesis/region_data.gd")
const Atlas=preload("res://genesis/world_planner.gd")
const Architecture=preload("res://convergence/architecture.gd")
func _initialize():call_deferred("run")
func run():
	var fail: Array=[];var cases: Array=[];var expanded:=0;var polygons_checked:=0
	for seed_text in ["101","707","816204","9007199254740993","9223372036854775807"]:
		var atlas: Dictionary=Atlas.read_atlas("res://genesis/atlas_seed_"+seed_text+".json") if seed_text in ["101","816204"] else Atlas.plan(seed_text)
		for spec in atlas.regions:
			if spec.kind!="settlement":continue
			var data:=Data.new(atlas,int(spec.id));var polygons: Array=[];var plans: Array=[]
			for lot in data.lots:
				var result: Dictionary=Architecture.plan(data,lot)
				if not result.ok:fail.append([seed_text,spec.id,lot.id,result]);continue
				var bp: Dictionary=result.plan;expanded+=int(bp.composition=="reserved_courtyard");plans.append(bp)
				var rect: Array=bp.footprint_local_xz;var origin:=Vector2(bp.origin_world[0],bp.origin_world[2]);var polygon:=PackedVector2Array()
				for point in [Vector2(rect[0],rect[1]),Vector2(rect[2],rect[1]),Vector2(rect[2],rect[3]),Vector2(rect[0],rect[3])]:polygon.append(Architecture.transform_point(lot,point+origin))
				for other in polygons:
					polygons_checked+=1
					if not Geometry2D.intersect_polygons(polygon,other).is_empty():fail.append([seed_text,spec.id,lot.id,"footprint_overlap"])
				polygons.append(polygon)
			cases.append({"seed":seed_text,"rid":spec.id,"target":data.lots.size(),"plans":plans.size()})
	var result: Dictionary={"failures":fail,"settlements":cases.size(),"expanded_courtyards":expanded,"polygon_pairs":polygons_checked,"cases":cases}
	FileAccess.open("res://convergence/geometry_result012.json",FileAccess.WRITE).store_string(JSON.stringify(result,"\t"));print("GEOMETRY012 ",JSON.stringify({"failures":fail,"settlements":cases.size(),"expanded":expanded,"polygon_pairs":polygons_checked}));quit(int(not fail.is_empty()))
