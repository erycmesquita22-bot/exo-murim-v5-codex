extends RefCounted
static func run(core: RefCounted) -> Dictionary:
 var errors: Array=[]
 for id in core.registry.order:
  var module: Dictionary=core.registry.modules[id]
  if module.state!="ready" and not module.get("optional_module",false):errors.append("module_not_ready:"+str(id))
  if module.state=="ready":
   for service in module.services:
    if not core.services.has_service(str(service)):errors.append("service_unavailable:"+str(service))
 if not core.world.journey.valid(core.world.journey.data):errors.append("invalid_save")
 return {"status":"PASS" if errors.is_empty() else "FAIL","errors":errors,"order":core.registry.order,"services":core.services.entries.keys(),"schema":1}
