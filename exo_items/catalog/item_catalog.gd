extends RefCounted
# Read-only procedural descriptors. They are NOT game inventory definitions.
static var profiles: Dictionary = _read("profiles.json")
static var rarities: Array = _read("rarities.json")
static var materials: Array = _read("materials.json")
static var affixes: Array = _read("affixes.json")
static func _read(filename: String) -> Variant:
 var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://exo_items/data/" + filename))
 return parsed if parsed != null else {}
static func base(family: String, id: String) -> Dictionary:
 return profiles.get(family, {}).get(id, {}).duplicate(true)
static func rarity(id: String) -> Dictionary:
 for r in rarities:
  if str(r.id) == id: return r.duplicate(true)
 return {}
static func material(id: String) -> Dictionary:
 for m in materials:
  if str(m.id) == id: return m.duplicate(true)
 return {}
static func affix(id: String) -> Dictionary:
 for a in affixes:
  if str(a.id) == id: return a.duplicate(true)
 return {}
