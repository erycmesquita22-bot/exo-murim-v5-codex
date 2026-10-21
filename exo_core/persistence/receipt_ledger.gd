extends RefCounted
# EXO Core 01-P: shared, pure helper; no singleton, bus, disk writer, or sidecar.
# Sharded exact membership: do not use Bloom filters for reward authority.
const SCHEMA=1
static func fresh() -> Dictionary:
 return {"schema":SCHEMA,"shards":{},"count":0}
static func valid(v: Variant) -> bool:
 if not v is Dictionary or v.get("schema")!=SCHEMA or not v.get("shards") is Dictionary:return false
 if (not v.get("count") is int and not v.get("count") is float) or int(v.count)!=v.count or v.count<0:return false
 var n:=0
 for prefix in v.shards:
  if not prefix is String or prefix.length()!=2 or not prefix.is_valid_hex_number():return false
  var shard: Variant=v.shards[prefix]
  if not shard is Dictionary:return false
  for digest in shard:
   if not digest is String or digest.length()!=64 or not digest.is_valid_hex_number() or not digest.begins_with(prefix):return false
   var entry: Variant=shard[digest]
   if not entry is Dictionary or not entry.get("id") is String or entry.id.is_empty() or entry.id.length()>160:return false
   if entry.id.sha256_text()!=digest or not entry.get("fingerprint") is String or entry.fingerprint.length()!=64 or not entry.fingerprint.is_valid_hex_number():return false
   if entry.has("payload") and not entry.payload is Dictionary:return false
   n+=1
 return n==v.count
static func lookup(v: Dictionary,id: String) -> Dictionary:
 if id.is_empty() or id.length()>160:return {}
 var digest: String=id.sha256_text()
 var shard: Variant=v.get("shards",{}).get(digest.substr(0,2),{})
 if not shard is Dictionary:return {}
 var entry: Variant=shard.get(digest,{})
 if not entry is Dictionary or entry.get("id")!=id:return {}
 return entry
static func put(v: Dictionary,id: String,fingerprint: String,payload: Dictionary={}) -> bool:
 if id.is_empty() or id.length()>160 or fingerprint.length()!=64 or not fingerprint.is_valid_hex_number():return false
 var existing: Dictionary=lookup(v,id)
 if not existing.is_empty():return existing.fingerprint==fingerprint
 if v.get("schema")!=SCHEMA or not v.get("shards") is Dictionary or (not v.get("count") is int and not v.get("count") is float):return false
 var digest: String=id.sha256_text();var prefix: String=digest.substr(0,2)
 var shard: Dictionary=v.shards.get(prefix,{})
 # Treat an occupied SHA-256 slot with a different identity as a collision.
 if shard.has(digest):return false
 var record: Dictionary={"id":id,"fingerprint":fingerprint}
 if not payload.is_empty():record["payload"]=payload.duplicate(true)
 shard[digest]=record;v.shards[prefix]=shard;v.count=int(v.count)+1
 return true
