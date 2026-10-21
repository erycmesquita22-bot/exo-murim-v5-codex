extends RefCounted
# Release overlay R4. Does NOT change legacy R3 selection digest or persist anything.
const Library = preload("res://exo_world_library/core/entrypoint.gd")
const RELEASE: String = "0.4.0-bridge-candidate"
const EXCLUSIVE: Array = [
    ["flood_active", "drought_active"], ["public_festival", "curfew_active"],
    ["peace_only", "siege_active"], ["open_market", "trade_embargo"],
    ["waterway_blocked", "ferry_operational"],
    ["faction_allied", "faction_at_war"], ["npc_living", "npc_deceased"],
    ["electoral_voting", "imperial_appointment"], ["interior_public", "interior_sealed"]
]
var library: Variant = null
var error: String = ""

func initialize() -> bool:
    library = Library.new()
    if not library.load_catalogs():
        error = "catalog_load_failed"
        return false
    error = ""
    return true

static func normalize_region_id(value: Variant) -> Dictionary:
    if value is int:
        return {"ok":value >= 0 and value <= 87,"region_id":value}
    if value is String:
        var t: String = value.strip_edges()
        if not t.is_valid_int() or str(t.to_int()) != t:
            return {"ok":false,"reason":"invalid_region_id_format"}
        var n: int = t.to_int()
        return {"ok":n >= 0 and n <= 87,"region_id":n}
    return {"ok":false,"reason":"invalid_region_id_type"}

static func _context_reason(ctx: Dictionary) -> String:
    var check: Dictionary = Library.validate_context(ctx)
    if not bool(check.get("ok",false)):
        return str(check.get("reason","invalid_context"))
    for field in ["world_id", "seed", "region_id"]:
        if not ctx.has(field):
            return "missing_" + field
    for field in ["tags", "flags", "excluded_record_ids", "previous_record_ids"]:
        if ctx.has(field) and not (ctx[field] is Array):
            return "invalid_" + field
    for field in ["faction_id", "place_id", "instance_key"]:
        if ctx.has(field) and (not ctx[field] is String or str(ctx[field]).strip_edges().is_empty()):
            return "invalid_" + field
    if ctx.has("verified_facts") and not (ctx["verified_facts"] is Array):
        return "invalid_verified_facts"
    if ctx.has("world_day") and (not ctx["world_day"] is int or int(ctx["world_day"]) < 0):
        return "invalid_world_day"
    return ""

static func _exclusive_reason(tags: Array) -> String:
    for family in EXCLUSIVE:
        var found: int = 0
        for tag in family:
            if tag in tags:
                found += 1
        if found > 1:
            return "exclusive_tags:" + str(family[0]) + ":" + str(family[1])
    return ""

func reason_for(record: Dictionary, ctx: Dictionary, selected_tags: Array = []) -> String:
    if str(record.get("origin","")) != "authorial" or str(record.get("status","")) != "candidate" or float(record.get("weight",0.0)) <= 0.0:
        return "non_selectable_reference"
    if str(record.get("id","")) in ctx.get("excluded_record_ids",[]):
        return "excluded_record_id"
    if str(record.get("id","")) in ctx.get("previous_record_ids",[]):
        return "previous_record_id"
    if not Library._matches(record,ctx):
        return "record_conditions_or_flags"
    var tags: Array = ctx.get("tags",[]).duplicate()
    for t in selected_tags:
        if t not in tags:
            tags.append(t)
    for t in record.get("tags",[]):
        if t not in tags:
            tags.append(t)
    var exclusive: String = _exclusive_reason(tags)
    if not exclusive.is_empty():
        return exclusive
    var standard: String = library.coherence_reason(record,ctx,selected_tags)
    if not standard.is_empty():
        return standard
    var vars: Dictionary = record.get("variables",{})
    if vars.has("allowed_settlement_types") and ctx.get("settlement_type","") not in vars["allowed_settlement_types"]:
        return "settlement_type_forbidden"
    if vars.has("allowed_biomes") and ctx.get("biome","") not in vars["allowed_biomes"]:
        return "biome_forbidden"
    if vars.has("min_power") and int(ctx.get("player_tier",-1)) < int(vars["min_power"]):
        return "power_too_low"
    if vars.has("max_power") and int(ctx.get("player_tier",-1)) > int(vars["max_power"]):
        return "power_too_high"
    if vars.has("faction_required") and str(ctx.get("faction_id","")) != str(vars["faction_required"]):
        return "wrong_faction"
    if vars.has("required_host_facts"):
        for fact in vars["required_host_facts"]:
            if fact not in ctx.get("verified_facts",[]):
                return "missing_authoritative_fact"
    if vars.has("excluded_host_facts"):
        for fact in vars["excluded_host_facts"]:
            if fact in ctx.get("verified_facts",[]):
                return "forbidden_authoritative_fact"
    if str(record.get("domain","")) == "parallel_arc":
        var parent: String = str(vars.get("parent_story_id",""))
        if parent.is_empty() or parent != str(ctx.get("parent_story_id","")):
            return "parallel_arc_parent_not_verified"
    return ""

func propose(domain: String, ctx: Dictionary, slot: String = "0", prior_tags: Array = []) -> Dictionary:
    var blocked: Dictionary = {"status":"BLOCKED","committed":false,"authority":"none","proposals":[],"version":RELEASE}
    if library == null or not library.is_loaded:
        blocked["reason"] = "not_initialized"
        return blocked
    var context_reason: String = _context_reason(ctx)
    if not context_reason.is_empty():
        blocked["reason"] = context_reason
        return blocked
    if not library.catalogs.has(domain):
        blocked["reason"] = "unknown_domain"
        return blocked
    if slot.is_empty() or slot.length() > 96:
        blocked["reason"] = "invalid_slot"
        return blocked
    var eligible: Array = []
    var counts: Dictionary = {}
    for record in library.catalogs[domain]:
        var why: String = reason_for(record,ctx,prior_tags)
        if not why.is_empty():
            counts[why] = int(counts.get(why,0)) + 1
        else:
            eligible.append(record)
    blocked["rejection_counts"] = counts.duplicate(true)
    if eligible.is_empty():
        blocked["reason"] = "no_eligible_records"
        return blocked
    eligible.sort_custom(func(a: Dictionary,b: Dictionary) -> bool: return str(a["id"]) < str(b["id"]))
    var fingerprint: String = ("EXO-WORLD-LIBRARY-R4|" + str(ctx["world_id"]) + "|" + str(ctx["seed"]) + "|" + str(ctx["region_id"]) + "|" + str(ctx.get("instance_key","")) + "|" + domain + "|" + slot + "|" + Library._canonical(ctx)).sha256_text()
    var rng: RandomNumberGenerator = RandomNumberGenerator.new()
    rng.seed = fingerprint.substr(0,15).hex_to_int()
    var total: float = 0.0
    for record in eligible:
        total += float(record.get("weight",0.0))
    var roll: float = rng.randf() * total
    var picked: Dictionary = eligible.back()
    for record in eligible:
        roll -= float(record.get("weight",0.0))
        if roll < 0.0:
            picked = record
            break
    return {"status":"PROPOSAL_ONLY","committed":false,"authority":"none","version":RELEASE,"selection_hash":fingerprint,"proposals":[{"record_id":str(picked["id"]),"domain":domain,"variables":picked.get("variables",{}).duplicate(true),"tags":picked.get("tags",[]).duplicate(true)}],"rejection_counts":counts,"eligible_count":eligible.size(),"never_apply_directly":true}

func compose(ctx: Dictionary, domains: Array) -> Dictionary:
    if domains.is_empty():
        return {"status":"BLOCKED","reason":"empty_recipe","committed":false,"authority":"none","proposals":[]}
    var generated: Array = []
    var prior_tags: Array = []
    var used: Array = []
    for i in range(domains.size()):
        var local_ctx: Dictionary = ctx.duplicate(true)
        local_ctx["previous_record_ids"] = ctx.get("previous_record_ids",[]).duplicate()
        local_ctx["previous_record_ids"].append_array(used)
        var r: Dictionary = propose(str(domains[i]),local_ctx,str(i),prior_tags)
        if str(r.get("status","")) != "PROPOSAL_ONLY":
            return {"status":"BLOCKED","reason":str(r.get("reason","selection_failed")),"failed_domain":str(domains[i]),"committed":false,"authority":"none","proposals":[],"rejection_counts":r.get("rejection_counts",{})}
        var item: Dictionary = r["proposals"][0]
        used.append(str(item["record_id"]))
        generated.append(item)
        for tag in item.get("tags",[]):
            if tag not in prior_tags:
                prior_tags.append(tag)
    return {"status":"PROPOSAL_ONLY","committed":false,"authority":"none","proposals":generated,"version":RELEASE,"host_approval_required":true}
