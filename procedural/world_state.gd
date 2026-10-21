extends RefCounted
const Stream=preload("res://procedural/seed_stream.gd")
const Ledger=preload("res://exo_core/persistence/receipt_ledger.gd")
const GENERATION_VERSION=1
static func create(seed_value: int=-1,identity: String="") -> Dictionary:
 if seed_value<0:seed_value=Stream.hash_value(Crypto.new().generate_random_bytes(16).hex_encode())
 if identity.is_empty():identity="world_"+Crypto.new().generate_random_bytes(12).hex_encode()
 return {"schema":2,"seed":seed_value,"id":identity,"generation_version":GENERATION_VERSION,"events":{},"claim_receipts":Ledger.fresh()}
static func stream(w: Dictionary,domain: String,key: String) -> RefCounted:
 return Stream.new(Stream.hash_value("%d|%d|%s|%s"%[int(w.seed),int(w.generation_version),domain,key]))
static func migrate_legacy(save: Dictionary) -> void:
 if save.has("world"):return
 var signature: String=JSON.stringify(save,"",true).sha256_text()
 save.world=create(Stream.hash_value(signature),"world_legacy_"+signature.substr(0,24))
 for drop in save.get("pending_loot",[]):save.world.events["loot/"+str(drop.source)]={"status":"pending","legacy":true}
 for id in save.get("defeated",[]):
  var key: String="loot/"+str(id)
  if not save.world.events.has(key):mark_collected(save.world,key,{"legacy":true})
static func _claim_fingerprint(id: String) -> String:
 return ("EXO-WORLD-COLLECTED-01|"+id).sha256_text()
static func upgrade(w: Dictionary) -> bool:
 if w.get("schema")==2:return w.get("claim_receipts") is Dictionary and w.get("events") is Dictionary
 if w.get("schema")!=1 or not valid(w):return false
 var candidate: Dictionary=w.duplicate(true)
 var ledger: Dictionary=Ledger.fresh()
 for id in candidate.events.keys():
  var event: Dictionary=candidate.events[id]
  if event.status=="collected":
   if not Ledger.put(ledger,id,_claim_fingerprint(id),event):return false
   candidate.events.erase(id)
 candidate.schema=2;candidate.claim_receipts=ledger
 if not valid(candidate):return false
 w.clear();w.merge(candidate,true)
 return true
static func has_event(w: Dictionary,id: String) -> bool:
 if w.get("events",{}).has(id):return true
 if w.get("schema")!=2:return false
 return not Ledger.lookup(w.claim_receipts,id).is_empty()
static func mark_pending(w: Dictionary,id: String,entry: Dictionary) -> bool:
 if id.is_empty() or id.length()>128 or not upgrade(w) or has_event(w,id):return false
 if w.events.size()>=4096:return false
 var item: Dictionary=entry.duplicate(true);item.status="pending"
 w.events[id]=item
 return true
static func mark_collected(w: Dictionary,id: String,details: Dictionary={}) -> bool:
 if id.is_empty() or id.length()>128 or not upgrade(w):return false
 if not Ledger.lookup(w.claim_receipts,id).is_empty():return false
 var record: Dictionary=w.events.get(id,details).duplicate(true)
 record.status="collected"
 if not Ledger.put(w.claim_receipts,id,_claim_fingerprint(id),record):return false
 w.events.erase(id)
 return true
static func valid(w: Variant) -> bool:
 if not w is Dictionary or (w.get("schema")!=1 and w.get("schema")!=2) or w.get("generation_version")!=GENERATION_VERSION:return false
 if not w.get("id") is String or not w.id.begins_with("world_") or w.id.length()>96:return false
 var seed_value: Variant=w.get("seed")
 if (not seed_value is int and not seed_value is float) or not is_finite(float(seed_value)) or int(seed_value)!=seed_value or seed_value<0 or seed_value>=2147483647:return false
 if not w.get("events") is Dictionary:return false
 if w.events.size()>(2048 if w.schema==1 else 4096):return false
 for id in w.events:
  if not id is String or id.length()>128 or not w.events[id] is Dictionary:return false
  if w.events[id].get("status") not in (["pending","collected"] if w.schema==1 else ["pending"]):return false
 if w.schema==2:return Ledger.valid(w.get("claim_receipts",null))
 return true
