extends RefCounted
## EXO Forja 02 — detalhes por função. Os novos GLBs existem fisicamente no catalogo.
## Todos os props usam collision=false no GLB; apenas obstaculos grandes recebem caixa unica.
const Kit = preload("res://godot/modular_kit.gd")
const MAX_PER_PROFILE = {"low": 12, "medium": 26, "high": 50}

static func _solid(node: Node3D, center: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	body.name = "SimpleStaticObstacle"
	node.add_child(body)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	shape.position = center

static func _part(root: Node3D, id: String, pos: Vector3, palette: String, yaw: float = 0.0, solid_center: Vector3 = Vector3.ZERO, solid_size: Vector3 = Vector3.ZERO) -> Node3D:
	var node: Node3D = Kit.place(root, id, pos, yaw, palette, false)
	if solid_size.length_squared() > 0.0:
		_solid(node, solid_center, solid_size)
	return node

static func apply(house: Node3D, plan: Dictionary) -> Dictionary:
	var archetype: String = str(plan["archetype"])
	var profile: String = str(plan["detail_profile"])
	if profile not in MAX_PER_PROFILE: return {"ok": false}
	var pal: String = str(plan["palette"])
	var w: float = float(plan["width_m"])
	var stories: int = int(plan["stories"])
	var door_x: float = float(plan["entrance_local"][0])
	var left_x: float = -w * 0.5 + 1.0
	var top_y: float = 0.4 + float(stories) * 2.6
	var rng := RandomNumberGenerator.new()
	rng.seed = int(plan["decor_seed"])
	var node := Node3D.new()
	node.name = "ForjaDetails"
	house.add_child(node)
	var ids: Array[String] = []
	# Qualidade baixa preserva silhueta, sem colocar ornamentos pesados.
	match archetype:
		"standard":
			_part(node, "bamboo_planter_box", Vector3(left_x, 0.0, 3.75), pal)
			ids.append("bamboo_planter_box")
		"veranda":
			_part(node, "public_timber_bench", Vector3(left_x, 0.0, 3.65), pal, 0.0, Vector3(0.0,0.50,0.0), Vector3(1.62,1.0,0.43))
			ids.append("public_timber_bench")
			for side in [-1.0, 1.0]:
				_part(node, "veranda_bamboo_railing_2m", Vector3(side * (w*0.5+0.85),0.0,3.3),pal,PI*0.5)
				ids.append("veranda_bamboo_railing_2m")
		"merchant":
			_part(node, "market_cloth_awning_2m", Vector3(left_x, 2.55, 2.35), pal)
			_part(node, "merchant_counter_2m", Vector3(left_x, 0.0, 3.45), pal, 0.0, Vector3(0.0,0.6,0.0), Vector3(1.98,1.20,0.75))
			_part(node, "shop_hanging_sign", Vector3(left_x, 2.47, 2.60), pal)
			ids.append_array(["market_cloth_awning_2m", "merchant_counter_2m", "shop_hanging_sign"])
		"teahouse":
			_part(node, "market_cloth_awning_2m", Vector3(left_x, 2.55, 2.35), pal)
			_part(node, "tea_table_with_stools", Vector3(left_x, 0.0, 3.8), pal, 0.0, Vector3(0.0,.5,0.0), Vector3(1.97,1.00,1.0))
			_part(node, "shop_hanging_sign", Vector3(left_x, 2.57, 2.65), pal)
			ids.append_array(["market_cloth_awning_2m", "tea_table_with_stools", "shop_hanging_sign"])
		"forge":
			_part(node, "blacksmith_forge_hearth", Vector3(left_x, 0.0, 3.70), pal, 0.0, Vector3(0.0,1.04,0.0), Vector3(1.60,2.10,1.12))
			_part(node, "blacksmith_anvil", Vector3(left_x, 0.0, 2.70), pal, 0.0, Vector3(0.0,0.50,0.0), Vector3(1.16,0.99,0.6))
			ids.append_array(["blacksmith_forge_hearth", "blacksmith_anvil"])
		"herb_shop":
			_part(node, "facade_lattice_2m", Vector3(left_x,0.4,2.17),pal)
			ids.append("facade_lattice_2m")
			_part(node, "herb_drying_rack", Vector3(left_x, 0.0, 3.18), pal)
			_part(node, "herbalist_medicine_jars", Vector3(left_x, 0.0, 4.10), pal)
			_part(node, "shop_hanging_sign", Vector3(left_x, 2.55, 2.58), pal)
			ids.append_array(["herb_drying_rack", "herbalist_medicine_jars", "shop_hanging_sign"])
		"inn":
			_part(node, "facade_lattice_2m",Vector3(left_x,3.0,2.17),pal)
			ids.append("facade_lattice_2m")
			_part(node, "silk_vertical_banner", Vector3(left_x, 2.25, 2.52), pal)
			_part(node, "shop_hanging_sign", Vector3(left_x, 3.08, 2.57), pal)
			_part(node, "public_timber_bench", Vector3(left_x, 0.0, 3.70), pal, 0.0, Vector3(0.0,.5,0.0), Vector3(1.62,1.0,.43))
			ids.append_array(["silk_vertical_banner", "shop_hanging_sign", "public_timber_bench"])
		"courtyard":
			# A entrada real da casa continua z=3.02. O portao do patio fica em z=6.2.
			_part(node, "courtyard_entry_gate", Vector3(door_x,0.0,6.2), pal)
			for gate_side in [-1.0,1.0]:
				_solid(node, Vector3(door_x + gate_side * 1.25, 1.47, 6.2), Vector3(.26,2.95,.32))
				_part(node, "courtyard_wall_2m", Vector3(door_x + gate_side * 2.45, 0.0, 6.2), pal, 0.0, Vector3(0.0,.80,0.0), Vector3(2.0,1.65,.40))
				_part(node, "courtyard_wall_2m", Vector3(gate_side * 3.45, 0.0, 4.95), pal, PI*0.5, Vector3(0.0,.80,0.0), Vector3(2.0,1.65,.40))
				ids.append_array(["courtyard_wall_2m", "courtyard_wall_2m"])
			for z in [3.8,5.6]:
				_part(node, "stone_courtyard_paving_2m", Vector3(door_x,0.0,z), pal)
				ids.append("stone_courtyard_paving_2m")
			ids.append("courtyard_entry_gate")
			_part(node, "bamboo_planter_box", Vector3(-2.05,0,4.5), pal)
			ids.append("bamboo_planter_box")
		_:
			return {"ok": false}
	var must_have_count: int = ids.size()
	if profile != "low":
		# Variacao cosmetica deterministica, sem ocupar o corredor da porta.
		if archetype != "courtyard":
			for x_index in range(int(w / 2.0)):
				var x: float = -w * 0.5 + 1.0 + 2.0 * x_index
				_part(node,"roof_tile_eave_2m",Vector3(x,top_y,2.48),pal)
				ids.append("roof_tile_eave_2m")
		if archetype in ["merchant", "herb_shop", "inn"]:
			_part(node,"woven_market_baskets",Vector3(left_x,0,4.28),pal)
			ids.append("woven_market_baskets")
		elif archetype == "teahouse":
			_part(node,"silk_vertical_banner",Vector3(w*0.5+0.6,2.2,2.5),pal)
			ids.append("silk_vertical_banner")
		elif archetype == "forge":
			_part(node,"smith_tool_rack",Vector3(left_x,1.2,2.22),pal)
			ids.append("smith_tool_rack")
		elif archetype == "courtyard":
			_part(node,"stone_garden_lantern",Vector3(2.22,0,4.8),pal,0.0,Vector3(0,1.0,0),Vector3(.85,2.0,.85))
			ids.append("stone_garden_lantern")
		elif archetype == "veranda":
			_part(node,"silk_vertical_banner",Vector3(left_x,2.2,2.45),pal)
			ids.append("silk_vertical_banner")
		else:
			_part(node,"facade_lattice_2m",Vector3(left_x,0.4,2.17),pal)
			ids.append("facade_lattice_2m")
	if profile == "high":
		for side in [-1.0, 1.0]:
			_part(node,"roof_ridge_finial",Vector3(side * (w*.5+.06),top_y+1.1,0.0),pal)
			ids.append("roof_ridge_finial")
		if archetype in ["merchant", "herb_shop", "inn"]:
			_part(node,"grain_sack_stack",Vector3(-w*.5-0.6,0,4.20),pal)
			ids.append("grain_sack_stack")
		elif archetype == "teahouse":
			_part(node,"tea_ceramic_shelf",Vector3(left_x,0,2.40),pal)
			ids.append("tea_ceramic_shelf")
		elif archetype == "forge" and w >= 6.0:
			_part(node,"village_grain_millstone",Vector3(w * 0.5 - 1.0,0,3.70),pal,0.0,Vector3(0,.35,0),Vector3(1.30,.70,1.30))
			ids.append("village_grain_millstone")
		elif archetype == "courtyard":
			_part(node,"bronze_incense_burner",Vector3(-2.05,0,5.65),pal)
			ids.append("bronze_incense_burner")
		elif archetype == "veranda":
			pass  # guarda-corpos ja ocupam ambas laterais; evita decorar por cima deles
		else:
			if rng.randi_range(0,1) == 0:
				_part(node,"woven_market_baskets",Vector3(-w*.5-.63,0,4.05),pal)
				ids.append("woven_market_baskets")
			else:
				_part(node,"stone_garden_lantern",Vector3(-w*.5-.8,0,4.05),pal)
				ids.append("stone_garden_lantern")
	if ids.size() > int(MAX_PER_PROFILE[profile]): return {"ok": false, "code": "detail_budget_exceeded"}
	node.set_meta("forja_asset_ids", ids)
	node.set_meta("essential_count", must_have_count)
	node.set_meta("detail_profile", profile)
	return {"ok": true, "count": ids.size()}
