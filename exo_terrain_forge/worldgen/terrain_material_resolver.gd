extends RefCounted
# Read-only, fail-closed resolver. No host dependencies or save mutations.
const MANIFEST_PATH = "res://exo_terrain_forge/worldgen/terrain_texture_manifest.json"
static func resolve(biome: String, moisture: float, elevation: float, paved: bool, world_x: int, world_z: int, world_seed: int) -> Dictionary:
 var file := FileAccess.open(MANIFEST_PATH, FileAccess.READ)
 if file == null:
  return {}
 var data = JSON.parse_string(file.get_as_text())
 if not data is Dictionary:
  return {}
 var profiles: Dictionary = data.get("biome_profiles", {})
 if not profiles.has(biome):
  return {}
 var profile: Dictionary = profiles[biome]
 var key := "stone" if paved else ("dirt" if moisture < 0.25 else "grass")
 var candidates: Array = profile.get(key, [])
 if candidates.is_empty():
  return {}
 var h: int = (world_seed * 73856093) ^ (world_x * 19349663) ^ (world_z * 83492791)
 var index: int = posmod(h, candidates.size())
 return {"schema": "exo.terrain.resolution.v1", "group": key, "variant_index": candidates[index], "biome": biome, "elevation": elevation}
