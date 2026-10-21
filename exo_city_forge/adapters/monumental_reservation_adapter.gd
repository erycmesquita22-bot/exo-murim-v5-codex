extends RefCounted
## Uses actual R13 bounds, no receipt fabrication or reservations created.
static func overlap(bounds: Dictionary,reservations: Array,padding: float=2.0) -> bool:
 for r in reservations:
  if float(bounds.max_x)>float(r.min_x)-padding and float(bounds.min_x)<float(r.max_x)+padding and float(bounds.max_z)>float(r.min_z)-padding and float(bounds.min_z)<float(r.max_z)+padding:return true
 return false
static func get_verified_receipt_context(core: RefCounted,region_id: int) -> Dictionary:
 if core==null or not core.services.has_service("monuments.plans"):return {"status":"unavailable"}
 var data: Variant=core.services.invoke("monuments.plans","regional_receipts",[region_id])
 return {"status":"read_only","receipts":data}
