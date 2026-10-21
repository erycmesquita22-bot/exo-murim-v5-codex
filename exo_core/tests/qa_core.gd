extends SceneTree
const Registry=preload("res://exo_core/module_registry.gd")
const Services=preload("res://exo_core/service_registry.gd")
const Bus=preload("res://exo_core/event_bus.gd")
const Save=preload("res://journey_save.gd")
var checks:=0
var failures: Array=[]
var counter:=0
func check(ok: bool,label: String) -> void:
 checks+=1
 if not ok:failures.append(label)
func spec(id: String,deps: Dictionary={}) -> Dictionary:return {"id":id,"version":"1.0.0","requires":deps,"optional":{},"services":[],"publishes":[],"consumes":[],"persistence":{}}
func handle(_e: Dictionary) -> bool:counter+=1;return true
func reject(_e: Dictionary) -> bool:return false
func _initialize() -> void:
 var r=Registry.new();r.register(spec("b",{"a":"1.0.0"}));r.register(spec("a"));check(r.resolve() and r.order==["a","b"],"topological_order")
 check(not r.register(spec("a")),"duplicate_module")
 r=Registry.new();r.register(spec("a",{"missing":"1.0.0"}));check(not r.resolve(),"missing_dependency")
 r=Registry.new();r.register(spec("a",{"b":"2.0.0"}));r.register(spec("b"));check(not r.resolve(),"version_conflict")
 r=Registry.new();r.register(spec("a",{"b":"1.0.0"}));r.register(spec("b",{"a":"1.0.0"}));check(not r.resolve(),"cycle")
 r=Registry.new();var a: Dictionary=spec("a");a.optional_module=true;r.register(a);r.register(spec("b"));check(r.initialize(func(id):return id!="a") and r.modules.a.state=="failed" and r.modules.b.state=="ready","optional_failure")
 var save=Save.new("user://core_unit.json",101);var bus=Bus.new(save)
 check(bus.subscribe("region_entered","test",handle),"subscribe");check(not bus.subscribe("region_entered","test",handle),"duplicate_subscription")
 var event: Dictionary={"id":"arrival/1","type":"region_entered","source":"world","schema":1,"region":1,"context":{}}
 check(bus.publish(event).ok and counter==1,"delivery");check(bus.publish(event).ok and counter==1,"dedupe")
 event.region=2;check(not bus.publish(event).ok,"id_collision")
 event.id="invalid";event.schema=2;check(not bus.publish(event).ok,"schema_refusal")
 event.schema=1;event.source="combat";check(not bus.publish(event).ok,"publisher_refusal")
 event.source="world";event.id="rollback";bus.subscribe("region_entered","reject",reject)
 var before: Dictionary=save.data.duplicate(true);check(not bus.publish(event).ok and save.data==before,"consumer_rollback")
 var service=Services.new();check(service.register_service("save","persistence",save,["write"]),"registered_interface");check(not service.register_service("save","other",save,["write"]),"service_conflict");check(service.invoke("save","load_progress")==null,"private_method_refused")
 check(save.write(),"atomic_save")
 var reopen=Save.new(save.path);check(reopen.load_progress(),"reload")
 var bus2=Bus.new(reopen);bus2.subscribe("region_entered","test",handle);event.id="arrival/1";event.region=1
 var old: int=counter;check(bus2.publish(event).ok and counter==old,"durable_event_dedupe")
 print("EXO_CORE_QA ",JSON.stringify({"checks":checks,"failures":failures}));quit(int(not failures.is_empty()))
