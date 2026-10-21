extends RefCounted
const Validation = preload("res://exo_items/persistence/item_validation.gd")
static func export_preview(item: Dictionary) -> String:
 if not Validation.descriptor(item): return ""
 return JSON.stringify(item, "", true)
static func import_preview(raw: String) -> Dictionary:
 if raw.length() > 8192 or raw.is_empty(): return {}
 var data: Variant = JSON.parse_string(raw)
 if not data is Dictionary: return {}
 # Godot JSON numbers can round-trip as float: restore schema integer fields.
 for key in ["schema", "seed", "level", "quality", "tier", "rules_version"]:
  if data.has(key) and (data[key] is float or data[key] is int) and is_finite(float(data[key])) and int(data[key]) == data[key]:
   data[key] = int(data[key])
 if data.get("stats") is Dictionary:
  for key in ["guard", "agilidade", "inteligencia"]:
   if data.stats.has(key) and (data.stats[key] is float or data.stats[key] is int) and int(data.stats[key]) == data.stats[key]:
    data.stats[key] = float(int(data.stats[key]))
 if not Validation.descriptor(data): return {}
 return data
static func roundtrip(item: Dictionary) -> bool:
 var raw: String = export_preview(item)
 return not raw.is_empty() and JSON.stringify(import_preview(raw), "", true) == raw
static func fingerprint(item: Dictionary) -> String:
 var raw: String = export_preview(item)
 return "" if raw.is_empty() else raw.sha256_text()
