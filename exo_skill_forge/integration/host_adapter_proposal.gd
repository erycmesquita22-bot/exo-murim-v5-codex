extends RefCounted
# CANDIDATE ONLY — code example, NEVER bind this as a trusted Combat executor.
# The C3 Work "combat" service only exposes enemy_defeated. No approved generic host exists yet.
# The future Core integrator must implement the two callbacks below inside the actual combat owner.
static func missing_permit(_actor_id: String, _plan: Dictionary) -> Dictionary:
	return {"ok": false, "reason": "c3_work_combat_owner_contract_not_implemented"}

static func missing_execute(_actor_id: String, _plan: Dictionary, _receipt: String) -> Dictionary:
	return {"ok": false, "committed": false, "status": "rejected", "schema_version": 2,
		"receipt": _receipt, "reason": "no_trusted_host"}
