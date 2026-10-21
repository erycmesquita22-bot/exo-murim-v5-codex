extends RefCounted
# EXO-Murim World Library 01 v0.3.0. Content proposals ONLY.
# Never spawns actors, writes saves, changes money, publishes Core events or grants rewards.
const MANIFEST_PATH: String = "res://exo_world_library/manifest.json"
const BIOMES: Array[String] = ["grassland", "temperate_forest", "bamboo_forest", "dry_valley", "wetland", "rocky_highlands", "alpine", "mixed_woodland"]
const VERSION: String = "0.3.0"
var catalogs: Dictionary = {}
var by_id: Dictionary = {}
var catalog_manifest: Dictionary = {}
var policy: Dictionary = {}
var errors: Array[String] = []
var is_loaded: bool = false

static func _read_json(path: String) -> Variant:
    if not FileAccess.file_exists(path):
        return null
    return JSON.parse_string(FileAccess.get_file_as_string(path))

func load_catalogs() -> bool:
    catalogs.clear()
    by_id.clear()
    errors.clear()
    is_loaded = false
    var loaded: Variant = _read_json(MANIFEST_PATH)
    if not (loaded is Dictionary):
        errors.append("missing_manifest")
        return false
    if str(loaded.get("schema", "")) != "exo.world_library.manifest.v1" or str(loaded.get("version", "")) != VERSION:
        errors.append("bad_manifest_schema_or_version")
        return false
    if not (loaded.get("catalogs", null) is Array):
        errors.append("invalid_catalog_table")
        return false
    catalog_manifest = loaded.duplicate(true)
    var rule_path: String = str(loaded.get("coherence_policy", ""))
    var raw_policy: Variant = _read_json(rule_path)
    if not (raw_policy is Dictionary):
        errors.append("coherence_policy_missing")
    elif str(raw_policy.get("schema", "")) != "exo.world_library.coherence.v1":
        errors.append("coherence_policy_bad_schema")
    else:
        policy = raw_policy.duplicate(true)
    for entry in loaded["catalogs"]:
        if not (entry is Dictionary):
            errors.append("invalid_catalog_entry")
            continue
        var domain: String = str(entry.get("domain", ""))
        var path: String = str(entry.get("path", ""))
        if domain.is_empty() or catalogs.has(domain):
            errors.append("invalid_or_duplicate_catalog:" + domain)
            continue
        var raw_catalog: Variant = _read_json(path)
        if not (raw_catalog is Dictionary):
            errors.append("missing_catalog:" + domain)
            continue
        if str(raw_catalog.get("schema", "")) != "exo.world_library.catalog.v1" or str(raw_catalog.get("domain", "")) != domain:
            errors.append("bad_catalog_schema:" + domain)
            continue
        var records: Variant = raw_catalog.get("records", null)
        if not (records is Array) or records.size() != int(entry.get("count", -1)):
            errors.append("bad_catalog_count:" + domain)
            continue
        var accepted: Array[Dictionary] = []
        for raw in records:
            if not (raw is Dictionary):
                errors.append("non_dictionary_record:" + domain)
                continue
            var item: Dictionary = raw
            var rid: String = str(item.get("id", ""))
            if rid.length() > 128 or not rid.begins_with(domain + "/") or by_id.has(rid):
                errors.append("invalid_or_duplicate_id:" + rid)
                continue
            if not (item.get("tags") is Array) or not (item.get("conditions") is Dictionary) or not (item.get("variables") is Dictionary) or not (item.get("links") is Array):
                errors.append("bad_record_structure:" + rid)
                continue
            if not (item.get("requires") is Array) or not (item.get("excludes") is Array) or not (item.get("weight") is int or item.get("weight") is float):
                errors.append("bad_record_rules:" + rid)
                continue
            if float(item["weight"]) < 0.0:
                errors.append("negative_weight:" + rid)
                continue
            if str(item.get("origin", "")) == "external_ref" and (float(item["weight"]) != 0.0 or str(item.get("status", "")) != "reference_only"):
                errors.append("unsafe_external_ref:" + rid)
                continue
            accepted.append(item.duplicate(true))
            by_id[rid] = item.duplicate(true)
        accepted.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return str(a["id"]) < str(b["id"]))
        catalogs[domain] = accepted
    for rid in by_id:
        var rec: Dictionary = by_id[rid]
        for link in rec.get("links", []):
            if not by_id.has(str(link)):
                errors.append("unresolved_link:" + str(rid) + "->" + str(link))
    is_loaded = errors.is_empty()
    return is_loaded

func catalog_status() -> Dictionary:
    var counts: Dictionary = {}
    for name in catalogs:
        counts[name] = catalogs[name].size()
    return {"loaded":is_loaded,"domains":counts.size(),"counts":counts,"records":by_id.size(),"errors":errors.duplicate(),"read_only":true,"integration":"NOT_WIRED"}

func resolve(record_id: String) -> Dictionary:
    return by_id.get(record_id, {}).duplicate(true)

static func _canonical(value: Variant) -> String:
    if value is Dictionary:
        var d: Dictionary = value
        var ks: Array = d.keys()
        ks.sort()
        var chunks: PackedStringArray = []
        for k in ks:
            chunks.append(JSON.stringify(str(k)) + ":" + _canonical(d[k]))
        return "{" + ",".join(chunks) + "}"
    if value is Array:
        var chunks: PackedStringArray = []
        for part in value:
            chunks.append(_canonical(part))
        return "[" + ",".join(chunks) + "]"
    return JSON.stringify(value)

static func validate_context(context: Dictionary) -> Dictionary:
    for field in ["world_id", "seed", "region_id"]:
        if not context.has(field):
            return {"ok":false,"reason":"missing_" + field}
    if str(context["world_id"]).strip_edges().is_empty():
        return {"ok":false,"reason":"invalid_world_id"}
    if not (context["seed"] is int or context["seed"] is float) or int(context["seed"]) != context["seed"]:
        return {"ok":false,"reason":"invalid_seed"}
    if not (context["region_id"] is int or context["region_id"] is float):
        return {"ok":false,"reason":"invalid_region_id"}
    if int(context["region_id"]) < 0 or int(context["region_id"]) > 87 or int(context["region_id"]) != context["region_id"]:
        return {"ok":false,"reason":"out_of_range_region_id"}
    if context.has("biome") and str(context["biome"]) not in BIOMES:
        return {"ok":false,"reason":"invalid_biome"}
    if context.has("settlement_type") and str(context["settlement_type"]) not in ["village", "town", "city", "none"]:
        return {"ok":false,"reason":"invalid_settlement_type"}
    if context.has("tags") and not (context["tags"] is Array):
        return {"ok":false,"reason":"invalid_tags"}
    if context.has("flags") and not (context["flags"] is Array):
        return {"ok":false,"reason":"invalid_flags"}
    if context.has("player_tier"):
        if not (context["player_tier"] is int or context["player_tier"] is float):
            return {"ok":false,"reason":"invalid_player_tier"}
        if context["player_tier"] < 0 or int(context["player_tier"]) != context["player_tier"]:
            return {"ok":false,"reason":"invalid_player_tier"}
    return {"ok":true}

static func _matches(record: Dictionary, context: Dictionary) -> bool:
    var cond: Dictionary = record.get("conditions", {})
    for key in cond:
        var k: String = str(key)
        var target: Variant = cond[key]
        if k.ends_with("_in"):
            var name: String = k.substr(0, k.length() - 3)
            if not context.has(name) or not (target is Array) or context[name] not in target:
                return false
        elif k == "min_player_tier":
            if not context.has("player_tier") or int(context["player_tier"]) < int(target):
                return false
        elif k == "max_player_tier":
            if not context.has("player_tier") or int(context["player_tier"]) > int(target):
                return false
        elif k == "tags_all":
            if not (target is Array):
                return false
            for need in target:
                if need not in context.get("tags", []):
                    return false
        elif k == "tags_any":
            if not (target is Array):
                return false
            var hit: bool = false
            for need in target:
                if need in context.get("tags", []):
                    hit = true
            if not hit:
                return false
        elif not context.has(k) or context[k] != target:
            return false
    var flags: Array = context.get("flags", [])
    for need in record.get("requires", []):
        if need not in flags:
            return false
    for blocked in record.get("excludes", []):
        if blocked in flags:
            return false
    return true

func coherence_reason(record: Dictionary, context: Dictionary, selected_tags: Array = []) -> String:
    var tags: Array = selected_tags.duplicate()
    for t in context.get("tags", []):
        if t not in tags:
            tags.append(t)
    var new_tags: Array = record.get("tags", [])
    for m in policy.get("mutually_exclusive_tag_sets", []):
        var conflicts: int = 0
        for t in m:
            if t in tags or t in new_tags:
                conflicts += 1
        if conflicts > 1:
            return "mutually_exclusive_tags:" + ",".join(PackedStringArray(m))
    for row in policy.get("context_incompatibilities", []):
        var applicable: bool = true
        for k in row.get("if_context", {}):
            if not context.has(k) or context[k] != row["if_context"][k]:
                applicable = false
        if applicable:
            for t in row.get("reject_any_tags", []):
                if t in new_tags:
                    return "context_forbids_tag:" + str(t)
    for requirement in policy.get("selected_tag_requirements", []):
        if requirement.get("tag", "") in new_tags:
            var any_found: bool = false
            for t in requirement.get("any_of", []):
                if t in tags or t in new_tags:
                    any_found = true
            if not any_found:
                return "missing_selected_tag_dependency:" + str(requirement.get("tag", ""))
    return ""

func query(domain: String, context: Dictionary, max_results: int = 256) -> Dictionary:
    if not is_loaded:
        return {"ok":false,"error":"library_not_loaded","records":[]}
    var check: Dictionary = validate_context(context)
    if not check.get("ok", false):
        return {"ok":false,"error":str(check.get("reason", "invalid_context")),"records":[]}
    if not catalogs.has(domain):
        return {"ok":false,"error":"unknown_domain:" + domain,"records":[]}
    var matches: Array[Dictionary] = []
    var count: int = 0
    var selected_tags: Array = context.get("_selected_tags", [])
    for record in catalogs[domain]:
        if float(record.get("weight", 0)) <= 0.0 or str(record.get("origin", "")) == "external_ref":
            continue
        if not _matches(record, context) or not coherence_reason(record, context, selected_tags).is_empty():
            continue
        count += 1
        if matches.size() < maxi(0, max_results):
            matches.append(record.duplicate(true))
    return {"ok":true,"count":count,"records":matches,"read_only":true}

func select(domain: String, context: Dictionary, slot_key: String = "0") -> Dictionary:
    var result: Dictionary = query(domain, context, 100000)
    if not bool(result.get("ok", false)):
        return result
    var records: Array = result.get("records", [])
    if records.is_empty():
        return {"ok":false,"error":"no_eligible_records:" + domain,"read_only":true}
    var total: float = 0.0
    var scores: Array[float] = []
    var previous_tags: Array = context.get("_selected_tags", [])
    for record in records:
        var affinity: int = 0
        for tag in record.get("tags", []):
            if tag in previous_tags and tag not in ["npc", "event", "settlement", "regional", "biome", "loot", "crowd", "ambient"]:
                affinity += 1
        var score: float = float(record.get("weight", 0.0)) * (1.0 + 0.5 * mini(affinity, 2))
        scores.append(score)
        total += score
    var hash_context: Dictionary = context.duplicate(true)
    # Inputs are immutable; sort via canonical JSON to remain independent of dictionary insertion order.
    var digest: String = ("EXO|WORLD_LIBRARY|" + VERSION + "|" + domain + "|" + slot_key + "|" + _canonical(hash_context)).sha256_text()
    var rng: RandomNumberGenerator = RandomNumberGenerator.new()
    rng.seed = digest.substr(0, 15).hex_to_int()
    var roll: float = rng.randf() * total
    for i in range(records.size()):
        roll -= scores[i]
        if roll < 0.0:
            return {"ok":true,"record":records[i],"selection_hash":digest,"read_only":true}
    return {"ok":true,"record":records.back(),"selection_hash":digest,"read_only":true}

func validate_bundle(context: Dictionary, record_ids: Array) -> Dictionary:
    var valid: Dictionary = validate_context(context)
    if not valid.get("ok", false):
        return {"valid":false,"reason":str(valid.get("reason", "invalid_context"))}
    var tags: Array = []
    var seen: Dictionary = {}
    for rid in record_ids:
        if seen.has(str(rid)):
            return {"valid":false,"reason":"duplicate_record:" + str(rid)}
        seen[str(rid)] = true
        if not by_id.has(str(rid)):
            return {"valid":false,"reason":"unknown_record:" + str(rid)}
        var rec: Dictionary = by_id[str(rid)]
        if rec.get("origin", "") != "authorial" or float(rec.get("weight", 0.0)) <= 0.0:
            return {"valid":false,"reason":"non_selectable_record:" + str(rid)}
        if not _matches(rec, context):
            return {"valid":false,"reason":"record_conditions_failed:" + str(rid)}
        var why: String = coherence_reason(rec, context, tags)
        if not why.is_empty():
            return {"valid":false,"reason":why,"record_id":str(rid)}
        for t in rec.get("tags", []):
            if t not in tags:
                tags.append(t)
    return {"valid":true,"tags":tags,"read_only":true}

func compose(context: Dictionary, domains: Array) -> Dictionary:
    var check: Dictionary = validate_context(context)
    if not bool(check.get("ok", false)):
        return {"status":"BLOCKED","reason":str(check.get("reason", "invalid_context")),"proposals":[],"committed":false}
    var tags: Array = context.get("tags", []).duplicate()
    var ctx: Dictionary = context.duplicate(true)
    var proposals: Array[Dictionary] = []
    var selected_ids: Array = []
    for i in range(domains.size()):
        var domain: String = str(domains[i])
        ctx["tags"] = tags.duplicate()
        ctx["_selected_tags"] = tags.duplicate()
        var selected: Dictionary = select(domain, ctx, str(i))
        if not bool(selected.get("ok", false)):
            return {"status":"BLOCKED","reason":str(selected.get("error", "selection_failed")),"failed_domain":domain,"proposals":proposals,"committed":false}
        var rec: Dictionary = selected["record"]
        if rec["id"] in selected_ids:
            return {"status":"BLOCKED","reason":"duplicate_record","proposals":proposals,"committed":false}
        selected_ids.append(rec["id"])
        proposals.append({"domain":domain,"record_id":rec["id"],"label":rec["label"],"variables":rec.get("variables", {}).duplicate(true),"selection_hash":selected["selection_hash"]})
        for t in rec.get("tags", []):
            if t not in tags:
                tags.append(t)
    return {"status":"PROPOSAL_ONLY","library_version":VERSION,"world_id":str(context["world_id"]),"region_id":int(context["region_id"]),"proposals":proposals,"tags":tags,"committed":false,"authority":"none"}
