extends RefCounted
## Contrato opcional Forja -> World Genesis. Genesis permanece dono dos lotes e estradas.
## Planos de V02 das casas continuam no forja_planner.gd.
const Fort = preload("res://forja/fortification_planner.gd")
const Walls = preload("res://forja/fortification_builder.gd")
const Civic = preload("res://forja/civic_planner.gd")
const Site = preload("res://forja/civic_builder.gd")
const Compound = preload("res://forja/compound_assembler.gd")
const Green = preload("res://forja/green_buffer_v3.gd")
const TYPES: Array[String] = ["fort", "civic", "compound", "green"]
const MAX_SITES_PER_BATCH: int = 32

static func _reject(code: String, index: int = -1) -> Dictionary:
	return {"ok":false,"code":code,"index":index,"blueprints":[]}

static func _number(value: Variant) -> bool:
	return typeof(value) in [TYPE_INT,TYPE_FLOAT] and is_finite(float(value))

static func _rect(lot: Dictionary) -> Array:
	var cx: float = float(lot["center_x"])
	var cz: float = float(lot["center_z"])
	var hw: float = float(lot["width_m"])*.5
	var hd: float = float(lot["depth_m"])*.5
	if int(lot.get("yaw_quadrants",0)) % 2 == 1:
		var tmp: float = hw
		hw = hd
		hd = tmp
	return [cx-hw,cz-hd,cx+hw,cz+hd]

static func _overlap(a: Array,b: Array) -> bool:
	return a[0]<b[2]-.001 and a[2]>b[0]+.001 and a[1]<b[3]-.001 and a[3]>b[1]+.001

static func plan_sites(seed_value: int, requested: Array) -> Dictionary:
	if requested.size()>MAX_SITES_PER_BATCH:return _reject("over_site_batch_limit")
	var seen: Dictionary = {}
	var bounds: Array = []
	var plans: Array[Dictionary] = []
	for index in range(requested.size()):
		var record: Variant = requested[index]
		if not (record is Dictionary):return _reject("invalid_request",index)
		var role: String = str(record.get("kind",""))
		if role not in TYPES:return _reject("unsupported_request_kind",index)
		var lot: Variant = record.get("parcel",null)
		if not (lot is Dictionary):return _reject("missing_parcel",index)
		var id: String = str(lot.get("id",""))
		if id.is_empty() or seen.has(id):return _reject("missing_or_duplicate_site_id",index)
		seen[id] = true
		for k in ["center_x","center_z","width_m","depth_m"]:
			if not lot.has(k) or not _number(lot[k]):return _reject("invalid_site_dimensions",index)
		var orientation: Variant = lot.get("yaw_quadrants",0)
		if typeof(orientation)!=TYPE_INT or int(orientation) not in [0,1,2,3]:return _reject("invalid_orientation",index)
		var box: Array = _rect(lot)
		for other in bounds:
			if _overlap(box,other):return _reject("site_parcels_overlap",index)
		var result: Dictionary
		match role:
			"fort":result = Fort.plan_fort(seed_value,lot)
			"civic":result = Civic.plan_civic(seed_value,lot)
			"compound":result = Compound.plan_compound(seed_value,lot)
			"green":result = Green.plan(seed_value,lot)
		if not bool(result.get("ok",false)):
			return _reject(role+"_"+str(result.get("code","unknown")),index)
		bounds.append(box)
		var blue: Dictionary = result if role == "compound" else result["plan"]
		plans.append({"kind":role,"blueprint":blue})
	return {"ok":true,"blueprints":plans,"count":plans.size()}

static func build_sites(parent: Node3D, agreed: Dictionary) -> Dictionary:
	if not is_instance_valid(parent):return {"ok":false,"code":"invalid_parent","nodes":[]}
	if not bool(agreed.get("ok",false)) or not (agreed.get("blueprints",null) is Array):
		return {"ok":false,"code":"missing_approved_batch","nodes":[]}
	var blueprints: Array = agreed["blueprints"]
	if blueprints.size()>MAX_SITES_PER_BATCH:return {"ok":false,"code":"batch_over_limit","nodes":[]}
	# Recalcula o loteamento INTEIRO para impedir troca de planta, duplicata e sobreposicao.
	var requested: Array = []
	var common_seed: int = 0
	var first := true
	for pair in blueprints:
		if not (pair is Dictionary) or str(pair.get("kind","")) not in TYPES or not (pair.get("blueprint",null) is Dictionary):
			return {"ok":false,"code":"bad_blueprint","nodes":[]}
		var kind: String = str(pair["kind"])
		var payload: Dictionary = pair["blueprint"]
		var actual: Dictionary = payload
		if kind == "compound":
			if not (payload.get("civic",null) is Dictionary) or not (payload.get("fort",null) is Dictionary):
				return {"ok":false,"code":"bad_compound","nodes":[]}
			actual = payload["civic"]
		var source: Variant = actual.get("source_parcel",null)
		var seed_key: String = "seed" if kind == "green" else "world_seed"
		if not (source is Dictionary) or typeof(actual.get(seed_key,null)) != TYPE_INT:
			return {"ok":false,"code":"invalid_plan_source","nodes":[]}
		var current_seed: int = int(actual[seed_key])
		if not first and current_seed != common_seed:return {"ok":false,"code":"mixed_seeds","nodes":[]}
		first = false
		common_seed = current_seed
		requested.append({"kind":kind,"parcel":source})
	var canonical: Dictionary = plan_sites(common_seed,requested)
	if not bool(canonical.get("ok",false)) or canonical["blueprints"] != blueprints:
		return {"ok":false,"code":"batch_modified_or_conflicting","nodes":[]}
	var created: Array[Node3D] = []
	for pair in blueprints:
		var payload: Dictionary = pair["blueprint"]
		var result: Dictionary
		match str(pair["kind"]):
			"fort":result = Walls.build(parent,payload)
			"civic":result = Site.build(parent,payload)
			"compound":result = Compound.build_compound(parent,payload)
			"green":result = Green.build(parent,{"ok":true,"plan":payload})
		if not bool(result.get("ok",false)):
			for node in created:node.free()
			return {"ok":false,"code":"instantiate_failed","nodes":[]}
		created.append(result["node"])
	return {"ok":true,"nodes":created,"count":created.size()}
