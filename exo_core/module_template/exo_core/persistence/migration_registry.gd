extends RefCounted
static func fresh() -> Dictionary:return {"schema":1,"sequence":0,"receipts":{},"module_versions":{}}
static func valid(v: Variant) -> bool:
 if not v is Dictionary or v.get("schema")!=1 or not v.get("receipts") is Dictionary or not v.get("module_versions") is Dictionary:return false
 if not (v.get("sequence") is int or v.get("sequence") is float) or int(v.sequence)!=v.sequence or v.sequence<0:return false
 if v.receipts.size()>12000:return false
 for id in v.receipts:
  if not id is String or id.length()>160 or not v.receipts[id] is String or v.receipts[id].length()!=64:return false
 return true
static func upgrade(data: Dictionary) -> bool:
 if data.has("exo_core"):return valid(data.exo_core)
 data.exo_core=fresh()
 return true
