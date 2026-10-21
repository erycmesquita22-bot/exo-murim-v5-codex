extends RefCounted
## Disk-backed catalog; identical manifests yield stable deterministic order.
const ROOT = "res://exo_city_forge/libraries/"
const GROUPS = {"blueprints":"city_blueprints", "districts":"districts", "profiles":"population_profiles", "landmarks":"landmarks"}
static func _read(path: String) -> Dictionary:
 if not FileAccess.file_exists(path):return {}
 var value: Variant=JSON.parse_string(FileAccess.get_file_as_string(path))
 return value if value is Dictionary else {}
static func catalog() -> Dictionary:
 var out: Dictionary={"blueprints":[],"districts":[],"profiles":[],"landmarks":[],"social_profiles":[]}
 for typ in GROUPS:
  var folder: String=ROOT+str(GROUPS[typ])+"/"
  var dir: DirAccess=DirAccess.open(folder)
  if dir==null:continue
  var names: PackedStringArray=dir.get_files()
  names.sort()
  for file in names:
   if not file.ends_with(".json"):continue
   var item: Dictionary=_read(folder+file)
   if item.is_empty():continue
   if typ=="profiles" and file.begins_with("social_"):out.social_profiles.append(item)
   else:out[typ].append(item)
 return out
static func status() -> Dictionary:
 var c: Dictionary=catalog()
 return {"status":"ready","blueprints":c.blueprints.size(),"districts":c.districts.size(),"profiles":c.profiles.size(),"landmarks":c.landmarks.size(),"social_profiles":c.social_profiles.size(),"settlement_scales":["village","town","city"],"host_r13_native_verified":false,"crowd_illusion_bridge":"opt_in_after_official_region_build","crowd_module_modified":false}
