extends RefCounted
var modules: Dictionary={}
var order: Array[String]=[]
var errors: Array[String]=[]
func register(spec: Dictionary) -> bool:
 for key in ["id","version","requires","optional","services","publishes","consumes","persistence"]:
  if not spec.has(key):errors.append("missing_field:"+key);return false
 var id: String=str(spec.id)
 if id.is_empty() or modules.has(id):errors.append("duplicate_module:"+id);return false
 if str(spec.version).split(".").size()!=3:errors.append("invalid_version:"+id);return false
 modules[id]=spec.duplicate(true);modules[id]["state"]="registered"
 return true
static func compatible(actual: String,required: String) -> bool:
 var a: PackedStringArray=actual.split(".");var b: PackedStringArray=required.split(".")
 if a.size()!=3 or b.size()!=3:return false
 for x in a+b:
  if not x.is_valid_int():return false
 return int(a[0])==int(b[0]) and (int(a[1])>int(b[1]) or (int(a[1])==int(b[1]) and int(a[2])>=int(b[2])))
func resolve() -> bool:
 order.clear()
 if not errors.is_empty():return false
 var pending: Array=modules.keys();pending.sort()
 var providers: Dictionary={}
 for id in pending:
  for service in modules[id].services:
   if providers.has(service):errors.append("duplicate_service:"+str(service))
   providers[service]=id
  for dep in modules[id].requires:
   if not modules.has(dep):errors.append("missing_dependency:"+str(id)+":"+str(dep))
   elif not compatible(str(modules[dep].version),str(modules[id].requires[dep])):errors.append("incompatible_dependency:"+str(id)+":"+str(dep))
  for dep in modules[id].optional:
   if modules.has(dep) and not compatible(str(modules[dep].version),str(modules[id].optional[dep])):errors.append("incompatible_optional:"+str(id)+":"+str(dep))
 if not errors.is_empty():return false
 while not pending.is_empty():
  var progress:=false
  for id in pending.duplicate():
   var ready:=true
   for dep in modules[id].requires:
    if dep not in order:ready=false
   for dep in modules[id].optional:
    if modules.has(dep) and dep not in order:ready=false
   if ready:order.append(id);pending.erase(id);progress=true
  if not progress:errors.append("dependency_cycle:"+str(pending));return false
 return true
func initialize(callback: Callable) -> bool:
 if not resolve():return false
 for id in order:
  var failed:=false
  for dep in modules[id].requires:
   if modules[dep].state!="ready":failed=true
  if not failed:failed=not bool(callback.call(id))
  modules[id].state="failed" if failed else "ready"
  if failed and not bool(modules[id].get("optional_module",false)):errors.append("initialization_failed:"+id);return false
 return true
