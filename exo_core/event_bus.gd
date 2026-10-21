extends RefCounted
const Contracts=preload("res://exo_core/contracts/event_contracts.gd")
const Migrations=preload("res://exo_core/persistence/migration_registry.gd")
var save: RefCounted
var handlers: Dictionary={}
var queue: Array=[]
var dispatching:=false
var last_error:=""
var trace: Array=[]
var deferred_events: Array=[]
func _init(authority: RefCounted) -> void:save=authority
func subscribe(type: String,consumer: String,callback: Callable) -> bool:
 if not Contracts.OWNERS.has(type) or not callback.is_valid():return false
 if not handlers.has(type):handlers[type]=[]
 for row in handlers[type]:
  if row.consumer==consumer:return false
 handlers[type].append({"consumer":consumer,"callback":callback})
 return true
func publish(event: Dictionary,persistent: bool=true) -> Dictionary:
 if not Contracts.valid(event):return {"ok":false,"reason":"invalid_contract"}
 if not Migrations.upgrade(save.data):return {"ok":false,"reason":"invalid_core_state"}
 var fingerprint: String=JSON.stringify(event).sha256_text()
 var prior: Dictionary=Migrations.receipt(save.data.exo_core,str(event.id))
 if persistent and not prior.is_empty():return {"ok":prior.fingerprint==fingerprint,"duplicate":true,"reason":"duplicate" if prior.fingerprint==fingerprint else "id_collision"}
 if dispatching:
  # Reentrant consumers must use a distinct event. A 128-event ceiling terminates cycles.
  for pending in queue:
   if pending.event.id==event.id:return {"ok":false,"reason":"event_cycle"}
  queue.append({"event":event.duplicate(true),"persistent":persistent});return {"ok":true,"queued":true}
 var before: Dictionary=save.data.duplicate(true)
 var trace_before: int=trace.size()
 queue.append({"event":event.duplicate(true),"persistent":persistent})
 dispatching=true
 var processed:=0
 while not queue.is_empty():
  var item: Dictionary=queue.pop_front();var e: Dictionary=item.event
  var archived: Dictionary=Migrations.receipt(save.data.exo_core,str(e.id))
  if item.persistent and not archived.is_empty():
   if archived.fingerprint!=JSON.stringify(e).sha256_text():last_error="id_collision";break
   continue
  processed+=1
  if processed>128:last_error="event_cycle";break
  var accepted:=true
  for h in handlers.get(e.type,[]):
   var result: Variant=h.callback.call(e.duplicate(true))
   if result is bool and not result:accepted=false;break
   if result is Dictionary and not bool(result.get("ok",false)):accepted=false;break
  if not accepted:last_error="consumer_rejected:"+str(e.type);break
  if item.persistent:
   if not Migrations.remember(save.data.exo_core,str(e.id),JSON.stringify(e).sha256_text()):last_error="receipt_collision";break
   save.data.exo_core.sequence=int(save.data.exo_core.sequence)+1
  trace.append(e.duplicate(true))
  if trace.size()>256:trace.pop_front()
 var ok: bool=queue.is_empty() and last_error.is_empty()
 queue.clear();dispatching=false
 if not ok:
  save.data=before
  trace.resize(mini(trace_before,trace.size()))
 var reason: String=last_error;last_error=""
 return {"ok":ok,"reason":reason,"processed":processed}
