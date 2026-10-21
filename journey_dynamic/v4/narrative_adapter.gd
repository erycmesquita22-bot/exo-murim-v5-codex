extends RefCounted
# Read-only comparison with actual C3 Narrative. Its hooks (manual/rival/dispute)
# are NOT automatically mapped to World Library R4's story_arc IDs.
const Hooks=preload("res://narrative/stories/narrative_hooks.gd")
static func inspect_story_access(world: Object,story_id: String) -> Dictionary:
    if world==null or not is_instance_valid(world):return {"status":"BLOCKED","reason":"host_missing"}
    if not str(story_id).begins_with("story_arc/"):return {"status":"BLOCKED","reason":"invalid_library_story_id"}
    if not world.get("exo_core") is Object:return {"status":"BLOCKED","reason":"exo_core_missing"}
    var core: Object=world.get("exo_core")
    if not core.services.has_service("narrative"):return {"status":"BLOCKED","reason":"narrative_service_missing"}
    # Only social_context / narrative_opportunities / master_disciple_* are present.
    return {"status":"BLOCKED","reason":"catalog_story_write_api_missing","known_narrative_ids":"story/manual, story/rival, story/dispute"}
