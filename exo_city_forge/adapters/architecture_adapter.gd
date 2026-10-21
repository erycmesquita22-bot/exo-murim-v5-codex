extends RefCounted
## Read-only manifest of accepted architectural functions; Forja retains materialization authority.
const OFFICIAL_FUNCTIONS=["residence","farmstead","market","inn","smithy","herbalist","administration","martial_school","shrine","warehouse"]
static func slots(city: Dictionary) -> Array:
 var result: Array=[]
 for b in city.get("buildings",[]):
  if str(b.get("function","")) not in OFFICIAL_FUNCTIONS:continue
  result.append({"id":str(b.id),"function":str(b.function),"interior_slot":bool(b.get("interior_slot",false)),"status":"planned_only","forja_build_called":false})
 return result
