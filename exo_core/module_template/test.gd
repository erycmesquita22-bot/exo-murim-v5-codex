extends Node
# A contract harness only: no NPCs/world/combat and no claims of gameplay validation.
const Registry=preload("res://exo_core/module_registry.gd")
const Services=preload("res://exo_core/service_registry.gd")
const Bus=preload("res://exo_core/event_bus.gd")
class Store extends RefCounted:
 var data: Dictionary={}
 var save_coordinator: RefCounted
class Domains extends RefCounted:
 var owners: Dictionary={}
 func register_domain(key: String,id: String,validator: Callable) -> bool:
  if owners.has(key):return false
  owners[key]={"owner":id,"validator":validator};return true
class World extends RefCounted:
 var journey: RefCounted
class Context extends RefCounted:
 var world: RefCounted
 var services=Services.new()
 var events: RefCounted
func _ready() -> void:
 var context=Context.new();context.world=World.new();context.world.journey=Store.new();context.world.journey.save_coordinator=Domains.new();context.events=Bus.new(context.world.journey)
 var module=preload("res://example/module.gd").new()
 assert(module.initialize(context))
 var event: Dictionary={"id":"test/equipment/1","type":"equipment_changed","source":"inventory","schema":1,"region":-1,"context":{}}
 assert(context.events.publish(event).ok);assert(context.events.publish(event).ok)
 assert(context.services.invoke("example.counter","count")==1)
 assert(module.valid(context.world.journey.data.example))
 module.shutdown();context.events.handlers.clear()
 print("MODULE_TEMPLATE PASS — idempotent event + public service + owned schema")
 get_tree().quit()
