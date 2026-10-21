extends RefCounted
const Catalog=preload("res://exo_dungeon/layouts/room_catalog.gd")
static func describe(family: String) -> Dictionary:
 if not Catalog.is_supported(family):return {}
 var d: Dictionary=Catalog.profile(family)
 d["materials_owner"]="EXO Forja/coleção original de EXO"
 d["fallback_geometry"]="Original voxels from Dungeon Genesis lab"
 return d
