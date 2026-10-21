extends SceneTree
const Atlas=preload("res://genesis/world_planner.gd")
const Bridge=preload("res://narrative/adapters/journey_bridge.gd")
const State=preload("res://narrative/core/narrative_state.gd")
const LivingState=preload("res://living_world/state.gd")
func _initialize() -> void:
	var path: String="user://narrative_qa_reopen.json"
	if not FileAccess.file_exists(path):
		push_error("NOT_RUN: QA first process must be executed before reopen")
		quit(2);return
	var data: Variant=JSON.parse_string(FileAccess.get_file_as_string(path))
	if not data is Dictionary:quit(1);return
	data.narrative=LivingState.restore_numbers(data.narrative)
	var atlas: Dictionary=Atlas.read_atlas("res://genesis/atlas_seed_101.json")
	var valid: bool=State.valid(data.narrative)
	var original_count: int=data.narrative.receipts.size()
	var duplicate: Dictionary=Bridge.ingest(data,atlas,{"id":"npc/help/001","type":"npc_helped","source":"qa_fixture","region":86,"clock":910.0,"npc_id":"npc/r86/narrative_fixture","context":{}})
	var passed: bool=valid and bool(duplicate.get("duplicate",false)) and data.narrative.receipts.size()==original_count and data.narrative.decisions.size()==3
	print("NARRATIVE_REOPEN "+JSON.stringify({"pass":passed,"receipt_count":original_count,"decisions":data.narrative.decisions.size()}))
	quit(0 if passed else 1)
