extends RefCounted
## Composicao opcional de terreno de cla / escola circundado por muros.
## Planeja tudo antes de criar nodes para impedir instalacao parcial.
const Civic = preload("res://forja/civic_planner.gd")
const Fort = preload("res://forja/fortification_planner.gd")
const CivicBuilder = preload("res://forja/civic_builder.gd")
const FortBuilder = preload("res://forja/fortification_builder.gd")

static func plan_compound(seed_value: int, parcel: Dictionary) -> Dictionary:
	var a: Dictionary = Civic.plan_civic(seed_value,parcel)
	if not bool(a.get("ok",false)): return {"ok":false,"code":"civic_"+str(a["code"])}
	var b: Dictionary = Fort.plan_fort(seed_value,parcel)
	if not bool(b.get("ok",false)): return {"ok":false,"code":"fort_"+str(b["code"])}
	if str(a["plan"]["site_id"]) != str(b["plan"]["site_id"]): return {"ok":false,"code":"site_id_mismatch"}
	return {"ok":true,"kind":"exo_compound_plan","civic":a["plan"],"fort":b["plan"]}

static func build_compound(parent: Node3D, pack: Dictionary) -> Dictionary:
	if not is_instance_valid(parent):return {"ok":false,"code":"invalid_parent"}
	if not bool(pack.get("ok",false)) or str(pack.get("kind","")) != "exo_compound_plan":return {"ok":false,"code":"not_a_compound"}
	if not (pack.get("civic",null) is Dictionary) or not (pack.get("fort",null) is Dictionary):return {"ok":false,"code":"malformed_compound"}
	if not Civic.compatible(pack["civic"]) or not Fort.compatible(pack["fort"]):return {"ok":false,"code":"invalid_blueprint"}
	if str(pack["civic"]["site_id"]) != str(pack["fort"]["site_id"]):return {"ok":false,"code":"different_sites"}
	if pack["civic"]["origin_world"] != pack["fort"]["origin_world"] or pack["civic"]["yaw_quadrants"] != pack["fort"]["yaw_quadrants"]:return {"ok":false,"code":"site_misaligned"}
	var root_node := Node3D.new()
	root_node.name = ("Compound_" + str(pack["civic"]["site_id"])).validate_node_name()
	parent.add_child(root_node)
	var wall: Dictionary = FortBuilder.build(root_node,pack["fort"])
	if not bool(wall.get("ok",false)):
		root_node.free()
		return {"ok":false,"code":"fort_failed"}
	var site: Dictionary = CivicBuilder.build(root_node,pack["civic"])
	if not bool(site.get("ok",false)):
		root_node.free()
		return {"ok":false,"code":"civic_failed"}
	root_node.add_to_group("exo_compounds")
	return {"ok":true,"node":root_node,"wall_sections":wall["segments"],"site_objects":site["count"]}
