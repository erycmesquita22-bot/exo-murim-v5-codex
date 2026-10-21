extends RefCounted
## EXO Core Work Candidate 01 optional module entrypoint (not loaded unless registered).
## Audited reference: Work Candidate 01 SHA-256 abe7b5736140d91153e0e6f9343ef443d9ca526f78b636361355b2d895cb69f9.
const Director = preload("res://exo_crowd_illusion/runtime/director.gd")
const RegionAdapter = preload("res://exo_crowd_illusion/runtime/region_adapter.gd")
var core: RefCounted
var crowd = Director.new()
var initialized := false
var last_region_event := -1

func initialize(core_host: RefCounted) -> bool:
	if initialized or core_host == null:
		return false
	if not core_host.services.has_method("register_service") or not core_host.events.has_method("subscribe"):
		return false
	if not core_host.services.register_service("crowd.illusion", "crowd_illusion", self,
		["attach_region", "status", "set_density", "set_hour", "set_mobile", "notify_event", "detach"], "1.0.4"):
		return false
	# Event contracts forbid crowd from being an event owner. Consume official events only.
	if not core_host.events.subscribe("region_entered", "crowd_illusion", Callable(self, "_region_entered")):
		return false
	if not core_host.events.subscribe("region_exited", "crowd_illusion", Callable(self, "_region_exited")):
		return false
	if not core_host.events.subscribe("entity_state_changed", "crowd_illusion", Callable(self, "_entity_changed")):
		return false
	core = core_host
	initialized = true
	return true

func attach_region(region: Node3D) -> Dictionary:
	if not initialized or not is_instance_valid(region):
		return {"ok": false, "reason": "core_not_initialized_or_region_missing"}
	var mapping: Dictionary = RegionAdapter.from_r13_region(region)
	if not bool(mapping.get("ok", false)):
		return mapping
	var data: Variant = region.get("data")
	if data == null or not data is RefCounted:
		return {"ok": false, "reason": "region_data_unavailable"}
	var raw_spec: Variant = data.get("spec")
	if not raw_spec is Dictionary:
		return {"ok": false, "reason": "region_spec_unavailable"}
	var spec: Dictionary = raw_spec
	var region_id := int(spec.get("id", -1))
	if core.world == null or not is_instance_valid(core.world):
		return {"ok": false, "reason": "world_unavailable"}
	var focus_node := core.world.get("player") as Node3D
	var save_seed := str(core.world.journey.data.get("world", {}).get("seed", ""))
	if save_seed.is_empty():
		return {"ok": false, "reason": "official_world_seed_unavailable"}
	var clock_value := float(core.clock())
	var time_hour := posmod(int(floor(clock_value / 90.0)), 24)
	var is_mobile := OS.has_feature("mobile") or OS.has_feature("android")
	var result: Dictionary = crowd.attach_region(region, region_id, mapping["zones"], save_seed, focus_node, is_mobile, time_hour, mapping.get("reserved", []), mapping.get("area_index", {}), mapping.get("context", {}))
	result["source"] = mapping.get("source", "unknown")
	result["urban_areas"] = mapping.get("area_index", {}) if str(mapping.get("source", "")) == "city_forge_authorized_geometry" else {}
	return result

func _region_entered(event: Dictionary) -> bool:
	last_region_event = int(event.get("region", -1))
	return true

func _region_exited(event: Dictionary) -> bool:
	# Exit event is staged BEFORE save commit. Host detaches only after success.
	pass
	return true

func _entity_changed(event: Dictionary) -> bool:
	# Combat's entity_state_changed context varies by owner. Never synthesize a position.
	var ctx: Dictionary = event.get("context", {})
	if str(ctx.get("state", "")) not in ["combat", "danger", "hostile"]:
		return true
	var at: Variant = ctx.get("position", null)
	if at is Array and at.size() == 3:
		crowd.notify_event("danger", Vector3(float(at[0]),float(at[1]),float(at[2])))
	return true

func status() -> Dictionary:
	var report: Dictionary = crowd.status()
	report["core_bound"] = initialized
	report["last_region_event"] = last_region_event
	return report

func set_density(amount: float) -> void:
	crowd.set_density(amount)

func set_hour(value: int) -> void:
	crowd.set_hour(value)

func set_mobile(enabled: bool) -> void:
	crowd.set_mobile(enabled)

func notify_event(kind: String, location: Vector3) -> bool:
	return crowd.notify_event(kind, location)

func detach() -> void:
	crowd.detach()

func shutdown() -> void:
	crowd.detach()
	initialized = false
	core = null
