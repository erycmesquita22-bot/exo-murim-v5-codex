extends RefCounted
const TerritoryPlan=preload("res://regional_ecology/territories.gd")
const Reward=preload("res://regional_ecology/rewards.gd")
const Enemy=preload("res://enemy.gd")
const FaunaActor=preload("res://exo_bestiary/integration/regional_fauna_actor.gd")
const MAX_ACTIVE:=8
var world: Node3D
var sites: Array=[]
var active: Dictionary={}
var timer:=0.0
var region_id: int=-1
func dead_members(record: Dictionary) -> Array[int]:
	# JSON numbers load as floats; membership must use canonical integer IDs.
	var result: Array[int]=[]
	for value in record.get("members_dead",[]):
		var member:=int(value)
		if member>=0 and not result.has(member):result.append(member)
	return result
const SPAWN_MIN_DISTANCE:=19.0
const SPAWN_MAX_DISTANCE:=85.0
const DESPAWN_DISTANCE:=105.0
func visible_spawn(point: Vector3) -> bool:
	if world.camera==null:return true
	# Bounds of an upright Minecraft-rig actor, not merely the site centre.
	for height in [0.4,1.1,2.3]:
		if world.camera.is_position_in_frustum(point+Vector3.UP*height):return true
	return false
func reap_distant() -> void:
	for key in active.keys():
		var actor: Node3D=active[key]
		if not is_instance_valid(actor):active.erase(key);continue
		if actor.hp<=0:continue # the death callback must own the receipt
		if actor.position.distance_to(world.player.position)<DESPAWN_DISTANCE:continue
		if actor.attack_time>=0 or actor.interest_seconds>0.0:continue
		world.enemies.erase(actor)
		active.erase(key)
		actor.queue_free()

func _init(owner: Node3D) -> void:world=owner
func detach() -> void:
	for id in active.keys():
		var actor: Node3D=active[id]
		world.enemies.erase(actor)
		if is_instance_valid(actor):actor.queue_free()
	active.clear();sites.clear();region_id=-1
func attach(data: RefCounted,seed_text: String) -> void:
	detach();region_id=int(data.spec.id)
	sites=TerritoryPlan.build(data,seed_text)
	# Bestiário não abre um segundo spawn director. Catálogo é lido do Core.
	if world.exo_core!=null and world.exo_core.services.has_service("bestiary.catalog") and world.exo_core.services.has_service("bestiary.combat") and bool(ProjectSettings.get_setting("exo_murim/r4/fauna_enabled",true)):
		var profiles: Variant=world.exo_core.services.invoke("bestiary.catalog","list_profiles")
		if profiles is Array:sites.append_array(TerritoryPlan.build_fauna(data,seed_text,profiles,sites))
	timer=0.0
func tick(delta: float) -> void:
	if region_id<0 or not is_instance_valid(world.active_region):return
	if world.flow.lab_mode or world.trial_mode or world.flow.phase!="adventure":return
	timer-=delta
	if timer>0:return
	timer=0.8
	reap_distant()
	if world.journey.data.pending_loot.size()>=200:return
	var state: Dictionary=world.extension()
	var ecology: Dictionary=Reward.ensure(state)
	var total: int=active.size()
	for site in sites:
		if total>=MAX_ACTIVE:break
		var id: String=str(site.id)
		var record: Dictionary=Reward.territory_state(ecology,region_id,id)
		if not Reward.permitted(record,float(state.clock)):continue
		var point:=Vector3(site.p.x,site.y,site.p.y)
		var distance: float=point.distance_to(world.player.position)
		if distance<SPAWN_MIN_DISTANCE or distance>SPAWN_MAX_DISTANCE:continue
		if visible_spawn(point):continue
		var dead: Array[int]=dead_members(record)
		for member in range(int(site.group_size)):
			if total>=MAX_ACTIVE:break
			if member in dead:continue
			var instance_key: String=id+"/m%d"%member
			if active.has(instance_key):continue
			var offset:=Vector3(float(member)*1.6,0,float(member%2)*1.2)
			var spawn: Vector3=world.regional_spawn(world.active_region,point+offset)
			if not spawn.is_finite():continue
			var actual_distance: float=spawn.distance_to(world.player.position)
			if actual_distance<SPAWN_MIN_DISTANCE or actual_distance>SPAWN_MAX_DISTANCE:continue
			if visible_spawn(spawn):continue
			var instance_id: String=instance_key+"/g%04d"%int(record.generation)
			var actor: Node3D
			if bool(site.get("fauna",false)):
				var profile: Variant=world.exo_core.services.invoke("bestiary.catalog","get_profile",[str(site.species)])
				if not profile is Dictionary or profile.is_empty():continue
				actor=FaunaActor.new();world.add_child(actor)
				actor.setup_regional(world,instance_id,profile,spawn,member)
				actor.set_meta("ecology_region",region_id)
				actor.set_meta("ecology_level",int(site.danger))
			else:
				actor=Enemy.new();world.add_child(actor)
				actor.setup(world,instance_id,str(site.kind),spawn)
				var danger:int=world.activation_v4.encounter_danger(site) if world.get("activation_v4")!=null else int(site.danger)
				actor.configure_regional(float(site.radius),danger)
				if str(site.kind)=="blade":actor.set_meta("bestiary03_profile","hostile_wanderer")
			actor.set_meta("ecology_territory",id)
			actor.set_meta("ecology_member",member)
			actor.set_meta("ecology_members_total",int(site.group_size))
			actor.set_meta("ecology_active_key",instance_key)
			active[instance_key]=actor
			world.enemies.append(actor)
			total+=1
func defeated(actor: Node3D) -> int:
	var site: String=str(actor.get_meta("ecology_territory",""))
	if site.is_empty():return 0
	var ecology: Dictionary=Reward.ensure(world.extension())
	var record: Dictionary=Reward.territory_state(ecology,region_id,site)
	var member: int=int(actor.get_meta("ecology_member",-1))
	var key: String=site+"/m%d"%member
	if member<0 or str(actor.uid)!=key+"/g%04d"%int(record.generation):return 0
	var dead: Array[int]=dead_members(record)
	if member in dead:return 0
	dead.append(member);record["members_dead"]=dead
	record.kills=int(record.kills)+1
	if dead.size()>=int(actor.get_meta("ecology_members_total",1)):
		record.generation=int(record.generation)+1
		record.defeated_at=float(world.extension().clock)
		record.members_dead=[]
	active.erase(key)
	world.enemies.erase(actor)
	actor.set_meta("ecology_rewarded",true)
	var value: int=Reward.award(ecology,region_id,str(actor.kind),int(actor.get_meta("ecology_level",1)),preload("res://ai_core/world_clock.gd").day(world.extension()))
	# Removal is committed by the gameplay owner only after the atomic save succeeds.
	return value

# R6: host-authorized dungeon encounter XP uses the pre-existing ecology bank,
# day limits, region key and save domain. No second progression counter.
func award_dungeon_encounter(kind: String,level: int) -> int:
	if world==null or world.current_region<0:return 0
	if kind not in ["blade","mage","boss"]:return 0
	var state: Dictionary=world.extension()
	var ecology: Dictionary=Reward.ensure(state)
	return Reward.award(ecology,world.current_region,kind,maxi(1,level),preload("res://ai_core/world_clock.gd").day(state))
