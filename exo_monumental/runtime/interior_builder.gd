extends Node3D
## Interiores autorais dimensionados pela fachada. Somente construção da cena.
## Troca de cenas e save permanecem sob responsabilidade do serviço oficial.
@export var interior_id: String = "martial_hall"
@export var parent_site_id: String = "lab"
const PALETTE: Dictionary = {"wood": "#74503d", "wood_dark": "#3d3030", "plaster": "#d2bfa1", "stone": "#8c8c82", "gold": "#b89651", "bamboo": "#437d5c", "red": "#a3473a", "roof": "#465459"}

func _block(label: String, center: Vector3, size: Vector3, tone: String, physical: bool = true) -> Node3D:
	var visual := MeshInstance3D.new()
	visual.name = label.validate_node_name()
	visual.position = center
	var cube := BoxMesh.new(); cube.size = size; visual.mesh = cube
	var mat := StandardMaterial3D.new(); mat.albedo_color = Color(str(PALETTE.get(tone, "#cccccc")))
	visual.material_override = mat
	add_child(visual)
	if physical:
		var solid := StaticBody3D.new()
		solid.collision_layer = 4
		solid.collision_mask = 0
		visual.add_child(solid)
		var collider := CollisionShape3D.new(); var shape := BoxShape3D.new()
		shape.size = size; collider.shape = shape
		solid.add_child(collider)
	return visual

func _anchor(label: String, where: Vector3, role: String) -> void:
	var marker := Marker3D.new()
	marker.name = label.validate_node_name()
	marker.position = where
	marker.set_meta("exo_semantic_kind", role)
	marker.set_meta("interior_id", interior_id)
	marker.set_meta("site_id", parent_site_id)
	add_child(marker)

func _ready() -> void:
	var w: float = 26 if interior_id == "grand_hall" or interior_id == "fortress_command" else (17 if interior_id == "ruin_remains" else (18 if interior_id == "temple_sanctum" else 16))
	var d: float = 18 if interior_id == "grand_hall" or interior_id == "fortress_command" else (13 if interior_id == "temple_sanctum" else 12)
	var h: float = 8 if w > 20 else 5.8
	var doorway: float = 6 if w > 20 else 4.3
	var panel_w: float = (w - doorway) * 0.5
	var is_temple: bool = interior_id == "temple_sanctum"
	_block("HandlaidStoneFloor", Vector3(0, -.2, 0), Vector3(w, .38, d), "stone")
	_block("RearWall", Vector3(0, h*.5, -d*.5+.22), Vector3(w, h, .44), "plaster")
	for side in [-1.0, 1.0]:
		_block("SideWall", Vector3(side*(w*.5-.22), h*.5, 0), Vector3(.44, h, d), "plaster")
		_block("FrontPanel", Vector3(side*(doorway*.5+panel_w*.5), h*.5, d*.5-.22), Vector3(panel_w, h, .44), "plaster")
		_block("DoorPost", Vector3(side*doorway*.5, h*.43, d*.5-.25), Vector3(.43, h*.86, .45), "wood")
	_block("DoorHeadBeam", Vector3(0, h-.2, d*.5-.23), Vector3(doorway+.8, .5, .55), "wood_dark")
	# Distinct timber structure; no bland square-room fallback.
	for x in [-w*.33, w*.33]:
		for z in [-d*.28, d*.25]:
			_block("InteriorStructuralPillar", Vector3(x,h*.47,z), Vector3(.7,h*.94,.7), "wood")
			_block("PillarStoneFoot", Vector3(x,.23,z), Vector3(1.1,.46,1.1), "stone")
	for z in [-d*.3,0,d*.28]:
		_block("WoodCeilingBeam", Vector3(0,h-.25,z), Vector3(w-.7,.38,.52), "wood_dark", false)
	# Patterned martial floor / cushions, no invisible obstacles.
	for x in [-3.3,0,3.3]:
		for z in [-d*.12,d*.15]:
			_block("TrainingMat", Vector3(x,.025,z), Vector3(2.1,.045,1.5), "bamboo", false)
	_block("MasterDais", Vector3(0,.33,-d*.5+2.3), Vector3(5.0,.68,2.5), "wood")
	_block("MasterStep", Vector3(0,.12,-d*.5+4.05), Vector3(5.0,.25,.9), "wood_dark")
	_block("MasterSeat", Vector3(0,1.1,-d*.5+1.75), Vector3(1.45,1.4,.7), "red")
	for side in [-1,1]:
		var rack_x: float = float(side) * (w*.5-1.4)
		for z in [-d*.18,d*.15]:
			_block("WeaponRackPost", Vector3(rack_x,1.2,z), Vector3(.35,2.4,.35), "wood")
			_block("WeaponRackBar", Vector3(rack_x,1.7,z), Vector3(.4,.23,2.0), "gold")
		_block("CeremonyBanner", Vector3(rack_x,h*.68,-d*.48), Vector3(.08,2.0,1.0), "red",false)
	if w > 20:
		for x in [-9.0,9.0]:
			for z in [-5.6,-3.8]:
				_block("AdditionalDiscipleBench", Vector3(x,.31,z), Vector3(3.1,.55,.66), "wood")
	if is_temple:
		_block("SanctumAltar", Vector3(0,1.05,-d*.5+2.25), Vector3(5.9,2.1,1.75), "gold")
		for x in [-2,2]:_block("IncensePillar", Vector3(x,1.3,-d*.5+4.0), Vector3(.35,2.6,.35), "stone")
	if interior_id == "ruin_remains":
		for x in [-5,5]: _block("RuinedStoneFragment", Vector3(x,.28,0), Vector3(1.2,.56,1.65), "stone")
	_anchor("MestrePrincipal", Vector3(0,.75,-d*.5+3.4), "master_station")
	for x in [-3.3,0.0,3.3]:
		for z in [-d*.12,d*.15]: _anchor("DisciplePractice", Vector3(x,.1,z), "disciple_station")
	_anchor("InteriorReturn", Vector3(0,.4,d*.5-1.3), "return_anchor")
	_anchor("InteriorEntrance", Vector3(0,.4,d*.5-1.3), "entrance_anchor")
	_anchor("AssemblyStage", Vector3(0,.8,-d*.5+4.8), "martial_hall")
