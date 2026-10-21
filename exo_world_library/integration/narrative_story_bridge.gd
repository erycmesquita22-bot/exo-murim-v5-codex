extends RefCounted
# R3 story and political proposals; NO SAVE WRITES, NO EVENT BUS, NO WORLD MUTATION.
const LIBRARY = preload("res://exo_world_library/core/entrypoint.gd")
var library: Variant = null
func initialize() -> bool:
    library = LIBRARY.new()
    return library.load_catalogs()

func inspect_arc(story_id: String) -> Dictionary:
    if library == null or not library.is_loaded:
        return {"status":"BLOCKED", "reason":"catalog_not_ready"}
    var r: Dictionary = library.resolve(story_id)
    if str(r.get("domain", "")) != "story_arc":
        return {"status":"BLOCKED", "reason":"not_an_arc"}
    return {"status":"PROPOSAL_ONLY", "story":r.duplicate(true), "committed":false}

func preview_node(story_id: String, node_id: String) -> Dictionary:
    var arc: Dictionary = inspect_arc(story_id)
    if str(arc.get("status", "")) != "PROPOSAL_ONLY":
        return arc
    var story: Dictionary = arc["story"].get("variables", {})
    for raw in story.get("nodes", []):
        if str(raw.get("id", "")) == node_id:
            return {"status":"PROPOSAL_ONLY", "story_id":story_id, "node":raw.duplicate(true), "committed":false}
    return {"status":"BLOCKED", "reason":"unknown_story_node"}

func propose_choice(story_id: String, current_node: String, choice_id: String, verified_host_snapshot: Dictionary) -> Dictionary:
    # This is only a *draft*; the authoritative Narrative module MUST validate and commit.
    # A caller-supplied boolean is never proof of host authority.
    if not (verified_host_snapshot.has("world_id") and verified_host_snapshot.has("region_id") and verified_host_snapshot.has("instance_id") and verified_host_snapshot.has("state_revision")):
        return {"status":"BLOCKED", "reason":"host_snapshot_incomplete", "committed":false}
    var arc: Dictionary = preview_node(story_id, current_node)
    if str(arc.get("status", "")) != "PROPOSAL_ONLY":
        return arc
    var node: Dictionary = arc["node"]
    for raw in node.get("choices", []):
        if str(raw.get("id", "")) == choice_id:
            var next_node: String = str(raw.get("next", ""))
            var target: Dictionary = preview_node(story_id, next_node)
            if str(target.get("status", "")) != "PROPOSAL_ONLY":
                return {"status":"BLOCKED", "reason":"invalid_next_node", "committed":false}
            return {"status":"PROPOSAL_ONLY", "committed":false, "requires_host_authorization":true, "story_id":story_id, "instance_id":str(verified_host_snapshot["instance_id"]), "expected_revision":verified_host_snapshot["state_revision"], "from_node":current_node, "choice_id":choice_id, "to_node":next_node, "suggested_facts":raw.get("propose_facts", []).duplicate(true), "next_is_terminal":str(target["node"].get("stage", "")) == "terminal", "host_mutations":[]}
    return {"status":"BLOCKED", "reason":"choice_not_found", "committed":false}

func inspect_political_record(record_id: String) -> Dictionary:
    if library == null or not library.is_loaded:
        return {"status":"BLOCKED", "reason":"catalog_not_ready"}
    var r: Dictionary = library.resolve(record_id)
    if str(r.get("domain", "")) not in ["war_casus", "revolution_cause", "civic_institution", "ballot_rule", "council_motion", "election_campaign", "peace_treaty", "diplomatic_offer"]:
        return {"status":"BLOCKED", "reason":"unsupported_political_domain"}
    return {"status":"PROPOSAL_ONLY", "committed":false, "record":r.duplicate(true), "requires_host_authorization":true}
