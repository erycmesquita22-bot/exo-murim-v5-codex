extends RefCounted
# Pure structure checks. Data belongs to JourneyManager's journey_dynamic envelope.
const VERSION: int = 2
const MAX_INSTANCES: int = 5
const MAX_RECEIPTS: int = 1024
const MAX_HISTORY: int = 128
const MAX_NODES: int = 64
const MAX_CHOICES: int = 8
const MAX_DEPTH: int = 64

static func fresh() -> Dictionary:
    return {"schema":VERSION,"instances":{},"receipts":{},"history":[],"tracked":""}

static func valid_storage(raw: Variant) -> bool:
    if not (raw is Dictionary): return false
    if int(raw.get("schema", -1)) != VERSION: return false
    for key in ["instances", "receipts"]:
        if not (raw.get(key) is Dictionary): return false
    if not (raw.get("history") is Array) or not (raw.get("tracked") is String): return false
    if raw.instances.size() > MAX_INSTANCES or raw.receipts.size() > MAX_RECEIPTS or raw.history.size() > MAX_HISTORY: return false
    if str(raw.tracked).length() > 128: return false
    for k in raw.receipts:
        if not (k is String) or str(k).is_empty() or str(k).length() > 160: return false
        if not (raw.receipts[k] is Dictionary): return false
    for k in raw.instances:
        if not (k is String) or not str(k).begins_with("j02/") or str(k).length() > 128: return false
        var i: Variant = raw.instances[k]
        if not (i is Dictionary): return false
        if str(i.get("status", "")) not in ["BLOCKED", "PROPOSED", "ACTIVE", "COMPLETED", "CANCELLED", "FAILED", "REWARDED"]: return false
        if not (i.get("catalog_version") is String) or not (i.get("story_id") is String): return false
        if not (i.get("decisions") is Dictionary) or not (i.get("objective_receipts") is Dictionary): return false
        if not (i.get("revision") is int) or int(i.revision) < 0: return false
        if str(i.get("status", "")) in ["ACTIVE", "COMPLETED", "REWARDED"] and not bool(i.get("owner_authorized", false)): return false
    return true

static func validate_definition(d: Dictionary) -> Dictionary:
    if str(d.get("schema", "")) != "exo.journey.definition.v2": return {"ok":false,"reason":"schema"}
    for field in ["id","story_id","catalog_version","start_node"]:
        if not (d.get(field) is String) or str(d[field]).is_empty(): return {"ok":false,"reason":"missing_" + field}
    if not str(d.id).begins_with("j02/definition/"): return {"ok":false,"reason":"id_prefix"}
    var nodes: Variant = d.get("nodes", null)
    if not (nodes is Array) or nodes.is_empty() or nodes.size() > MAX_NODES:return {"ok":false,"reason":"node_capacity"}
    var graph: Dictionary = {}
    var finals: int = 0
    for v in nodes:
        if not (v is Dictionary):return {"ok":false,"reason":"node_not_dictionary"}
        var nid: String = str(v.get("id", ""))
        if nid.is_empty() or nid.length()>80 or graph.has(nid):return {"ok":false,"reason":"duplicate_or_invalid_node"}
        if not (v.get("choices") is Array) or v.choices.size()>MAX_CHOICES:return {"ok":false,"reason":"choices"}
        graph[nid]=v
        if bool(v.get("terminal", false)):finals+=1
    if not graph.has(str(d.start_node)) or finals==0:return {"ok":false,"reason":"missing_start_or_terminal"}
    for nid in graph:
        var node: Dictionary=graph[nid]
        var choice_ids: Dictionary={}
        if bool(node.get("terminal",false)) and not node.choices.is_empty():return {"ok":false,"reason":"terminal_with_choices"}
        if not bool(node.get("terminal",false)) and node.choices.is_empty():return {"ok":false,"reason":"dead_end"}
        for c in node.choices:
            if not (c is Dictionary):return {"ok":false,"reason":"invalid_choice"}
            var cid: String=str(c.get("id",""))
            var dest: String=str(c.get("next",""))
            if cid.is_empty() or choice_ids.has(cid) or not graph.has(dest):return {"ok":false,"reason":"bad_edge"}
            choice_ids[cid]=true
    # Reject all cycles, even bounded ones; authorial R4 arcs are DAGs.
    var status: Dictionary={}
    var reached_terminal: bool=false
    var stack: Array=[{"node":str(d.start_node),"finish":false}]
    while not stack.is_empty():
        var row: Dictionary=stack.pop_back()
        var nid: String=str(row.node)
        if bool(row.finish):status[nid]=2;continue
        if int(status.get(nid,0))==1:return {"ok":false,"reason":"cycle"}
        if int(status.get(nid,0))==2:continue
        status[nid]=1
        stack.append({"node":nid,"finish":true})
        if bool(graph[nid].terminal):reached_terminal=true
        for c in graph[nid].choices:
            stack.append({"node":str(c.next),"finish":false})
    if not reached_terminal or status.size()!=graph.size():return {"ok":false,"reason":"unreachable_or_no_terminal"}
    return {"ok":true,"node_count":graph.size(),"terminals":finals}
