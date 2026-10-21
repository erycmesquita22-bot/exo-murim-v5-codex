extends RefCounted
# EXO Skill Forge 01 R3. Pure catalog and routing, never a parallel combat or save owner.
const SkillCatalog = preload("res://exo_skill_forge/runtime/catalog.gd")
const Planner = preload("res://exo_skill_forge/runtime/planner.gd")
const LegacyBridge = preload("res://exo_skill_forge/integration/legacy_bridge.gd")
const Compatibility = preload("res://exo_skill_forge/integration/compatibility.gd")
const HostContract = preload("res://exo_skill_forge/runtime/host_contract.gd")
const SERVICE_VERSION := "1.2.0"
var core: RefCounted
var catalog: RefCounted
var trusted_permit: Callable = Callable()
var trusted_execute: Callable = Callable()
var authorized_host_name: String = ""
var in_flight: Dictionary = {}
var authorial_host_enabled: bool = false

func initialize(context: RefCounted) -> bool:
	if context == null or context.services == null: return false
	core = context
	catalog = SkillCatalog.new()
	if not catalog.initialize():
		core = null
		return false
	return core.services.register_service("skill_forge", "exo_skill_forge", self,
		["summary", "skill", "query", "preview", "plan", "legacy_cast", "authorized_cast", "compatibility_status"], SERVICE_VERSION)

func shutdown() -> void:
	trusted_permit = Callable()
	trusted_execute = Callable()
	authorized_host_name = ""
	in_flight.clear()
	authorial_host_enabled = false
	core = null
	catalog = null

func summary() -> Dictionary:
	return catalog.summary() if catalog != null else {"ok": false}
func skill(id: String) -> Dictionary:
	return catalog.get_skill(id) if catalog != null else {}
func query(filters: Dictionary = {}) -> Array:
	return catalog.query(filters) if catalog != null else []
func preview(id: String) -> Dictionary:
	var s: Dictionary = skill(id)
	if s.is_empty(): return {"ok": false, "reason": "unknown_skill"}
	return {"ok": true, "id": id, "name": s["name"], "loc_key": "exo.skill." + id,
		"source": s["source"], "state": s["state"], "requirements": s["tags"].duplicate(true),
		"balance": s["balance"].duplicate(true), "media": s["presentation"].duplicate(true)}
func plan(id: String, actor: Dictionary = {}) -> Dictionary:
	return Planner.compose(skill(id), actor)

# DO NOT CHARGE Qi/stamina here. Casts through existing techniques.gd by actual runtime loadout slot.
func legacy_cast(id: String) -> Dictionary:
	var s: Dictionary = skill(id)
	if s.is_empty() or str(s.get("executor", "")) != "legacy": return {"ok": false, "reason": "not_legacy"}
	if core == null or not is_instance_valid(core.world): return {"ok": false, "reason": "host_unavailable"}
	return LegacyBridge.cast(core.world, id)

# ONLY the trusted in-process integrator may call; this is not exposed via Core service registry.
# This binding does not prove trust by itself. Real Core integrator must own the instance.
func bind_trusted_host(host_id: String, permit: Callable, execute: Callable) -> bool:
	if core == null or host_id != HostContract.HOST_ID or not core.services.has_service("combat"): return false
	if not core.services.entries.has("combat") or str(core.services.entries["combat"].get("owner", "")) != "combat": return false
	if trusted_permit.is_valid() or trusted_execute.is_valid(): return false
	if not permit.is_valid() or not execute.is_valid(): return false
	authorized_host_name = host_id
	trusted_permit = permit
	trusted_execute = execute
	authorial_host_enabled = true
	return true

# Caller-supplied actor ID is only a request, never actor ownership proof.
# Owner must revalidate every property from its own state, including weapon, faction, target, and exact skill ID.
func authorized_cast(actor_id: String, id: String) -> Dictionary:
	if core == null or not authorial_host_enabled or authorized_host_name != HostContract.HOST_ID or not trusted_permit.is_valid() or not trusted_execute.is_valid():
		return {"ok": false, "reason": "host_adapter_not_bound"}
	if actor_id.length() > 128 or HostContract.actor_kind(actor_id).is_empty():
		return {"ok": false, "reason": "actor_invalid"}
	var s: Dictionary = skill(id)
	if s.is_empty(): return {"ok": false, "reason": "unknown_skill"}
	if str(s.get("executor", "")) != "generic" or str(s.get("state", "")) != "candidate_not_unlocked":
		return {"ok": false, "reason": "not_authorial_candidate"}
	var pending_key: String = actor_id + "|" + id
	if in_flight.has(pending_key): return {"ok": false, "reason": "cast_in_flight"}
	var candidate: Dictionary = Planner.compose(s, {"type": HostContract.actor_kind(actor_id)})
	if not bool(candidate.get("ok", false)): return candidate
	var digest: String = HostContract.fingerprint(candidate)
	in_flight[pending_key] = true
	# Permit and execute are synchronous by contract. No UI/network/await calls permitted.
	var permit_reply: Variant = trusted_permit.call(actor_id, candidate.duplicate(true))
	if not HostContract.valid_permit(permit_reply, digest):
		in_flight.erase(pending_key)
		return {"ok": false, "reason": "host_permit_denied_or_invalid"}
	var receipt: String = str(permit_reply["receipt"])
	var applied: Variant = trusted_execute.call(actor_id, candidate.duplicate(true), receipt)
	in_flight.erase(pending_key)
	if not HostContract.valid_commit(applied, receipt):
		return {"ok": false, "reason": "host_commit_unverified"}
	# Never imply success unless the authorized host explicitly returned committed/duplicate.
	return applied.duplicate(true)

func compatibility_status() -> Dictionary:
	var status: Dictionary = Compatibility.probe(core)
	status["catalog_ok"] = catalog != null and catalog.loaded
	status["service_version"] = SERVICE_VERSION
	status["host_contract_schema"] = HostContract.SCHEMA_VERSION
	status["generic_host_bound"] = authorial_host_enabled and trusted_permit.is_valid() and trusted_execute.is_valid()
	status["catalogue_only_for_new"] = not status["generic_host_bound"]
	status["media_bindings_verified"] = false
	return status
