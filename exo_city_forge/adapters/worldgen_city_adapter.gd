extends RefCounted
## Reads verified C3 WORK candidate-01 RegionData fields; no edits to WorldGenesis-owned terrain, atlas or reservations.
static func request_from_region(data: RefCounted,profile_id: String="rich_commercial_city") -> Dictionary:
 var gates: Array=[]
 for gate in data.gates:gates.append([float(gate.p.x),float(gate.p.y)])
 var rivers: Array=[]
 for river in data.rivers:rivers.append({"p":[float(river.p.x),float(river.p.y)],"height":float(river.height)})
 var reservations: Array=[]
 var receipts: Array=data.monumental_receipts
 var approved_count: int=0
 for receipt in receipts:
  if not receipt is Dictionary:continue
  if not bool(receipt.get("approved",false)):continue
  approved_count+=1
  var b: Variant=receipt.get("bounds",null)
  if not b is Dictionary or not b.has("min_x") or not b.has("max_x") or not b.has("min_z") or not b.has("max_z"):
   return {"blocked_r7_contract":true,"reason":"r7_receipt_without_verified_bounds"}
  if float(b.min_x)>=float(b.max_x) or float(b.min_z)>=float(b.max_z):
   return {"blocked_r7_contract":true,"reason":"r7_invalid_bounds"}
  reservations.append({"min_x":float(b.min_x),"max_x":float(b.max_x),"min_z":float(b.min_z),"max_z":float(b.max_z)})
 if data.monumental_plans.size()!=approved_count:
  return {"blocked_r7_contract":true,"reason":"r7_plan_receipt_count_mismatch"}
 return {"region_id":int(data.spec.id),"region_seed":str(data.spec.region_seed),"kind":str(data.spec.kind),"settlement_scale":str(data.spec.get("settlement_scale","")),"half_extent":float(data.half),"gates":gates,"rivers":rivers,"river_hub":[float(data.river_hub.x),float(data.river_hub.y)],"monument_reservations":reservations,"profile_id":profile_id,"mode":"authored_modular"}
