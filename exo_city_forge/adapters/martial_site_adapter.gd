extends RefCounted
## Physical opportunity only, not a registered martial school/teacher.
static func pending_sites(city: Dictionary) -> Array:
 var sites: Array=[]
 for building in city.get("buildings",[]):
  if str(building.get("function",""))=="martial_school":sites.append({"building_id":str(building.id),"school_id":"","owner":"exo_martial/r9","status":"unbound_physical_candidate"})
 return sites
