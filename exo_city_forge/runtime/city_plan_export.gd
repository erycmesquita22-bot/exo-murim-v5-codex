extends RefCounted
static func export_plan(plan: Dictionary) -> Dictionary:
 if str(plan.get("status",""))!="ready":return {"status":"invalid","errors":plan.get("errors",["plan_not_ready"])}
 return plan.duplicate(true)
