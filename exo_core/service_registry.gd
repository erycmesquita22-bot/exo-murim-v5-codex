extends RefCounted
var entries: Dictionary={}
func register_service(id: String,owner_id: String,provider: Object,methods: Array,version: String="1.0.0") -> bool:
 if entries.has(id) or not is_instance_valid(provider):return false
 for method in methods:
  if not provider.has_method(method):return false
 entries[id]={"owner":owner_id,"provider":weakref(provider),"methods":methods.duplicate(),"version":version}
 return true
func invoke(id: String,method: String,args: Array=[]) -> Variant:
 if not entries.has(id) or method not in entries[id].methods:return null
 var provider: Object=entries[id].provider.get_ref()
 if not is_instance_valid(provider):return null
 return provider.callv(method,args)
func has_service(id: String) -> bool:return entries.has(id) and entries[id].provider.get_ref()!=null
