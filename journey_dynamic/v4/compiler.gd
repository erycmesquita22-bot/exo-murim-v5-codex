extends RefCounted
const Schema=preload("res://journey_dynamic/v4/schema.gd")
# Build a deterministic definition from REAL Library records. No quest is accepted here.
static func compile_story(record: Dictionary, catalog_version: String) -> Dictionary:
    if str(record.get("domain",""))!="story_arc" or str(record.get("origin",""))!="authorial":
        return {"ok":false,"reason":"record_not_authorial_story_arc"}
    var story_id: String=str(record.get("id",""))
    if not story_id.begins_with("story_arc/") or catalog_version.is_empty():return {"ok":false,"reason":"story_identity"}
    var variables: Variant=record.get("variables",null)
    if not (variables is Dictionary) or not (variables.get("nodes") is Array):return {"ok":false,"reason":"story_nodes_absent"}
    var nodes: Array=[]
    var raw_nodes: Array=variables.nodes
    for raw in raw_nodes:
        if not (raw is Dictionary):return {"ok":false,"reason":"story_node_invalid"}
        var choices: Array=[]
        for c in raw.get("choices",[]):
            if not (c is Dictionary):return {"ok":false,"reason":"story_choice_invalid"}
            choices.append({"id":str(c.get("id","")),"next":str(c.get("next","")),"label_key":story_id+"/choice/"+str(c.get("id","")),"proposed_facts":c.get("propose_facts",[]).duplicate(true)})
        nodes.append({"id":str(raw.get("id","")),"terminal":str(raw.get("stage",""))=="terminal", "phase":str(raw.get("stage","")),"choices":choices,
            "text_key":story_id+"/node/"+str(raw.get("id","")),"requirements":[{"owner":"world","status":"UNVERIFIED"}],"optional":false})
    var definition: Dictionary={"schema":"exo.journey.definition.v2","id":"j02/definition/"+story_id.trim_prefix("story_arc/"),"story_id":story_id,
        "catalog_version":catalog_version,"source_status":str(record.get("status","")),"start_node":"opening","nodes":nodes,"owner":"journey",
        "narrative_commit":"BLOCKED_UNTIL_OWNER_CONTRACT","reward_proposal":{"authority":"owner_required","currency":{},"xp":0}}
    if not nodes.is_empty():definition.start_node=str(nodes[0].id)
    var validation: Dictionary=Schema.validate_definition(definition)
    if not bool(validation.get("ok",false)):return {"ok":false,"reason":str(validation.get("reason","schema_invalid"))}
    return {"ok":true,"status":"PROPOSAL_ONLY","definition":definition,"committed":false}
