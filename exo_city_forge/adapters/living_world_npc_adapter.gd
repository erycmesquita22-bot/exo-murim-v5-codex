extends RefCounted
## R13 convergence/region.gd constructs assigned_slots after Forja builds actual lots.
## This adapter only describes candidate R13-compatible jobs; does NOT call record_roster().
const JOBS={"farmstead":"farmer","market":"merchant","inn":"merchant","smithy":"resident","herbalist":"healer","administration":"guild_agent","martial_school":"disciple","shrine":"master","warehouse":"courier"}
static func potential_slots(accepted_host_plan: Dictionary) -> Array:
 var slots: Array=[]
 for lot in accepted_host_plan.get("lots",[]):
  var id: String=str(lot.get("id",""))
  if id.is_empty():continue
  var role: String=str(JOBS.get(str(lot.get("function","residence")),"resident"))
  slots.append({"id":id,"role":role,"home_slot":id,"work_slot":id,"authority":"convergence/region.build_lots","npc_created":false})
 return slots
