extends RefCounted
const Ledger=preload("res://exo_core/persistence/receipt_ledger.gd")
static func fresh() -> Dictionary:return {"schema":2,"sequence":0,"receipts":Ledger.fresh(),"module_versions":{}}
static func valid(v: Variant) -> bool:
 if not v is Dictionary or (v.get("schema")!=1 and v.get("schema")!=2) or not v.get("module_versions") is Dictionary:return false
 if not (v.get("sequence") is int or v.get("sequence") is float) or int(v.sequence)!=v.sequence or v.sequence<0:return false
 if v.schema==2:return Ledger.valid(v.get("receipts",null))
 if not v.get("receipts") is Dictionary or v.receipts.size()>12000:return false
 for id in v.receipts:
  if not id is String or id.is_empty() or id.length()>160 or not v.receipts[id] is String or v.receipts[id].length()!=64:return false
 return true
static func upgrade(data: Dictionary) -> bool:
 if not data.has("exo_core"):
  data.exo_core=fresh();return true
 var v: Variant=data.exo_core
 # Hot publication path: full structural validation belongs to the save/load boundary.
 if v is Dictionary and v.get("schema")==2:return v.get("receipts") is Dictionary and v.receipts.get("schema")==1
 if not valid(v):return false
 var migrated: Dictionary=Ledger.fresh()
 for id in v.receipts:
  if not Ledger.put(migrated,id,str(v.receipts[id])):return false
 var candidate: Dictionary=v.duplicate(true);candidate.schema=2;candidate.receipts=migrated
 if not valid(candidate):return false
 data.exo_core=candidate
 return true
static func receipt(v: Dictionary,id: String) -> Dictionary:
 if v.get("schema")!=2:return {}
 return Ledger.lookup(v.receipts,id)
static func remember(v: Dictionary,id: String,hash: String) -> bool:
 if v.get("schema")!=2:return false
 return Ledger.put(v.receipts,id,hash)
