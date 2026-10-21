extends RefCounted
# Stable local deterministic selection. No global RNG state; ID and seed must be canonical.
static func choose(seed_text: String, uid: String, purpose: String, count: int) -> int:
	if count <= 0 or uid.is_empty():
		return -1
	var signature: String = ("EXO|NPC03|1|" + seed_text + "|" + uid + "|" + purpose).sha256_text()
	return int(signature.substr(0, 7).hex_to_int()) % count

static func signed_offset(seed_text: String, uid: String, purpose: String, magnitude: int) -> int:
	if magnitude < 0:
		return 0
	return choose(seed_text, uid, purpose, 2 * magnitude + 1) - magnitude
