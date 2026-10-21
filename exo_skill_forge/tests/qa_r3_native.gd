extends SceneTree
# NATIVE GODOT 4.6.2 QA: run with the module copied into a disposable project mirror.
# The test mocks Core/Combat explicitly: it is NOT a live physics/gameplay endorsement.
const Module = preload("res://exo_skill_forge/module.gd")
const HostContract = preload("res://exo_skill_forge/runtime/host_contract.gd")
class MockServices extends RefCounted:
	var entries: Dictionary = {"combat": {"owner": "combat"}}
	var provider: RefCounted
	func _init() -> void: provider = RefCounted.new()
	func has_service(id: String) -> bool: return id == "combat" or id == "skill_forge"
	func register_service(id: String, owner: String, object: Object, methods: Array, version: String = "1.0.0") -> bool:
		if id != "skill_forge" or owner != "exo_skill_forge" or version != "1.2.0": return false
		for m in methods:
			if not object.has_method(m): return false
		entries[id] = {"owner": owner, "provider": weakref(object), "methods": methods, "version": version}
		return true
class MockCore extends RefCounted:
	var services: RefCounted = MockServices.new()
	var world: Node3D = Node3D.new()
class MockCombat extends RefCounted:
	var receipts: Dictionary = {}
	var charges: int = 0
	var denied: bool = false
	func permit(_actor_id: String, plan: Dictionary) -> Dictionary:
		if denied: return {"ok": false}
		return {"ok": true, "owner": "combat", "schema_version": 2, "receipt": "fixture/replayed-1",
			"plan_sha256": HostContract.fingerprint(plan)}
	func execute(_actor_id: String, _plan: Dictionary, receipt: String) -> Dictionary:
		if receipts.has(receipt):
			return {"ok": true, "committed": false, "status": "duplicate", "schema_version": 2, "receipt": receipt}
		receipts[receipt] = true
		charges += 1
		return {"ok": true, "committed": true, "status": "committed", "schema_version": 2, "receipt": receipt}
var pass_count: int = 0
var fail_count: int = 0
func check(condition: bool, name: String) -> void:
	if condition: pass_count += 1
	else:
		fail_count += 1
		printerr("FAIL:R3_NATIVE:", name)
func _initialize() -> void:
	var mod: RefCounted = Module.new()
	var core: RefCounted = MockCore.new()
	check(mod.initialize(core), "core bootstrap")
	if not mod.catalog.loaded:
		printerr(mod.catalog.issues)
		quit(1)
		return
	check(mod.summary().total == 184, "catalog 184")
	check(mod.summary().legacy == 16, "16 legacy IDs")
	check(mod.compatibility_status().service_version == "1.2.0", "service version")
	check(not mod.authorized_cast("player", "exo.sf.fio_do_bambu").ok, "unbound fail-closed")
	check(not mod.bind_trusted_host("untrusted", Callable(), Callable()), "wrong host denied")
	var host: RefCounted = MockCombat.new()
	check(mod.bind_trusted_host("exo_core_combat_owner_v1", Callable(host, "permit"), Callable(host, "execute")), "trusted mock bound")
	check(not mod.bind_trusted_host("exo_core_combat_owner_v1", Callable(host, "permit"), Callable(host, "execute")), "rebind denied")
	var once: Dictionary = mod.authorized_cast("player", "exo.sf.fio_do_bambu")
	check(once.get("status", "") == "committed", "first mock commit")
	var twice: Dictionary = mod.authorized_cast("player", "exo.sf.fio_do_bambu")
	check(twice.get("status", "") == "duplicate" and host.charges == 1, "receipt replays once")
	check(not mod.authorized_cast("ghost/1", "exo.sf.fio_do_bambu").get("ok", true), "ghost actor refused")
	check(not mod.authorized_cast("player", "corte_inicial").get("ok", true), "legacy not generic")
	host.denied = true
	check(not mod.authorized_cast("npc/1", "exo.sf.fio_do_bambu").get("ok", true), "host denial")
	mod.shutdown()
	check(not mod.authorized_cast("player", "exo.sf.fio_do_bambu").get("ok", true), "shutdown closes")
	print("EXO SKILL FORGE R3 NATIVE MOCK PASS=", pass_count, " FAIL=", fail_count)
	quit(1 if fail_count > 0 else 0)
