extends SceneTree
# Godot native smoke/regression gate (REQUIRES exact C3 checkpoint + staged V4 files).
const Legacy=preload("res://journey_dynamic/quest_manager.gd")
const Generator=preload("res://journey_dynamic/quest_generator.gd")
const Ext=preload("res://journey_dynamic/v4/extension.gd")
const Schema=preload("res://journey_dynamic/v4/schema.gd")
const Compiler=preload("res://journey_dynamic/v4/compiler.gd")
var errors: Array[String]=[]
var count: int=0
func check(ok: bool,label: String) -> void:
    count+=1
    if not ok:errors.append(label)
func _initialize() -> void:
    var fresh: Dictionary=Legacy.fresh()
    check(Legacy.valid(fresh),"legacy_fresh")
    check(Generator.TYPES.size()==7,"legacy_seven_types")
    check(Ext.inspect(fresh).status=="PROPOSAL_ONLY","v4_read_only")
    check(Schema.valid_storage(Schema.fresh()),"v4_storage")
    check(not Schema.valid_storage({"schema":2}),"invalid_storage_rejected")
    check(not bool(Ext.request_accept(null,{}).get("ok",true)),"unbound_accept_blocked")
    check(not bool(Ext.request_reward(null,{}).get("ok",true)),"unbound_reward_blocked")
    check(not bool(Ext.request_choice(null,{},"a").get("ok",true)),"unbound_choice_blocked")
    var fake: Dictionary={"domain":"story_arc","origin":"authorial","id":"story_arc/smoke","variables":{"nodes":[{"id":"opening","stage":"rumor","choices":[{"id":"go","next":"ending"}]},{"id":"ending","stage":"terminal","choices":[]}]}}
    var compiled: Dictionary=Compiler.compile_story(fake,"test-version")
    check(bool(compiled.get("ok",false)),"compiler_dag")
    check(not bool(Ext.preview(null,fake,{"catalog_version":"test-version","locator":{"type":"region","region_id":3}}).get("ok",false)),"host_absent_blocked")
    print("JORNADA_V4_NATIVE ",JSON.stringify({"checks":count,"failures":errors,"result":"PASS" if errors.is_empty() else "FAIL"}))
    quit(0 if errors.is_empty() else 1)
