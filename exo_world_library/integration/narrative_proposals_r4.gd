extends RefCounted
# Unprivileged authorial story proposals. The Narrative owner is the ONLY actor that can accept/commit.
const Library = preload("res://exo_world_library/core/entrypoint.gd")
var library: Variant = null
func initialize() -> bool:
    library = Library.new()
    return library.load_catalogs()

static func _blocked(reason: String) -> Dictionary:
    return {"status":"BLOCKED","reason":reason,"committed":false,"authority":"none","proposals":[]}

static func _graph_validate(story: Dictionary) -> String:
    var variables: Dictionary = story.get("variables",{})
    var nodes: Array = variables.get("nodes",[])
    if nodes.is_empty():
        return "story_has_no_nodes"
    var by_node: Dictionary = {}
    for n in nodes:
        if not n is Dictionary or str(n.get("id","")).is_empty() or by_node.has(str(n.get("id",""))):
            return "duplicate_or_invalid_node"
        by_node[str(n["id"])] = n
    var terminal_count: int = 0
    for n in nodes:
        if str(n.get("stage","")) == "terminal":
            terminal_count += 1
            if not n.get("choices",[]).is_empty():
                return "terminal_has_outgoing_choices"
        for choice in n.get("choices",[]):
            if not by_node.has(str(choice.get("next",""))):
                return "dangling_story_choice"
    if terminal_count < 1:
        return "no_terminal_node"
    # Exhaustively detect any non-terminating paths, including cycles.
    for start in by_node.keys():
        var stack: Array = [[str(start),[]]]
        while not stack.is_empty():
            var row: Array = stack.pop_back()
            var key: String = str(row[0])
            var trail: Array = row[1]
            if key in trail:
                return "non_terminating_cycle"
            var n: Dictionary = by_node[key]
            if str(n.get("stage","")) == "terminal":
                continue
            if n.get("choices",[]).is_empty():
                return "non_terminal_dead_end"
            var next_trail: Array = trail.duplicate()
            next_trail.append(key)
            for choice in n["choices"]:
                stack.append([str(choice["next"]), next_trail])
    return ""

func validate_arc(story_id: String) -> Dictionary:
    if library == null or not library.is_loaded:
        return _blocked("not_initialized")
    var story: Dictionary = library.resolve(story_id)
    if str(story.get("domain","")) != "story_arc" or str(story.get("origin","")) != "authorial":
        return _blocked("missing_authorial_story")
    var reason: String = _graph_validate(story)
    if not reason.is_empty():
        return _blocked(reason)
    return {"status":"PROPOSAL_ONLY","story_id":story_id,"committed":false,"authority":"none","terminal_verified":true,"proposals":[]}

func propose_spawn(story_id: String, request: Dictionary) -> Dictionary:
    var proof: Dictionary = validate_arc(story_id)
    if str(proof.get("status","")) != "PROPOSAL_ONLY":
        return proof
    for field in ["world_id","seed","region_id","location_id","story_instance_id","pinned_story_version","expected_revision"]:
        if not request.has(field):
            return _blocked("missing_"+field)
    if not (request["expected_revision"] is int) or int(request["expected_revision"]) != 0:
        return _blocked("spawn_expected_revision_must_be_zero")
    if str(request["story_instance_id"]).strip_edges().is_empty() or str(request["location_id"]).strip_edges().is_empty():
        return _blocked("missing_persistent_identity")
    if int(request["region_id"]) < 0 or int(request["region_id"]) > 87:
        return _blocked("invalid_region")
    if str(request["pinned_story_version"]) != "0.3.0":
        return _blocked("incompatible_story_version_pin")
    var ctx: Dictionary = request.duplicate(true)
    var validity: Dictionary = Library.validate_context(ctx)
    if not bool(validity.get("ok",false)):
        return _blocked(str(validity.get("reason","invalid_context")))
    var story: Dictionary = library.resolve(story_id)
    if not Library._matches(story,ctx):
        return _blocked("story_conditions_not_met")
    var instance_id: String = str(request["story_instance_id"])
    if instance_id.length() > 112:
        return _blocked("story_instance_id_too_long")
    var fingerprint: String = ("exo-r4-story|spawn|"+story_id+"|"+instance_id+"|"+str(request["world_id"])+"|"+str(request["region_id"])).sha256_text()
    return {"status":"PROPOSAL_ONLY","committed":false,"authority":"none","proposals":[{"action":"request_story_spawn","story_id":story_id,"story_instance_id":instance_id,"expected_revision":0,"start_node":str(story.get("variables",{}).get("nodes",[])[0].get("id","opening")),"pinned_story_version":"0.3.0","location_id":str(request["location_id"]),"proposal_fingerprint":fingerprint,"host_validation_required":true}]}

func propose_choice(story_id: String, host_snapshot: Dictionary, chosen_option_ids: Array) -> Dictionary:
    var status: Dictionary = validate_arc(story_id)
    if str(status.get("status","")) != "PROPOSAL_ONLY":
        return status
    for field in ["story_instance_id","state_revision","expected_revision","current_node","pinned_story_version","world_id","region_id"]:
        if not host_snapshot.has(field):
            return _blocked("missing_"+field)
    if str(host_snapshot["pinned_story_version"]) != "0.3.0":
        return _blocked("story_version_pin_mismatch")
    if not (host_snapshot["state_revision"] is int and host_snapshot["expected_revision"] is int):
        return _blocked("non_integer_revision")
    if host_snapshot["state_revision"] != host_snapshot["expected_revision"]:
        return _blocked("stale_revision")
    if chosen_option_ids.size() != 1 or not (chosen_option_ids[0] is String):
        return _blocked("one_choice_required")
    var story: Dictionary = library.resolve(story_id)
    var current: Dictionary = {}
    for n in story.get("variables",{}).get("nodes",[]):
        if str(n["id"]) == str(host_snapshot["current_node"]):
            current = n
            break
    if current.is_empty() or str(current.get("stage","")) == "terminal":
        return _blocked("invalid_or_terminal_current_node")
    for choice in current.get("choices",[]):
        if str(choice.get("id","")) == str(chosen_option_ids[0]):
            var target: String = str(choice.get("next",""))
            var receipts: Array = []
            for fact in choice.get("propose_facts",[]):
                receipts.append({"fact_key":str(fact),"verified":false,"authoritative_owner":"narrative"})
            var identity: String = ("exo|world_library|" + story_id+"|"+str(host_snapshot["story_instance_id"])+"|"+str(host_snapshot["expected_revision"])+"|"+str(chosen_option_ids[0])).sha256_text()
            return {"status":"PROPOSAL_ONLY","committed":false,"authority":"none","proposals":[{"action":"commit_story_choice_PROPOSAL_NOT_API","story_id":story_id,"story_instance_id":str(host_snapshot["story_instance_id"]),"expected_revision":host_snapshot["expected_revision"],"from_node":str(current["id"]),"to_node":target,"chosen_option_ids":chosen_option_ids.duplicate(),"fact_receipts":receipts,"proposal_fingerprint":identity,"host_must_verify_replay_and_save":true}],"requires_narrative_owner":true}
    return _blocked("choice_not_authorial")

func advance_offscreen(story_id: String, host_snapshot: Dictionary, target_day: int) -> Dictionary:
    if not host_snapshot.has("world_day") or not host_snapshot["world_day"] is int:
        return _blocked("host_day_missing")
    if target_day < int(host_snapshot["world_day"]) or target_day > int(host_snapshot["world_day"]) + 1:
        return _blocked("advance_one_day_only")
    if target_day == int(host_snapshot["world_day"]):
        return _blocked("no_new_day")
    var node: String = str(host_snapshot.get("current_node",""))
    var story: Dictionary = library.resolve(story_id) if library != null else {}
    if story.is_empty():
        return _blocked("story_missing")
    for n in story.get("variables",{}).get("nodes",[]):
        if str(n.get("id","")) == node:
            var choices: Array = n.get("choices",[])
            # No autonomous arbitrary choice: NPC/system owner must elect a branch.
            return {"status":"PROPOSAL_ONLY","committed":false,"authority":"none","proposals":[{"action":"advance_offscreen_PROPOSAL_NOT_API","story_id":story_id,"story_instance_id":str(host_snapshot.get("story_instance_id","")),"expected_revision":host_snapshot.get("expected_revision",-1),"target_day":target_day,"available_option_ids":choices.map(func(c: Dictionary)->String: return str(c.get("id",""))),"fact_receipts":[],"requires_host_clock_and_choice":true}]}
    return _blocked("unknown_story_node")
