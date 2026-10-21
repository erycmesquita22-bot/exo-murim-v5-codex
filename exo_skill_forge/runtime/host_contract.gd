extends RefCounted
# R3 in-process, non-network, untrusted-plan contract. Core/Combat remains the sole authority.
const HOST_ID := "exo_core_combat_owner_v1"
const SCHEMA_VERSION := 2
const MAX_RECEIPT_LENGTH := 160

static func fingerprint(plan: Dictionary) -> String:
	# A fingerprint binds the permit to THIS immutable candidate snapshot; it is not a signature.
	return JSON.stringify(plan).sha256_text()

static func actor_kind(actor_id: String) -> String:
	if actor_id == "player": return "player"
	if actor_id.begins_with("enemy/") and actor_id.length() > 6: return "enemy"
	if actor_id.begins_with("npc/") and actor_id.length() > 4: return "npc"
	return ""

static func valid_permit(reply: Variant, digest: String) -> bool:
	if not reply is Dictionary: return false
	if not bool(reply.get("ok", false)): return false
	if str(reply.get("owner", "")) != "combat": return false
	if int(reply.get("schema_version", 0)) != SCHEMA_VERSION: return false
	if str(reply.get("plan_sha256", "")) != digest: return false
	var receipt: String = str(reply.get("receipt", ""))
	return not receipt.is_empty() and receipt.length() <= MAX_RECEIPT_LENGTH

static func valid_commit(reply: Variant, receipt: String) -> bool:
	if not reply is Dictionary: return false
	if str(reply.get("receipt", "")) != receipt or int(reply.get("schema_version", 0)) != SCHEMA_VERSION: return false
	var status: String = str(reply.get("status", ""))
	if status == "committed": return bool(reply.get("ok", false)) and bool(reply.get("committed", false))
	if status == "duplicate": return bool(reply.get("ok", false)) and not bool(reply.get("committed", true))
	if status == "rejected": return not bool(reply.get("ok", true)) and not bool(reply.get("committed", true))
	return false
