extends RefCounted
## In-process bridge from the real Techniques release owner to passive VFX Forge.
const Catalog=preload("res://catalog.gd")
const RECIPES={"cut":"vfx.slash.qi.blue.v1","area":"vfx.slash.qi.blue.v1","dash":"vfx.dash.afterimage.jade.v1","leap":"vfx.dash.afterimage.jade.v1","projectile":"vfx.beam.qi.v1","channel":"vfx.beam.qi.v1","shield":"vfx.crown.frost.v1","heal":"vfx.teleport.short.violet.v1","summon":"vfx.crown.frost.v1","pull":"vfx.slash.qi.blue.v1","repel":"vfx.slash.qi.blue.v1","root":"vfx.crown.frost.v1","trap":"vfx.crown.frost.v1"}
var world: Node3D
var module: RefCounted
var pending: Dictionary={}
var emitted: int=0
var rejected: int=0
func initialize(host: Node3D) -> bool:
    world=host
    module=world.exo_core.instances.get("exo_vfx_forge")
    if module==null:return false
    var bindings: Dictionary={}
    for skill in Catalog.SKILLS:
        if RECIPES.has(str(skill.kind)):bindings[str(skill.id)]=[RECIPES[str(skill.kind)]]
    return module.bind_trusted_bridge(Callable(self,"verify"),bindings)
func verify(payload: Dictionary) -> bool:
    return pending.has(JSON.stringify(payload))
func release(data: Dictionary) -> bool:
    if module==null or world.techniques.active<0 or data!=world.techniques.casting:return false
    if not RECIPES.has(str(data.kind)):return false
    var p: Vector3=world.player.global_position+Vector3(0,.2,0)
    var d: Vector3=world.techniques.direction
    var e: Dictionary={"contract_version":"exo.vfx.events/1","cast_instance_id":"player/"+str(data.get("_cast",0)),"skill_id":str(data.id),"caster_entity_id":"player","cue_id":"release","vfx_id":RECIPES[str(data.kind)],"phase":"launch","event_sequence":0,"visual_seed":int(world.journey.data.world.seed),"origin_xyz":[p.x,p.y,p.z],"direction_xyz":[d.x,d.y,d.z],"quality_profile":"low" if int(world.graphics.values.impact_details)==0 else "medium"}
    var key: String=JSON.stringify(e)
    pending[key]=true
    var result: Dictionary=module.receive_authorized_cue(e)
    pending.erase(key)
    if bool(result.get("ok",false)):emitted+=1;return true
    rejected+=1
    push_warning("VFX release: "+str(result))
    return false

func release_prologue_actor(actor:Node3D,data:Dictionary,sequence:int,direction:Vector3)->bool:
    if module==null or world.flow.phase!="prologue" or not world.flow.actors.has(actor) or actor.hp<=0:return false
    if str(data.id) not in Catalog.HEROES[int(actor.faction)].skills:return false
    var kind:String=str(data.kind)
    var recipe:String=RECIPES.get(kind,"vfx.slash.qi.blue.v1")
    # The exact skill->recipe mapping was bound during initialize, just as for player releases.
    var p:Vector3=actor.global_position+Vector3(0,.3,0)
    var cue:Dictionary={"contract_version":"exo.vfx.events/1","cast_instance_id":str(actor.uid)+"/skill/"+str(sequence),"skill_id":str(data.id),"caster_entity_id":str(actor.uid),"cue_id":"release","vfx_id":recipe,"phase":"launch","event_sequence":0,"visual_seed":int(world.journey.data.world.seed),"origin_xyz":[p.x,p.y,p.z],"direction_xyz":[direction.x,direction.y,direction.z],"quality_profile":"low" if int(world.graphics.values.impact_details)==0 else "medium"}
    var key:String=JSON.stringify(cue);pending[key]=true
    var result:Dictionary=module.receive_authorized_cue(cue);pending.erase(key)
    if bool(result.get("ok",false)):emitted+=1;return true
    rejected+=1;return false
