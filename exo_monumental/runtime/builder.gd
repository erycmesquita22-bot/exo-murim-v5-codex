extends RefCounted
## Renderer WITHOUT any global registry, save mutation, or world alteration.
## The calling WorldGenesis must reserve the bounds and approve the plan first.
const HITBOX_PATH: String = "res://exo_monumental/catalog/hitboxes.json"
const ASSET_PATH: String = "res://exo_monumental/assets/glb/"

static func _rotate_xz(v: Vector3, quadrants: int) -> Vector3:
	match quadrants % 4:
		1: return Vector3(v.z, v.y, -v.x)
		2: return Vector3(-v.x, v.y, -v.z)
		3: return Vector3(-v.z, v.y, v.x)
	return v

static func _marker(parent: Node3D, label: String, at: Vector3, kind: String, meta: Dictionary = {}) -> Marker3D:
	var n := Marker3D.new()
	n.name = label.validate_node_name()
	n.position = at
	n.set_meta("exo_semantic_kind", kind)
	for k in meta.keys(): n.set_meta(str(k), meta[k])
	parent.add_child(n)
	return n

static func _material(hex: String) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(hex)
	m.metallic = 0.0
	m.roughness = 1.0
	return m

static func _plinth(parent: Node3D, label: String, center: Vector3, size: Vector3, mat: Material, solid: bool = true) -> void:
	var surface := MeshInstance3D.new()
	surface.name = label.validate_node_name()
	var mesh := BoxMesh.new()
	mesh.size = size
	surface.mesh = mesh
	surface.material_override = mat
	surface.position = center
	parent.add_child(surface)
	if solid:
		var body := StaticBody3D.new()
		body.name = "Collision"
		body.collision_layer = 4
		body.collision_mask = 0
		surface.add_child(body)
		var shape := CollisionShape3D.new()
		var hitbox := BoxShape3D.new()
		hitbox.size = size
		shape.shape = hitbox
		body.add_child(shape)

static func _accessible_ramp(parent: Node3D, width: float, front_z: float, rise: float, length_m: float) -> void:
	# Accessible collision ramp joins the existing terrain to a prefab platform.
	# Top slopes toward -Z, respecting the site's local +Z approach.
	var ramp := MeshInstance3D.new()
	ramp.name = "AccessRamp"
	var box_mesh := BoxMesh.new()
	box_mesh.size = Vector3(width, .17, length_m)
	ramp.mesh = box_mesh
	ramp.material_override = _material("#918777")
	ramp.position = Vector3(0, rise * .5, front_z + length_m * .5 - .08)
	ramp.rotation.x = atan2(rise, length_m)
	parent.add_child(ramp)
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	ramp.add_child(body)
	var shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = Vector3(width, .17, length_m)
	shape.shape = box_shape
	body.add_child(shape)

static func validate_receipt(plan: Dictionary, receipt: Dictionary) -> bool:
	# Receipt issued by caller/real reservation owner AFTER committing the footprint.
	# QA_LAB_ONLY is valid exclusively for isolated laboratory scenes, never EXO world integration.
	if receipt.get("approved", false) != true: return false
	if str(receipt.get("plan_id", "")) != str(plan.get("id", "")): return false
	if str(receipt.get("site_id", "")) != str(plan.get("site_id", "")): return false
	if str(receipt.get("reservation_id", "")).is_empty(): return false
	if str(receipt.get("authority", "")) not in ["WorldGenesis", "CidadeViva", "QA_LAB_ONLY"]: return false
	if receipt.get("bounds", {}) != plan.get("bounds", {}): return false
	if str(receipt.get("authority", "")) == "QA_LAB_ONLY" and not bool(receipt.get("isolated_lab_only", false)): return false
	return true

static func set_roofs_visible(complex_root: Node3D, show_roofs: bool) -> int:
	# Camera/visibility service may call this on enter/exit or occlusion events.
	# No camera singleton or custom transition service is created.
	var changed: int = 0
	for mesh in complex_root.find_children("*", "MeshInstance3D", true, false):
		if bool(mesh.get_meta("exo_roof_occluder", false)):
			mesh.visible = show_roofs
			changed += 1
	return changed

static func build(parent: Node3D, plan: Dictionary, reservation_receipt: Dictionary = {}) -> Dictionary:
	if not is_instance_valid(parent): return {"ok": false, "code": "parent_missing"}
	if not bool(plan.get("ok", false)) or int(plan.get("schema", -1)) != 5:
		return {"ok": false, "code": "invalid_plan_schema"}
	if not validate_receipt(plan, reservation_receipt): return {"ok": false, "code": "reservation_receipt_invalid_or_missing"}
	var hitboxes: Variant = JSON.parse_string(FileAccess.get_file_as_string(HITBOX_PATH))
	if not (hitboxes is Dictionary): return {"ok": false, "code": "invalid_collider_catalog"}
	var table: Dictionary = hitboxes.get("colliders", {})
	# Preload all resources before any node is added: reject atomically on invalid GLB.
	var cache: Dictionary = {}
	for item in plan.get("instances", []):
		var aid: String = str(item.get("asset", ""))
		if aid.is_empty() or not table.has(aid): return {"ok": false, "code": "uncataloged_asset", "asset": aid}
		if not cache.has(aid):
			var resource: Resource = load(ASSET_PATH + aid + ".tscn")
			if not (resource is PackedScene): return {"ok": false, "code": "unimported_asset", "asset": aid}
			cache[aid] = resource
	var root := Node3D.new()
	root.name = ("EXO_Monument_" + str(plan["site_id"])).validate_node_name()
	root.position = Vector3(float(plan["origin_world"][0]), float(plan["origin_world"][1]), float(plan["origin_world"][2]))
	root.rotation.y = float(plan["yaw_quadrants"]) * PI * 0.5
	root.set_meta("exo_monument_id", str(plan["id"]))
	root.set_meta("exo_monument_kind", str(plan["kind"]))
	root.set_meta("exo_monument_school_id", str(plan.get("school_id", "")))
	root.set_meta("exo_monument_bounds", plan["bounds"].duplicate(true))
	root.set_meta("exo_reservation_id", str(reservation_receipt["reservation_id"]))
	root.add_to_group("exo_monumental_sites")
	parent.add_child(root)
	# Escola recebe identidade visual autoral (estandartes de cores próprias).
	var school_visual: Dictionary = plan.get("school_visual_style", {})
	if not school_visual.is_empty():
		var accent: Material = _material(str(school_visual.get("accent", "#b64031")))
		var gate_z: float = float(plan["size_m"][1]) * 0.5 - 5.0
		var school_dressing := Node3D.new()
		school_dressing.name = "SchoolIdentity_" + str(school_visual.get("architectural_style", "murim"))
		root.add_child(school_dressing)
		for side in [-1.0, 1.0]:
			_plinth(school_dressing, "DistinctiveColorBanner", Vector3(side * 6.15, 4.8, gate_z), Vector3(.24, 3.0, 1.25), accent, false)
			_plinth(school_dressing, "BannerPole", Vector3(side * 6.15, 3.0, gate_z), Vector3(.2, 6.0, .2), _material("#775039"), true)
			if int(school_visual.get("training_emphasis", 0)) >= 3:
				_plinth(school_dressing, "CeremonyPlinth", Vector3(side * 8.5, .55, gate_z - 3.0), Vector3(2.1, 1.1, 2.1), _material("#888f8c"), true)
	var floor_material := _material("#8c8a73")
	var paths_material := _material("#8b8064")
	var areas_parent := Node3D.new(); areas_parent.name = "SemanticZones"; root.add_child(areas_parent)
	for area in plan["areas"]:
		var position: Array = area["center"]
		_marker(areas_parent, "Zone_" + str(area["id"]), Vector3(float(position[0]), 0.25, float(position[1])), str(area["kind"]), area)
	for path in plan["paths"]:
		var waypoints: Array = path["points"]
		for i in range(waypoints.size()):
			_marker(areas_parent, "Path_" + str(path["id"]) + "_" + str(i), Vector3(float(waypoints[i][0]), 0.15, float(waypoints[i][1])), "navigation_waypoint", {"path_id": path["id"], "order": i, "width_m": path["width_m"]})
	var gates_parent := Node3D.new(); gates_parent.name = "Transitions"; root.add_child(gates_parent)
	var entrance: Array = plan["entrance_marker"]
	_marker(gates_parent, "EntranceAnchor", Vector3(float(entrance[0]), float(entrance[1]), float(entrance[2])), "entrance", {"site_id": plan["id"], "dungeon_family": plan["dungeon_family"]})
	var ret: Array = plan["return_marker"]
	_marker(gates_parent, "SafeExteriorReturn", Vector3(float(ret[0]), float(ret[1]), float(ret[2])), "safe_return", {"site_id": plan["id"]})
	var stations_parent := Node3D.new(); stations_parent.name = "GameplayStations"; root.add_child(stations_parent)
	for station in plan.get("stations", []):
		var at: Array = station["local"]
		var anchor: Marker3D = _marker(stations_parent, str(station["id"]), Vector3(float(at[0]), float(at[1]), float(at[2])), str(station["kind"]), {"station_id":str(plan["id"])+":"+str(station["id"]), "station_kind":str(station["kind"]), "capacity":int(station.get("capacity", 1)), "radius_m":float(station.get("radius_m",1.0))})
		anchor.add_to_group("exo_monument_gameplay_station")
	var structures := Node3D.new(); structures.name = "Modules"; root.add_child(structures)
	var sectors: Dictionary = {}
	var idx: int = 0
	for item in plan["instances"]:
		var aid: String = str(item["asset"])
		var shell: Node3D = cache[aid].instantiate()
		shell.name = ("Part_%03d_%s" % [idx, aid]).validate_node_name()
		shell.position = Vector3(float(item["x"]), float(item.get("y", 0)), float(item["z"]))
		shell.rotation.y = float(item.get("yaw", 0)) * PI * 0.5
		shell.set_meta("exo_semantic_kind", str(item.get("role", aid)))
		var gx: int = floori(float(item["x"]) / 28.0)
		var gz: int = floori(float(item["z"]) / 28.0)
		var sector_id: String = str(gx) + "_" + str(gz)
		if not sectors.has(sector_id):
			var sector := Node3D.new()
			sector.name = "Sector_" + sector_id
			structures.add_child(sector)
			sectors[sector_id] = sector
		(sectors[sector_id] as Node3D).add_child(shell)
		# Architectural roofs are separated in the authored GLBs; tag their real mesh nodes
		# so the EXO camera can hide ONLY roofing, keeping walls and floor intact.
		for mesh in shell.find_children("*", "MeshInstance3D", true, false):
			var node_label: String = str(mesh.name).to_lower()
			if "roof" in node_label or "ridge" in node_label or "eaves" in node_label:
				mesh.set_meta("exo_roof_occluder", true)
		var collision_root := StaticBody3D.new()
		collision_root.name = "SimplifiedColliders"
		collision_root.collision_layer = 4
		collision_root.collision_mask = 0
		shell.add_child(collision_root)
		var collision_pieces: Array = [] if aid == "stone_stairs" else table[aid]
		for hit in collision_pieces:
			var s := CollisionShape3D.new()
			var solid_shape := BoxShape3D.new()
			solid_shape.size = Vector3(float(hit["size"][0]), float(hit["size"][1]), float(hit["size"][2]))
			s.shape = solid_shape
			s.position = Vector3(float(hit["center"][0]), float(hit["center"][1]), float(hit["center"][2]))
			# Low structural platforms are walkable ground, separate from walls.
			if float(hit["center"][1])+float(hit["size"][1])*.5<=1.2:
				var floor_body:=StaticBody3D.new();floor_body.name="WalkablePlatform";floor_body.collision_layer=1;floor_body.collision_mask=0;shell.add_child(floor_body);floor_body.add_child(s)
			else:collision_root.add_child(s)
		match aid:
			"stone_stairs": _accessible_ramp(shell, 6.0, -2.75, 1.1, 5.5)
			"martial_hall": _accessible_ramp(shell, 3.9, 5.9, .24, 2.3)
			"grand_hall": _accessible_ramp(shell, 5.7, 8.9, .24, 2.4)
			"ancient_ruin_hall": _accessible_ramp(shell, 3.9, 5.9, .24, 2.2)
			"ancestral_temple": _accessible_ramp(shell, 4.2, 6.4, .5, 2.8)
			"wood_pavilion", "long_pavilion": _accessible_ramp(shell, 3.4, 3.9, .4, 2.6)
			"training_arena": _accessible_ramp(shell, 3.2, 6.9, .75, 4.0)
		if item.has("interior"):
			_marker(shell, "InteriorTransition", Vector3(0, 0.55, 9.2 if aid == "grand_hall" else (6.7 if aid == "ancestral_temple" else 6.4)), "interior_transition", {"interior_id": str(item["interior"]), "site_id": str(plan["id"]), "transition_owned_by": "Core/Dungeon shared transition service"})
		idx += 1
	# Small floor approach slabs only: no global terrain rework or blocking roads.
	var floor_root := Node3D.new(); floor_root.name = "ApproachStones"; root.add_child(floor_root)
	if str(plan["kind"]).begins_with("martial_"):
		_plinth(floor_root, "CourtyardStone", Vector3(0, 0.035, 6), Vector3(16, 0.07, 15), floor_material, false)
	if str(plan["kind"]).begins_with("dungeon_"):
		_plinth(floor_root, "ApproachStone", Vector3(0, 0.04, 12), Vector3(5, 0.08, 12), paths_material, false)
	return {"ok": true, "node": root, "instances": idx, "semantic_areas": plan["areas"].size(), "semantic_stations": plan.get("stations", []).size(), "sectors": sectors.size(), "state": "BUILT_IN_CALLER_SCENE"}
