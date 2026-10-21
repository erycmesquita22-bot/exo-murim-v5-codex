extends "res://main.gd"
const AtlasPlanner=preload("res://genesis/world_planner.gd")
const RegionalData=preload("res://genesis/region_data.gd")
const IntegratedRegion=preload("res://convergence/region.gd")
const WG5Atlas=preload("res://worldgen_v5/runtime/atlas_gate.gd")
const Resident=preload("res://npc_system04/actor.gd")
const NPCDirector=preload("res://npc_system04/director.gd")
const LivingBridge=preload("res://living_world/bridge.gd")
const LivingState=preload("res://living_world/state.gd")
const WorldClock=preload("res://ai_core/world_clock.gd")
const EcologyDirector=preload("res://regional_ecology/director.gd")
const JourneyManager=preload("res://journey_dynamic/quest_manager.gd")
const NarrativeBridge=preload("res://narrative/adapters/journey_bridge.gd")
var exo_core: RefCounted
var atlas: Dictionary={}
var active_region: Node3D
var current_region: int=-1
var changing_region:=false
var region_commit_staged:bool=false
var lifecycle_epoch: int=0
var residents: Array=[]
var npc_director: Variant
var legacy_enemies: Array=[]
var legacy_homes: Array=[]
var region_metrics: Array=[]
var generation_failure:=""
var gate_cooldown:=0.0
var travel_sign: Label3D
var legacy_shapes: Dictionary={}
var convergence_ready:=false
var npc_interactions:=0
var ecology_director: RefCounted
var journey_manager: RefCounted
const HOME_GATE=Vector3(0,.1,43)
const INSTITUTIONAL_SCENE=preload("res://exo_monumental/scenes/hall_interior.tscn")
var vfx_host_v5: RefCounted
var wg5_visit: Variant
var institutional_root: Node3D
var institutional_portal: Dictionary={}
var institutional_cooldown:float=0.0
var restoring_region:bool=false
var economy_host_v4: RefCounted
var martial_host_r8: RefCounted
func _ready() -> void:
	super._ready()
	if true:
		wg5_visit=preload("res://worldgen_v5/runtime/visit_host.gd").new(self)
		wg5_visit.name="WG5_VisitHost"
		add_child(wg5_visit)
	npc_director=NPCDirector.new(self)
	if is_instance_valid(player):player.collision_mask=player.collision_mask|8
	ecology_director=EcologyDirector.new(self)
	journey_manager=JourneyManager.new(self)
	journey_manager.state()
	journey_manager.sync_combat()
	exo_core=preload("res://exo_core/core.gd").new(self)
	if not exo_core.boot():
		generation_failure="EXO Core: "+str(exo_core.errors);push_error(generation_failure);simulation_enabled=false;return
	# R8 owner bridge: bind only when the real Martial R2 service has loaded.
	if bool(ProjectSettings.get_setting("exo_murim/r8/martial_enabled",true)):
		martial_host_r8=preload("res://convergence/martial_host_r8.gd").new()
		if not martial_host_r8.initialize(self):
			push_warning("EXO R8 martial host unavailable; enrollment stays fail-closed")
			martial_host_r8=null
	if exo_core.services.has_service("economy"):
		economy_host_v4=preload("res://convergence/economy_host_v4.gd").new()
		if not economy_host_v4.initialize(self):economy_host_v4=null
	# The original Techniques runtime remains the sole energy authority.
	_restore_r10_energy()
	legacy_enemies=enemies.duplicate()
	for actor in legacy_enemies:legacy_homes.append(actor.home)
	travel_sign=Label3D.new();travel_sign.text="ESTRADAS DOS REINOS • E\n88 regiões externas";travel_sign.position=HOME_GATE+Vector3(0,2.8,0);travel_sign.font_size=34;travel_sign.pixel_size=.012;travel_sign.billboard=BaseMaterial3D.BILLBOARD_ENABLED;add_child(travel_sign)
	activation_v4=preload("res://convergence4/activation.gd").new(self)
	activation_v4.initialize()
	bestiary_v4=preload("res://convergence4/bestiary_host.gd").new(self)
	vfx_host_v5=preload("res://convergence/vfx_host_v5.gd").new()
	if not vfx_host_v5.initialize(self):push_error("v5_vfx_host_binding_failed")
	convergence_ready=true
	if journey.data.has("convergence") and flow.phase=="adventure":call_deferred("restore_region")
var bestiary_v4:RefCounted
var activation_v4:RefCounted

func extension() -> Dictionary:
	if not journey.data.has("convergence"):
		journey.data.convergence={"schema":1,"atlas_seed":str(journey.data.world.seed),"current":-1,"position":[],"visited":{},"actors":{},"clock":900.0,"clock_rate":2,"regional_version":7,"worldgen_v4":{"schema":1,"generator":4}}
	WorldClock.migrate(journey.data.convergence)
	journey.data.convergence["architecture_version"]=2
	journey.data.convergence["regional_version"]=7
	return journey.data.convergence
func ensure_atlas() -> bool:
	var state: Dictionary=extension()
	if not atlas.is_empty() and str(atlas.seed)==str(state.atlas_seed):return preload("res://genesis/v4/world_plan.gd").valid_atlas(atlas)
	atlas=AtlasPlanner.read_atlas("res://genesis/atlas_seed_"+str(state.atlas_seed)+".json") if str(state.atlas_seed) in ["101","816204"] else AtlasPlanner.plan(str(state.atlas_seed))
	var errors: Array=AtlasPlanner.validate(atlas)
	if not errors.is_empty():generation_failure=str(errors);return false
	# Persist the full deterministic graph; subsequent sessions consume this exact atlas.
	if state.has("atlas"):
		atlas=state.atlas
	else:
		atlas=preload("res://genesis/v4/world_plan.gd").decorate(atlas,str(journey.data.world.id),exo_core)
		state.atlas=atlas.duplicate(true)
	if not preload("res://genesis/v4/world_plan.gd").valid_atlas(atlas):generation_failure="invalid_worldgen_v4_atlas";return false
	if wg5_visit!=null:
		var wg5_gate:Dictionary=WG5Atlas.validate(atlas)
		if not bool(wg5_gate.get("ok",false)):
			generation_failure="WG5 atlas gate: "+str(wg5_gate.get("errors",[]))
			return false
	return AtlasPlanner.validate(atlas).is_empty()
func legacy_active(value: bool) -> void:
	for node in region_nodes:
		if node is Node3D:node.visible=value
		var all: Array=node.find_children("*","CollisionShape3D",true,false)
		if node is CollisionShape3D:all.append(node)
		for shape in all:
			if not legacy_shapes.has(shape.get_instance_id()):legacy_shapes[shape.get_instance_id()]=shape.disabled
			shape.disabled=bool(legacy_shapes[shape.get_instance_id()]) if value else true
	npc.visible=value;encounters.visible=value;encounters.set_process(value);travel_sign.visible=value
	for actor in legacy_enemies:
		if value:
			actor.home=legacy_homes[legacy_enemies.find(actor)];actor.restore(actor.uid in journey.data.defeated)
		actor.visible=value and actor.hp>0;actor.collision_layer=4 if value and actor.hp>0 else 0
	enemies.assign(legacy_enemies if value else [])
func restore_region() -> void:
	var restore_epoch: int=lifecycle_epoch
	if not ensure_atlas():return
	var state: Dictionary=extension();var rid: int=int(state.current);var point: Array=state.position.duplicate()
	if rid>=0:
		restoring_region=true
		var opened: bool=await change_region(rid,"")
		restoring_region=false
		if not opened or not is_instance_valid(active_region):return
		var restored_region: Node3D=active_region
		# The staged region was relocated on commit. Synchronize broadphase before
		# querying any saved exterior or interior recovery anchor.
		await get_tree().physics_frame
		await get_tree().physics_frame
		if restore_epoch!=lifecycle_epoch or not is_instance_valid(restored_region) or active_region!=restored_region:return
		_restore_r10_energy()
		if point.size()==3:
			var saved:=Vector3(point[0],point[1],point[2])
			var safe: Vector3=regional_spawn(active_region,saved)
			if safe.is_finite():player.position=safe
		# Pending dungeon visits always recover to an EXTERIOR raycast+capsule
		# validated anchor before normal exploration; no interior respawn shortcut.
		_recover_dungeon_visit_after_region_load()
		_restore_institutional_after_region_load()
		if wg5_visit!=null:
			var visit:Dictionary=extension().get("worldgen_v5_visit",{})
			if bool(visit.get("inside",false)):
				if not wg5_visit.restore_saved_visit(visit):
					push_warning("WG5 saved interior invalid: safe exterior recovery; preserve original save for audit")
func snapshot_region() -> void:
	# NEVER persist interior coordinates as exterior coordinates. Also do not
	# overwrite a stored checkpoint while current_region is still the legacy boot.
	if region_commit_staged or not convergence_ready or current_region<0 or _dungeon_inside() or _institutional_inside() or (wg5_visit!=null and wg5_visit.inside()):return
	var state: Dictionary=extension()
	state.current=current_region;state.position=[player.position.x,player.position.y,player.position.z]
	for actor in residents:state.actors[actor.identity.id]=actor.snapshot(float(state.clock))
func save_progress() -> bool:
	# The legacy host deliberately skips writes in replay/laboratory mode.
	# Do not publish/commit Core events for a save that never reaches disk.
	if flow!=null and (flow.replaying or flow.lab_mode):
		return super.save_progress()
	# The rollback MUST precede all preparation; activation, region snapshots,
	# interior positions and Core event receipts can all modify journey.data.
	var previous: Dictionary=journey.data.duplicate(true)
	if convergence_ready:
		if activation_v4!=null:activation_v4.prepare_save()
		_record_institutional_save_position()
		if wg5_visit!=null:
			extension()["worldgen_v5_visit"]=wg5_visit.snapshot()
		snapshot_region()
		# Save the authoritative meter values; never infer expenditure from a lesson ticket.
		if flow!=null and flow.phase=="adventure" and is_finite(techniques.mana) and is_finite(techniques.stamina):
			extension()["r10_energy"]={"schema":1,"qi":clampf(techniques.mana,0.0,100.0),"stamina":clampf(techniques.stamina,0.0,100.0)}
	if exo_core!=null and exo_core.ready and not exo_core.prepare_save():
		journey.data=previous
		return false
	var ok: bool=super.save_progress()
	if ok and exo_core!=null and exo_core.ready:
		exo_core.committed()
	elif not ok:
		journey.data=previous
	return ok
func _restore_r10_energy() -> void:
	if journey==null or techniques==null or not journey.data.has("convergence"):return
	var energy:Variant=journey.data.convergence.get("r10_energy",{})
	if not energy is Dictionary or int(energy.get("schema",0))!=1:return
	var qi:float=float(energy.get("qi",-1));var st:float=float(energy.get("stamina",-1))
	if not is_finite(qi) or not is_finite(st) or qi<0.0 or st<0.0 or qi>100.0 or st>100.0:return
	techniques.mana=qi;techniques.stamina=st

func regional_spawn(region: Node3D,point: Vector3) -> Vector3:
	if not is_instance_valid(region) or not point.is_finite() or not is_instance_valid(player):return Vector3.INF
	var query:=PhysicsRayQueryParameters3D.create(point+region.position+Vector3(0,6,0),point+region.position-Vector3(0,12,0),1)
	var hit: Dictionary=get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():return Vector3.INF
	var result: Vector3=hit.position+Vector3(0,.06,0)
	var probe:=PhysicsShapeQueryParameters3D.new();probe.shape=player.get_child(0).shape
	probe.transform=Transform3D(Basis.IDENTITY,result+Vector3(0,.98,0));probe.collision_mask=1|4;probe.exclude=[player.get_rid()]
	if not get_world_3d().direct_space_state.intersect_shape(probe).is_empty():return Vector3.INF
	return result-region.position
func change_region(rid: int,gate_id: String="") -> bool:
	if _dungeon_inside() or _institutional_inside() or (wg5_visit!=null and wg5_visit.inside()):return false
	if changing_region or flow.phase!="adventure" or not ensure_atlas():return false
	if rid<0 or rid>=88:return false
	# Candidate construction consumes Library choices (e.g. city pavement theme).
	# Snapshot before construction, not just before staging travel/save events.
	var before_travel:Dictionary=journey.data.duplicate(true)
	changing_region=true;simulation_enabled=false
	var started:=Time.get_ticks_usec()
	var monument_storage:Dictionary=extension().get("monumental_r7",{})
	var pinned:Dictionary=monument_storage.get("regions",{}).get(str(rid),{})
	if pinned.is_empty() and bool(extension().get("visited",{}).get(str(rid),false)):
		# Historic campaigns are pinned: never retroactively introduce new monuments.
		pinned={"mode":"legacy","schema":1,"plans":[],"receipts":[]}
	var data:=RegionalData.new(atlas,rid,pinned)
	var errors: Array=data.validate()
	if not errors.is_empty():
		journey.data=before_travel
		generation_failure=str(errors);message("Falha de geração: "+generation_failure);changing_region=false;simulation_enabled=true;return false
	var candidate:=IntegratedRegion.new();add_child(candidate);candidate.visible=false
	# Historic visits are never repopulated or visually upgraded without an explicit migration.
	var old_visit:bool=bool(extension().get("visited",{}).get(str(rid),false))
	var permitted:Array=[]
	for persisted in journey.data.get("living_world",{}).get("npcs",{}).values():
		if persisted is Dictionary and int(persisted.get("region_id",-1))==rid and str(persisted.get("role",""))=="master":
			var known:String=str(persisted.get("martial_site_id",""))
			if not known.is_empty() and known not in permitted:permitted.append(known)
	candidate.set_meta("r9_existing_visit",old_visit)
	candidate.set_meta("r9_existing_school_sites",permitted)
	candidate.set_meta("world_v4",self)
	candidate.build(data,range(88))
	candidate.integrate_perimeter()
	candidate.position=Vector3(2048,0,0)
	if not candidate.build_errors.is_empty():
		journey.data=before_travel
		generation_failure=str(candidate.build_errors);candidate.free();message("Construção recusada: "+generation_failure);changing_region=false;simulation_enabled=true;return false
	await get_tree().physics_frame
	await get_tree().physics_frame
	var desired:=Vector3(0,data.center_h+.08,0)
	if gate_id.is_empty() and candidate.has_meta("worldgen_v5_plan"):
		var city_plan: Dictionary=candidate.get_meta("worldgen_v5_plan")
		for building in city_plan.get("buildings",[]):
			if str(building.function) in ["inn","market"]:
				var anchor: Array=building.return_anchor
				desired=Vector3(anchor[0],anchor[1],anchor[2])+Vector3(0,.08,0)
				break
	for gate in data.gates:
		if gate.id==gate_id:
			var p: Vector2=data.handoff_point(gate)-gate.p.normalized()*10
			desired=Vector3(p.x,data.height_at(p)+.08,p.y)
	var spawn: Vector3=regional_spawn(candidate,desired)
	if not spawn.is_finite():journey.data=before_travel;candidate.free();generation_failure="arrival_blocked";message("Chegada bloqueada; região anterior preservada.");changing_region=false;simulation_enabled=true;return false
	preload("res://convergence4/interiors.gd").verify(candidate)
	if data.worldgen_v4:candidate.set_meta("wg4_landmark_verification",preload("res://genesis/v4/landmarks.gd").verify(candidate))
	candidate.prepare_population()
	if not candidate.build_errors.is_empty():
		journey.data=before_travel
		generation_failure=str(candidate.build_errors);candidate.free();changing_region=false;simulation_enabled=true;return false
	var people: Array=[]
	if not candidate.assigned_slots.is_empty():
		var result: Dictionary=LivingBridge.record_roster(journey,data.spec,candidate.assigned_slots,str(atlas.seed),false)
		if not result.ok:journey.data=before_travel;candidate.free();generation_failure=str(result);changing_region=false;simulation_enabled=true;return false
		people=result.npcs
		for person in people:
			for lot in data.lots:
				if lot.id==person.work_slot:
					person["occupation"]=lot.function;person["service"]=preload("res://convergence/occupancy.gd").SERVICES.get(lot.function,"convivência")
	if candidate.has_meta("worldgen_v5_service"):
		var settlement: Variant=candidate.get_meta("worldgen_v5_service")
		if not settlement.bind_roster(people):
			journey.data=before_travel;candidate.free();generation_failure="settlement_roster_contract";changing_region=false;simulation_enabled=true;return false
	# Keep the old scene and all actors until the sole save authority commits.
	snapshot_region()
	# Pin the accepted zoning result on the same authorized JourneySave write.
	var mstate:Dictionary=extension().get("monumental_r7",{"schema":1,"regions":{},"active_interior":{}})
	if not mstate.regions.has(str(rid)):
		mstate.regions[str(rid)]={"mode":data.monumental_mode if data.monumental_mode!="none" else "legacy","schema":1,
			"plans":data.monumental_plans.duplicate(true),"receipts":data.monumental_receipts.duplicate(true),"rejections":data.monumental_rejections.duplicate(true)}
	extension()["monumental_r7"]=mstate
	extension().visited[str(rid)]=true
	extension().current=rid;extension().position=[spawn.x,spawn.y,spawn.z]
	var event_ok:bool=true
	if exo_core!=null:
		if current_region>=0:event_ok=bool(exo_core.publish("region_exited","exit/%02d/"%current_region+str(journey.data.exo_core.sequence),{},current_region).get("ok",false))
		if event_ok:event_ok=bool(exo_core.publish("region_entered","travel/region/%02d/"%rid+str(journey.data.exo_core.sequence),{},rid).get("ok",false))
	region_commit_staged=true
	var saved:bool=event_ok and (restoring_region or save_progress())
	region_commit_staged=false
	if not saved:
		journey.data=before_travel
		journey_manager.sync_combat()
		candidate.free()
		generation_failure="save_failed" if event_ok else "region_event_failed"
		changing_region=false;simulation_enabled=true
		message("Viagem cancelada: não foi possível confirmar o progresso. A região anterior foi preservada.")
		return false
	if exo_core!=null and exo_core.services.has_service("crowd.illusion"):exo_core.services.invoke("crowd.illusion","detach")
	if ecology_director!=null:ecology_director.detach()
	for actor in residents:actor.free()
	residents.clear()
	if is_instance_valid(active_region):active_region.free()
	legacy_active(false)
	active_region=candidate;active_region.position=Vector3.ZERO;active_region.visible=true;current_region=rid
	if wg5_visit!=null:wg5_visit.attach_region(active_region)
	# Visual only: do not replan the region or alter collision/navigation.
	if graphics!=null:graphics.apply()
	resident_roof_occluders.clear();resident_visibility_clock=0.0
	for holder in candidate.props:
		var roof: Node3D=holder.get_node_or_null("StaticRoofVisual")
		if roof is MeshInstance3D:resident_roof_occluders.append(roof)
	player.position=spawn;player.velocity=Vector3.ZERO;pending_ground_check=false;spawn_recovery_done=true
	activate_regional_encounter(data)
	ecology_director.attach(data,str(atlas.seed))
	inventory.rebuild_drops()
	for person in people:
		var actor:=Resident.new();add_child(actor)
		actor.setup(person,candidate.route_points[person.home_slot],extension().actors.get(person.id,{}),candidate.resident_routes(person,people),float(extension().clock),str(atlas.seed));residents.append(actor)
	active_region.set_meta("npc04_bound",residents.all(func(a):return a.setup_error.is_empty()))
	# C3 physical host approves only sampled materialized lanes, after save commit.
	if bool(ProjectSettings.get_setting("exo_murim/crowd/enable",false)) and exo_core.services.has_service("crowd.illusion"):
		await get_tree().physics_frame
		await get_tree().physics_frame
		preload("res://exo_crowd_illusion/visuals/shared_npc_skins.gd").capture(active_region,residents)
		var geometry:Dictionary=preload("res://convergence/crowd_geometry_v4.gd").authorize(active_region)
		active_region.set_meta("v4_crowd_check",geometry)
		if bool(geometry.get("ok",false)):
			active_region.set_meta("v4_crowd_attach",exo_core.services.invoke("crowd.illusion","attach_region",[active_region]))
	if exo_core.services.has_service("content.library"):
		var library_context:Dictionary={"world_id":str(journey.data.world.id),"seed":journey.data.world.seed,"region_id":rid,"biome":str(data.spec.get("biome","grassland")),"flags":[],"tags":[],"player_tier":1}
		active_region.set_meta("v4_npc_authorial_proposal",exo_core.services.invoke("content.library","preview",["living_world",library_context,["npc_archetype","npc_motivation","personality","social_custom"]]))
	if activation_v4!=null:
		if active_region.has_meta("library_material_consumed"):activation_v4.record_use(active_region.get_meta("library_material_consumed"),"city_pavement_material")
		activation_v4.apply_npc_content()
	# NPC Director updates nearby residents spatially instead of global O(N^2).
	if graphics!=null:graphics.apply()
	gate_cooldown=1.0;generation_failure="";changing_region=false;simulation_enabled=true
	region_metrics.append({"rid":rid,"seed":str(atlas.seed),"generation_ms":(Time.get_ticks_usec()-started)/1000.0,"scene_ms":candidate.build_ms,"houses":candidate.props.size(),"npcs":residents.size()})
	update_camera();message("Região %02d • %s • %d construções"%[rid,region_title(data.spec),candidate.props.size()])
	return true
func return_home() -> void:
	if wg5_visit!=null and wg5_visit.inside():return
	if changing_region or _institutional_inside():return
	snapshot_region()
	if exo_core!=null and current_region>=0:
		exo_core.publish("region_exited","exit/%02d/"%current_region+str(journey.data.exo_core.sequence),{},current_region)
	if exo_core!=null and exo_core.services.has_service("crowd.illusion"):exo_core.services.invoke("crowd.illusion","detach")
	if ecology_director!=null:ecology_director.detach()
	for actor in residents:actor.free()
	residents.clear()
	if is_instance_valid(active_region):active_region.free()
	active_region=null;resident_roof_occluders.clear();current_region=-1;legacy_active(true);inventory.rebuild_drops();prepare_player_spawn(HOME_GATE+Vector3(0,0,-2));save_progress();gate_cooldown=1.0
var resident_visibility_clock:=0.0
var resident_roof_occluders: Array=[]
func _physics_process(delta: float) -> void:
	if changing_region:return
	super._physics_process(delta)
	if wg5_visit!=null and wg5_visit.inside():
		autosave_time+=delta
		if autosave_time>20.0:
			autosave_time=0.0
			save_progress()
		return
	if graphics!=null:graphics.tick(delta)
	if not convergence_ready or flow.phase!="adventure":return
	if activation_v4!=null:activation_v4.tick(delta)
	gate_cooldown=maxf(0,gate_cooldown-delta)
	institutional_cooldown=maxf(0.0,institutional_cooldown-delta)
	if _institutional_inside():
		# Prepared Interior Forge roots live under a translated/rotated region.
		# Using root.position (parent-local) as a player world position is wrong.
		if player.global_position.y < institutional_root.global_position.y - 12.0:
			push_warning("R7 interior fall recovered to authored entrance")
			var local_entry:Array=institutional_portal.get("interior_entry_local",[0.0,0.4,4.7])
			player.global_position=institutional_root.to_global(Vector3(float(local_entry[0]),float(local_entry[1]),float(local_entry[2])))
			player.velocity=Vector3.ZERO
		# Interior visits must autosave like exterior and dungeon exploration;
		# the visit-specific recorder validates the position before persisting.
		autosave_time+=delta
		if autosave_time>20.0:
			autosave_time=0.0
			save_progress()
		return
	if _dungeon_inside():
		if exo_core!=null:exo_core.services.invoke("dungeons","tick_active",[delta])
		autosave_time+=delta
		if autosave_time>20:
			autosave_time=0
			save_progress()
		return
	if current_region>=0:
		WorldClock.advance(extension(),delta)
		if journey_manager!=null:journey_manager.on_near_ruin()
		var hour: int=WorldClock.hour(extension())
		if exo_core.services.has_service("crowd.illusion"):exo_core.services.invoke("crowd.illusion","set_hour",[hour])
		if ecology_director!=null:ecology_director.tick(delta)
		resident_visibility_clock-=delta
		if resident_visibility_clock<=0:
			resident_visibility_clock=.12
			for actor in residents:actor.presentation_visible=resident_is_visible(actor)
		if npc_director!=null:npc_director.tick(delta,residents,float(extension().clock))
		if martial_host_r8!=null:martial_host_r8.tick_training(delta)
		update_resident_labels()
		for holder in active_region.props:
			var house: Node=holder.get_child(0)
			var roof: Node3D=house.get_node_or_null("StaticRoofVisual")
			if roof!=null:
				var local: Vector3=house.to_local(player.position)
				roof.visible=not (absf(local.x)<5 and absf(local.z)<3)
		beacon.hide()
		autosave_time+=delta
		if autosave_time>20:
			autosave_time=0
			NarrativeBridge.advance(self)
			save_progress()
func resident_is_visible(actor: Node3D) -> bool:
	# Whole-body visibility: physics walls plus the real batched roof bounds.
	# Roofs deliberately have no gameplay collider, so physics-only rays miss them.
	if actor.sheltered:return false
	if actor.can_interact(player.global_position,3.0):return true
	for height in [.4,1.2,1.8]:
		var target: Vector3=actor.global_position+Vector3.UP*height
		if not camera.is_position_in_frustum(target):return false
		var pixel: Vector2=camera.unproject_position(target)
		var origin: Vector3=camera.project_ray_origin(pixel)
		var ray:=PhysicsRayQueryParameters3D.create(origin,target,1|4)
		if not get_world_3d().direct_space_state.intersect_ray(ray).is_empty():return false
		for roof in resident_roof_occluders:
			if is_instance_valid(roof) and roof.visible and roof.get_aabb().intersects_segment(roof.to_local(origin),roof.to_local(target))!=null:return false
	return true

func update_resident_labels() -> void:
	# Show useful names without stacking 2D billboards above nearby residents.
	# The nearest label takes priority; hidden nameplates never disable interaction.
	var sorted: Array=residents.duplicate()
	sorted.sort_custom(func(a,b):return a.position.distance_squared_to(player.position)<b.position.distance_squared_to(player.position))
	var shown: Array[Vector2]=[]
	for actor in sorted:
		actor.caption.visible=false
		if not actor.rig.visible or actor.position.distance_squared_to(player.position)>64.0:continue
		var anchor: Vector3=actor.caption.global_position
		if camera.is_position_behind(anchor):continue
		var projected: Vector2=camera.unproject_position(anchor)
		var collision:=false
		for seen in shown:
			# Rough visible label footprint in pixels; conservative for longer names.
			if absf(projected.x-seen.x)<102.0 and absf(projected.y-seen.y)<29.0:
				collision=true;break
		if collision:continue
		actor.caption.visible=true;shown.append(projected)

func interact() -> void:
	if not convergence_ready or flow.phase!="adventure" or flow.lab_mode:
		super.interact();return
	if get_tree().paused or not player.is_on_floor() or attack_time>=0 or roll_time>=0 or techniques.busy() or interaction_cooldown>0:return
	if gate_cooldown>0:return
	if wg5_visit!=null and wg5_visit.inside():
		if wg5_visit.try_interact():interaction_cooldown=.5
		return
	if _institutional_inside():
		if not _near_institutional_exit():return
		interaction_cooldown=.5
		if institutional_cooldown<=0.0:
			var result:Dictionary=_exit_institutional_interior()
			if not bool(result.get("ok",false)):message("Saída bloqueada: "+str(result.get("code","unknown")))
		return
	if current_region<0:
		if player.position.distance_to(HOME_GATE)<4:
			if combat_timer>0:message("Afaste-se do combate antes de viajar.");return
			change_region(86 if str(extension().atlas_seed)=="101" else starting_region());return
		super.interact();return
	interaction_cooldown=.5
	if wg5_visit!=null and wg5_visit.inside():
		wg5_visit.try_interact()
		return
	if _dungeon_inside():
		var interaction: Variant=exo_core.services.invoke("dungeons","interact_active") if exo_core!=null else null
		if interaction is Dictionary and bool(interaction.get("ok",false)):
			message("Exploração: "+str(interaction.get("action","ação concluída")))
		return
	var institutional:Dictionary=_near_institutional_portal()
	if not institutional.is_empty():
		var enter:Dictionary=_enter_institutional_interior(institutional)
		message("Interior institucional" if bool(enter.get("ok",false)) else "Entrada bloqueada: "+str(enter.get("code","unknown")))
		return
	if wg5_visit!=null and _near_resident(2.0)==null and wg5_visit.try_interact():return
	var dungeon_entrance: Dictionary=_near_dungeon_entrance()
	if not dungeon_entrance.is_empty():
		var entry: Variant=exo_core.services.invoke("dungeons","enter_instance",[dungeon_entrance.descriptor,dungeon_entrance.anchor]) if exo_core!=null else null
		if entry is Dictionary and bool(entry.get("ok",false)):
			message("Masmorra: explore e pressione E nos pontos de interação.")
		else:message("Entrada indisponível: "+str(entry.get("error","serviço não disponível") if entry is Dictionary else "serviço ausente"))
		return
	var drop: String=inventory.nearby_drop()
	if not drop.is_empty():inventory.collect(drop);return
	if _worldgen_landmark_interact():return
	if martial_host_r8!=null and martial_host_r8.handle_training_station():return
	var interaction_order: Array=residents.duplicate()
	interaction_order.sort_custom(func(a,b):return a.position.distance_squared_to(player.position)<b.position.distance_squared_to(player.position))
	for actor in interaction_order:
		if actor.can_interact(player.global_position,3.0):
			if exo_core!=null:
				var delivery: Dictionary=exo_core.publish("npc_interacted","talk/"+str(actor.identity.id)+"/"+str(journey.data.exo_core.sequence),{"npc_id":str(actor.identity.id)})
				if not bool(delivery.get("ok",false)):
					message("Interação não confirmada pelo Core.");return
			actor.paused_for_talk=4;actor.talks+=1;npc_interactions+=1
			if not save_progress():
				actor.talks-=1;npc_interactions-=1
				message("Não foi possível salvar a interação.");return
			# Real master NPC physically accessible at a real, reserved Monumental station.
			if martial_host_r8!=null and martial_host_r8.handle_master_interaction(actor):
				return
			if economy_host_v4!=null and economy_host_v4.handle_interaction(actor):return
			actor.rig.rotation.y=atan2(actor.position.x-player.position.x,actor.position.z-player.position.z)
			var offers_text: String=""
			if journey_manager!=null:
				var offers: Array=journey_manager.options(actor.identity)
				if not offers.is_empty():offers_text="\n\nContratos disponíveis: %d. Abra P > MISSÕES próximo a este morador."%offers.size()
			var social: Dictionary=NarrativeBridge.context_for(journey.data,atlas,str(actor.identity.id),float(extension().get("clock",0.0))) if not atlas.is_empty() else {}
			if bool(social.get("attacked",false)):offers_text+="\nO morador reconhece sua hostilidade."
			elif bool(social.get("helped",false)):offers_text+="\nO morador recorda sua ajuda."
			ui.dialogue(str(actor.identity.display_name),"%s • nível %d\n%s%s"%[role_title(str(actor.identity.role)),int(actor.identity.level),npc_activity_label(actor.activity_name),offers_text+activation_v4.npc_dialogue(actor)])
			save_progress();return
	for gate in active_region.gate_nodes:
		if player.position.distance_to(gate.point)<8:change_region(int(gate.contract.neighbor),str(gate.contract.id));return
	# Old initial enclosure is not accessible through gameplay. Travel uses real regional gates.
	if player.position.distance_to(Vector3(0,active_region.data.center_h,6))<4:
		message("Para viajar, siga as trilhas até as passagens regionais.");return
func _begin_new_procedural_campaign() -> void:
	# Deferred from the character creator after closing the UI. All journey
	# records were saved before this callback, which cannot spawn in the old camp.
	if not convergence_ready or flow.phase!="adventure":
		generation_failure="procedural_start_not_ready"
		message("Mundo procedural indisponível: confira os logs de inicialização.")
		return
	var target_region: int=starting_region()
	var ready: bool=await change_region(target_region,"")
	if not ready:
		push_error("EXO Convergence 03: failed procedural first region " + str(target_region) + " / " + generation_failure)
		message("Falha ao iniciar mundo procedural. Não foi realizado retorno automático à vila antiga.")


# Institutional halls use the existing Convergence/EXO JourneySave, never Dungeon authority.
func _institutional_inside() -> bool:
	return is_instance_valid(institutional_root)

func _near_institutional_portal() -> Dictionary:
	if not bool(ProjectSettings.get_setting("exo_murim/r7/institutional_interiors_enabled",true)):return {}
	if current_region<0 or not is_instance_valid(active_region) or not is_instance_valid(player) or _institutional_inside() or _dungeon_inside():return {}
	for portal in active_region.monument_portals:
		var at:Vector3=portal.get("entrance_world",Vector3.INF)
		if at.is_finite() and player.position.distance_to(at)<3.7:return portal
	return {}

# Only the interior's authored return marker can authorize a voluntary exit.
# Fatal recovery bypasses the proximity test without bypassing save/rollback.
func _near_institutional_exit() -> bool:
	if not _institutional_inside() or not is_instance_valid(player):
		return false
	var anchor_name: String = "InteriorReturn"
	var anchor: Node3D = institutional_root.get_node_or_null(anchor_name) as Node3D
	if not is_instance_valid(anchor):
		return false
	var delta: Vector3 = player.global_position - anchor.global_position
	return delta.is_finite() and absf(delta.y) <= 2.2 and Vector2(delta.x, delta.z).length() <= 2.2

func _record_institutional_save_position() -> void:
	if not _institutional_inside() or not is_instance_valid(player) or not player.global_position.is_finite():
		return
	var state: Dictionary = extension().get("monumental_r7", {})
	var visit: Dictionary = state.get("active_interior", {})
	if int(visit.get("region_id", -1)) != current_region or str(visit.get("persistent_id", "")) != str(institutional_portal.get("persistent_id", "")):
		return
	var relative: Vector3 = institutional_root.to_local(player.global_position)
	if not relative.is_finite() or absf(relative.x) > 36.0 or absf(relative.z) > 36.0 or relative.y < -2.0 or relative.y > 12.0:
		return
	visit["interior_position"] = [player.global_position.x, player.global_position.y, player.global_position.z]
	state["active_interior"] = visit
	extension()["monumental_r7"] = state

func _institutional_cleanup() -> void:
	if is_instance_valid(institutional_root):
		institutional_root.queue_free()
	institutional_root=null
	institutional_portal={}

func _enter_institutional_interior(portal:Dictionary,restoring:bool=false) -> Dictionary:
	if _institutional_inside() or _dungeon_inside() or current_region<0:return {"ok":false,"code":"another_visit_active"}
	if int(portal.get("region_id",-1))!=current_region:return {"ok":false,"code":"wrong_region"}
	var arrival:Vector3=portal.get("entrance_world",Vector3.INF)
	if not restoring and (not arrival.is_finite() or player.position.distance_to(arrival)>3.7):return {"ok":false,"code":"door_unreachable"}
	var before_data:Dictionary=journey.data.duplicate(true)
	var outside:Vector3=player.position
	snapshot_region()
	var hall:Node3D
	hall=INSTITUTIONAL_SCENE.instantiate()
	hall.set("interior_id",str(portal.get("interior_id","martial_hall")))
	hall.set("parent_site_id",str(portal.get("site_id","")))
	hall.position=Vector3(1080.0,32.0,0.0);add_child(hall)
	if not is_instance_valid(hall):journey.data=before_data;return {"ok":false,"code":"scene_invalid"}
	institutional_root=hall
	institutional_portal=portal.duplicate(true)
	var local_entry:Array=portal.get("interior_entry_local",[0.0,0.4,4.7])
	player.global_position=hall.to_global(Vector3(float(local_entry[0]),float(local_entry[1]),float(local_entry[2])))
	player.velocity=Vector3.ZERO
	institutional_cooldown=0.8
	var m:Dictionary=extension().get("monumental_r7",{"schema":1,"regions":{},"active_interior":{}})
	m["active_interior"]={"region_id":current_region,"persistent_id":str(portal.persistent_id),
		"outside_position":[outside.x,outside.y,outside.z],"interior_position":[player.position.x,player.position.y,player.position.z]}
	extension()["monumental_r7"]=m
	if not restoring and not save_progress():
		_institutional_cleanup();player.position=outside;player.velocity=Vector3.ZERO;journey.data=before_data
		return {"ok":false,"code":"save_entry_failed"}
	autosave_time=0.0
	return {"ok":true,"persistent_id":str(portal.persistent_id)}

func _exit_institutional_interior(force_recovery: bool = false) -> Dictionary:
	if not _institutional_inside():return {"ok":false,"code":"no_interior"}
	if not force_recovery and not _near_institutional_exit():return {"ok":false,"code":"not_at_exit"}
	var exterior:Vector3=institutional_portal.get("return_world",Vector3.INF)
	if not exterior.is_finite():return {"ok":false,"code":"no_return"}
	var safe:Vector3=regional_spawn(active_region,exterior)
	if not safe.is_finite():return {"ok":false,"code":"return_collision"}
	var before_data:Dictionary=journey.data.duplicate(true)
	var before_position:Vector3=player.position
	var m:Dictionary=extension().get("monumental_r7",{})
	m["active_interior"]={}
	extension()["monumental_r7"]=m
	# Exterior checkpoint is staged explicitly because _institutional_inside keeps
	# normal snapshot_region() from copying arbitrary interior coordinates.
	extension()["position"]=[safe.x,safe.y,safe.z]
	if not save_progress():
		journey.data=before_data;player.position=before_position
		return {"ok":false,"code":"save_return_failed"}
	_institutional_cleanup()
	player.position=safe;player.velocity=Vector3.ZERO
	institutional_cooldown=0.8
	return {"ok":true}

func _restore_institutional_after_region_load() -> void:
	var m:Dictionary=extension().get("monumental_r7",{})
	var visit:Dictionary=m.get("active_interior",{}).duplicate(true)
	if visit.is_empty() or int(visit.get("region_id",-1))!=current_region:return
	for portal in active_region.monument_portals:
		if str(portal.get("persistent_id",""))==str(visit.get("persistent_id","")):
			var outcome:Dictionary=_enter_institutional_interior(portal,true)
			if bool(outcome.get("ok",false)):
				# Recover the last saved location only inside the same authorized
				# interior and only with a clear capsule. Otherwise use safe spawn.
				var coords:Variant=visit.get("interior_position",[])
				if coords is Array and coords.size()==3:
					var saved:Vector3=Vector3(float(coords[0]),float(coords[1]),float(coords[2]))
					var local:Vector3=institutional_root.to_local(saved)
					if saved.is_finite() and local.is_finite() and absf(local.x)<=36.0 and absf(local.z)<=36.0 and local.y>=-2.0 and local.y<=12.0:
						if preload("res://convergence4/interiors.gd").clear_capsule(get_world_3d().direct_space_state,saved):
							player.global_position=saved
							player.velocity=Vector3.ZERO
				return
			break
	push_error("R7 institutional recovery refused: portal absent, exterior saved checkpoint retained")

# Convergência 03 — WorldGen-to-Dungeon host, no secondary map/save/inventory.
func _dungeon_inside() -> bool:
	if exo_core==null or not exo_core.ready or not exo_core.services.has_service("dungeons"):return false
	var state: Variant=exo_core.services.invoke("dungeons","active_status")
	return state is Dictionary and bool(state.get("active",false))

func _near_dungeon_entrance() -> Dictionary:
	if current_region<0 or not is_instance_valid(active_region) or not is_instance_valid(player):return {}
	if exo_core==null or not exo_core.services.has_service("dungeons"):return {}
	if str(active_region.data.spec.kind)!="dungeon_approach":return {}
	for holder in active_region.props:
		if not is_instance_valid(holder) or not holder.has_meta("exo_dungeon_location_id"):continue
		var anchor: Vector3=holder.to_global(Vector3(0.0,1.2,3.0))
		if player.global_position.distance_to(anchor)>4.0:continue
		var location: String=str(holder.get_meta("exo_dungeon_location_id",""))
		if location.is_empty():continue
		var world_data: Dictionary=journey.data.get("world",{})
		return {"anchor":anchor,"descriptor":{"world_id":str(world_data.get("id","")),"world_seed":str(world_data.get("seed","")),"region_id":current_region,"location_id":location,"family":"cavern","generator_version":4,"floors":1,"rooms_per_floor":10,"difficulty":1}}
	return {}

func _recover_dungeon_visit_after_region_load() -> void:
	if exo_core==null or not exo_core.services.has_service("dungeons") or not is_instance_valid(active_region):return
	var visit: Variant=exo_core.services.invoke("dungeons","recover_visit_context")
	if not visit is Dictionary or visit.is_empty():return
	if int(visit.get("region_id",-1))!=current_region:return
	var raw: Variant=visit.get("entrance_anchor",visit.get("outside_position",[]))
	if not raw is Array or raw.size()!=3:return
	var expected: Vector3=Vector3(float(raw[0]),float(raw[1]),float(raw[2]))
	var safe: Vector3=regional_spawn(active_region,expected)
	if not safe.is_finite():
		push_error("Dungeon recovery blocked: WorldGenesis failed exterior ray+capsule check")
		return
	var result: Variant=exo_core.services.invoke("dungeons","recover_to_exterior",[safe,current_region,str(visit.get("location_id",""))])
	if not result is Dictionary or not bool(result.get("ok",false)):
		push_error("Dungeon recovery failed: "+str(result))

func starting_region() -> int:
	if not ensure_atlas():return 0
	for spec in atlas.regions:
		if spec.kind=="settlement" and spec.settlement_scale=="village":return int(spec.id)
	return 0
func interaction_hint() -> String:
	if wg5_visit!=null and wg5_visit.inside():return wg5_visit.interaction_hint()
	if _institutional_inside():return "E • Sair do interior" if _near_institutional_exit() else ""
	if not _near_institutional_portal().is_empty():return "E • Entrar no edifício"
	var nearby: Node3D=_near_resident(2.0)
	if nearby!=null:return "E • Conversar com "+str(nearby.identity.display_name)
	if wg5_visit!=null:
		var door_hint:String=wg5_visit.interaction_hint()
		if not door_hint.is_empty():return door_hint
	if _dungeon_inside():
		var hint: Variant=exo_core.services.invoke("dungeons","interaction_hint")
		return str(hint) if hint!=null else "Explore o interior"
	if not _near_dungeon_entrance().is_empty():return "E • Entrar na masmorra"
	if current_region<0:
		if convergence_ready and flow.phase=="adventure" and player.position.distance_to(HOME_GATE)<4:return "E • Explorar as 88 regiões"
		return super.interaction_hint()
	for point in active_region.get_meta("wg4_landmarks",[]):
		if point.get("approved",false) and player.position.distance_to(point.point)<2.8:return "E • Examinar "+str(point.title)
	for actor in residents:
		if actor.can_interact(player.global_position,3.0):return "E • Conversar com "+str(actor.identity.display_name)
	for gate in active_region.gate_nodes:
		if player.position.distance_to(gate.point)<8:return "E • Viajar para região %02d"%int(gate.contract.neighbor)
	return ""
func update_quest(delta: float) -> void:
	if current_region<0:super.update_quest(delta)
func rescue_from_missing_adventure_floor(delta: float) -> void:
	if current_region<0:super.rescue_from_missing_adventure_floor(delta)
func is_safe(point: Vector3) -> bool:
	if current_region>=0:return active_region.data.spec.kind=="settlement"
	return super.is_safe(point)
func new_journey() -> void:
	if changing_region:return
	lifecycle_epoch+=1
	if wg5_visit!=null and wg5_visit.inside():
		message("Saia do edifício antes de iniciar outra jornada.");return
	if _institutional_inside():_institutional_cleanup()
	if exo_core!=null:exo_core.shutdown()
	if ecology_director!=null:ecology_director.detach()
	for actor in residents:actor.free()
	residents.clear()
	if is_instance_valid(active_region):active_region.free()
	active_region=null;current_region=-1
	if wg5_visit!=null:wg5_visit.detach()
	atlas.clear();convergence_ready=false;exo_core=null
	super.new_journey()
	journey_manager=JourneyManager.new(self);journey_manager.state()
	npc_director=NPCDirector.new(self)
	ecology_director=EcologyDirector.new(self)
	exo_core=preload("res://exo_core/core.gd").new(self)
	if not exo_core.boot():
		generation_failure="new_campaign_core:"+str(exo_core.errors)
		simulation_enabled=false;push_error(generation_failure);return
	economy_host_v4=preload("res://convergence/economy_host_v4.gd").new()
	if not economy_host_v4.initialize(self):
		generation_failure="new_campaign_economy_host";push_error(generation_failure);return
	martial_host_r8=preload("res://convergence/martial_host_r8.gd").new()
	if not martial_host_r8.initialize(self):
		generation_failure="new_campaign_martial_host";push_error(generation_failure);return
	activation_v4=preload("res://convergence4/activation.gd").new(self);activation_v4.initialize()
	bestiary_v4=preload("res://convergence4/bestiary_host.gd").new(self)
	vfx_host_v5=preload("res://convergence/vfx_host_v5.gd").new()
	if not vfx_host_v5.initialize(self):push_error("v5_vfx_host_binding_failed")
	convergence_ready=true
	if not save_progress():push_error("new_campaign_save_failed")

# The player's fatal damage interrupts the current visit and restores the
# exterior; the combat module remains owner of HP/death/pause and the Core
# remains owner of checkpoint persistence.
func on_fatal_dungeon_damage() -> void:
	if wg5_visit!=null and wg5_visit.inside():
		if not wg5_visit.interrupt("death"):push_error("settlement_death_recovery_failed")
		return
	if _institutional_inside():
		var result_inside:Dictionary=_exit_institutional_interior(true)
		if not bool(result_inside.get("ok",false)):
			push_error("R7 institutional death recovery blocked: "+str(result_inside))
		return
	if not _dungeon_inside():return
	var result: Variant=exo_core.services.invoke("dungeons","interrupt_active_visit",["death"])
	if result!=true:push_error("C03 R6: death checkpoint failed; pending recovery must remain")

# Reuse the six established campaign opponents and their existing unique loot
# identities. There are no extra enemy types or duplicate rewards.
func activate_regional_encounter(data: RefCounted) -> void:
	if data.spec.kind not in ["wild","ruins"]:return
	var selected: Array=[]
	for spec in atlas.regions:
		if spec.kind==data.spec.kind:selected.append(int(spec.id))
	var target_id: int=selected[0] if not selected.is_empty() else -1
	if str(atlas.seed)=="101" and data.spec.kind=="ruins":target_id=32
	if int(data.spec.id)!=target_id:return
	var indexes: Array=[0,1] if data.spec.kind=="wild" else [2,3,4,5]
	for k in range(indexes.size()):
		var actor: Node3D=legacy_enemies[indexes[k]]
		var p:=Vector2(-4.0+float(k)*3, -22.0)
		actor.home=Vector3(p.x,data.height_at(p)+.05,p.y);actor.restore(actor.uid in journey.data.defeated)
		actor.enabled=true;enemies.append(actor)
# Reuse the current loot generator. A separate, saved ecology generation counter
# prevents repeated XP/loot from the same death, without changing legacy IDs.
# R6: route dungeon deaths to the SAME combat actor / Core dungeon authority.
# Dungeon enemies are members of the official world.enemies collection.
func _dungeon_enemy_defeated(actor: Node3D) -> bool:
	if not actor.has_meta("exo_dungeon_id"):return false
	if exo_core==null or not exo_core.services.has_service("dungeons"):
		actor.hp=1;actor.visible=true;actor.collision_layer=4
		push_error("C03 R6 dungeon actor without official dungeon service")
		return true
	var outcome: Variant=exo_core.services.invoke("dungeons","defeat_encounter",[actor])
	if not outcome is Dictionary or not bool(outcome.get("ok",false)):
		actor.hp=1;actor.visible=true;actor.collision_layer=4;actor.cooldown=3.0
		message("Derrota da dungeon não registrada; inimigo recuperado.")
	else:
		message("Encontro concluído • +%d XP"%int(outcome.get("xp",0)))
	return true

func enemy_defeated(actor: Node3D) -> void:
	if _dungeon_enemy_defeated(actor):return
	if actor.has_meta("ecology_territory"):
		if not actor.get_meta("ecology_rewarded",false):
			var before: Dictionary=journey.data.duplicate(true)
			# Remove only obsolete *collected* ecological event receipts;
			# the generation counter in convergence.ecology is authoritative.
			var reward_logic=preload("res://regional_ecology/rewards.gd")
			if journey.data.world.events.size()>1800:reward_logic.compact_claimed(journey.data,1500)
			if not reward_logic.queue_loot(self,actor):
				# Never record a fatal encounter as rewarded without its pending loot.
				# Keep the actor valid and defer the defeat until inventory pressure
				# is resolved. This is a guard for corrupted/full external saves.
				actor.hp=1
				actor.visible=true
				actor.collision_layer=4
				actor.cooldown=3.0
				if actor.has_method("revive_after_failed_commit"):actor.revive_after_failed_commit()
				message("Recolha os saques pendentes antes de continuar.")
				return
			if exo_core!=null:
				var event: Dictionary=exo_core.publish("enemy_defeated","kill/"+str(actor.uid),{"enemy_uid":str(actor.uid),"territory":str(actor.get_meta("ecology_territory",""))})
				if not event.ok:
					restore_failed_death(actor,before);generation_failure=str(event);message("Evento de combate recusado: "+str(event.reason));return
			var gained: int=ecology_director.defeated(actor)
			if gained>0:
				if journey_manager!=null:journey_manager.sync_combat()
				message("Combate regional • +%d XP"%gained)
			if not save_progress():restore_failed_death(actor,before);message("Derrota revertida: não foi possível salvar.");return
			actor.call_deferred("queue_free")
		return
	super.enemy_defeated(actor)
func objective() -> String:
	if _dungeon_inside():return "Explore a masmorra.\n"+str(exo_core.services.invoke("dungeons","interaction_hint"))
	if journey_manager!=null:
		var tracked: String=journey_manager.objective()
		if not tracked.is_empty():return tracked
	if current_region>=0:return "Região %02d • %s\nEstradas: E nas passagens • moradores: E para conversar"%[current_region,region_title(active_region.data.spec)]
	return super.objective()
func destination() -> Vector3:
	if current_region>=0:return Vector3(0,active_region.data.center_h,6)
	return super.destination()

func resume_checkpoint() -> void:
	# The laboratory/checkpoint action must leave the active visit first.
	# Otherwise the regional spawn is teleported into a hidden, disabled exterior.
	if wg5_visit!=null and wg5_visit.inside():
		if not wg5_visit.interrupt("manual_checkpoint"):return
	if _institutional_inside():
		if not bool(_exit_institutional_interior(true).get("ok",false)):return
	if _dungeon_inside():
		if exo_core.services.invoke("dungeons","interrupt_active_visit",["manual_checkpoint"])!=true:return
	if convergence_ready and current_region>=0 and is_instance_valid(active_region):
		# Restore combat/stamina without discarding the procedural region or its save.
		super.resume_checkpoint()
		var anchor: Vector3=Vector3(0,active_region.data.center_h+0.08,0)
		var safe: Vector3=regional_spawn(active_region,anchor)
		if safe.is_finite():prepare_player_spawn(safe)
		else:message("Sem piso regional seguro para ressurgimento; preservando estado.")
		update_camera()
		return
	super.resume_checkpoint()

func region_title(spec: Dictionary) -> String:
	if str(spec.get("kind",""))=="wild" and spec.has("worldgen_v4"):return str(spec.worldgen_v4.profile.get("form","Terras abertas")).replace("_"," ").capitalize()
	if spec.kind=="settlement":return {"village":"Aldeia","town":"Vila","city":"Cidade"}.get(str(spec.settlement_scale),"Assentamento")
	return {"wild":"Terras abertas","ruins":"Ruínas","dungeon_approach":"Entrada de masmorra"}.get(str(spec.kind),"Região")
func role_title(role: String) -> String:
	return {"resident":"Morador","farmer":"Agricultor","merchant":"Comerciante","healer":"Curandeiro","guard":"Vigia","guild_agent":"Representante da Guilda","disciple":"Discípulo","master":"Mestre","courier":"Mensageiro","outlaw":"Fora da lei"}.get(role,"Morador")

func _exit_tree() -> void:
	if exo_core!=null:exo_core.shutdown()

func restore_failed_death(actor: Node3D,before: Dictionary) -> void:
	journey.data=before
	actor.hp=1;actor.visible=true;actor.collision_layer=4;actor.cooldown=3.0;actor.set_meta("ecology_rewarded",false)
	if actor.has_method("revive_after_failed_commit"):actor.revive_after_failed_commit()
	var key: String=str(actor.get_meta("ecology_territory",""))+"/m%d"%int(actor.get_meta("ecology_member",-1))
	ecology_director.active[key]=actor
	if actor not in enemies:enemies.append(actor)
	inventory.rebuild_drops()

func _prepare_worldgen_campaign()->bool:
	if flow.phase!="creator" or not extension().visited.is_empty():return false
	extension()["worldgen_v5"]={"schema":1,"generator":5,"settlement":"1.0.1","npc":"0.4.1"}
	extension()["worldgen_v4"]={"schema":1,"generator":4}
	extension()["regional_version"]=7
	extension().erase("atlas");atlas={}
	return true
func _worldgen_landmark_interact()->bool:
	if not is_instance_valid(active_region):return false
	for point in active_region.get_meta("wg4_landmarks",[]):
		if point.get("approved",false) and player.position.distance_to(point.point)<2.8:
			ui.dialogue(str(point.title),str(point.description));return true
	return false

func _near_resident(limit: float=2.0) -> Node3D:
	var best: Node3D=null
	var distance: float=limit
	for actor in residents:
		if not is_instance_valid(actor) or not actor.can_interact(player.global_position,limit):continue
		var current: float=actor.position.distance_to(player.position)
		if current<distance:
			var ray:=PhysicsRayQueryParameters3D.create(player.global_position+Vector3.UP,actor.global_position+Vector3.UP,1|4)
			if not get_world_3d().direct_space_state.intersect_ray(ray).is_empty():continue
			best=actor;distance=current
	return best

func npc_activity_label(activity: String) -> String:
	return {"viagem":"A caminho de seus afazeres.","atendimento":"Atendendo os moradores.","plantio":"Cuidando da plantação.","colheita":"Trabalhando na colheita.","treino":"Praticando artes marciais.","meditacao":"Em meditação.","descanso":"Descansando.","patrulhar":"Patrulhando a região.","posto":"Vigiando este local.","administracao":"Organizando os assuntos da comunidade.","preparar_remedios":"Preparando remédios.","convivio":"Conversando com os moradores."}.get(activity,"Cuidando de seus afazeres.")
