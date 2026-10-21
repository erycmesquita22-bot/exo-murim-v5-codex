extends Node3D
const Rules=preload("res://world/event_rules.gd")
var definitions: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/encounters.json"))
var event: Dictionary=definitions.encounters[0]
var world: Node3D
var clock:=0.0
var check_clock:=0.0
var attempts:=0
var raining:=false
var stranger: Node3D
var rain: GPUParticles3D
var rng: RefCounted
var seed_identity:=""
func _ready() -> void:
	seed_identity=str(world.journey.data.world.id)
	clock=float(world.journey.data.encounter.get("clock",0));check_clock=float(world.journey.data.encounter.get("check_clock",0));attempts=int(world.journey.data.encounter.get("attempts",0))
	rng=preload("res://procedural/world_state.gd").stream(world.journey.data.world,"encounters","stranger")
	stranger=world.Rig.new()
	add_child(stranger)
	stranger.position=Vector3(5,.03,26)
	preload("res://wardrobe.gd").apply(stranger,{"race":0,"robe":4,"hair":3,"skin":2,"style":1,"weapon":"quarterstaff"})
	stranger.hide()
	# Particle volume follows the player, keeping rain bounded.
	rain=GPUParticles3D.new()
	add_child(rain)
	rain.amount=180
	rain.lifetime=.75
	rain.visibility_aabb=AABB(Vector3(-20,-10,-20),Vector3(40,30,40))
	var material:=ParticleProcessMaterial.new()
	material.emission_shape=ParticleProcessMaterial.EMISSION_SHAPE_BOX
	material.emission_box_extents=Vector3(12,.5,12)
	material.direction=Vector3(-.15,-1,0)
	material.spread=4
	material.initial_velocity_min=16
	material.initial_velocity_max=20
	material.gravity=Vector3(0,-5,0)
	rain.process_material=material
	var mesh:=BoxMesh.new()
	mesh.size=Vector3(.018,.32,.018)
	var drop:=StandardMaterial3D.new()
	drop.albedo_color=Color(.55,.62,.68,.5)
	drop.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	drop.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh.material=drop
	rain.draw_pass_1=mesh
	rain.emitting=false
func _physics_process(delta: float) -> void:
	if not world.simulation_enabled or world.flow==null or world.flow.phase!="adventure" or world.flow.lab_mode:return
	if seed_identity!=str(world.journey.data.world.id):
		seed_identity=str(world.journey.data.world.id)
		clock=float(world.journey.data.encounter.get("clock",0));check_clock=float(world.journey.data.encounter.get("check_clock",0));attempts=int(world.journey.data.encounter.get("attempts",0))
	clock+=delta
	raining=fmod(clock,float(definitions.weather.dry_seconds)+float(definitions.weather.rain_seconds))>float(definitions.weather.dry_seconds)
	rain.emitting=raining and int(world.graphics.values.particles)>0
	rain.position=world.player.position+Vector3(0,9,0)
	rain.amount=[1,80,180,280][int(world.graphics.values.particles)]
	var e: Dictionary=world.journey.data.encounter
	stranger.visible=e.met and not e.done
	if stranger.visible:stranger.pose(clock,false,false,true)
	check_clock+=delta
	if check_clock>=float(event.interval):
		check_clock=0
		if Rules.eligible(event,{"already_met":e.met,"weather":"rain" if raining else "dry","health_ratio":float(world.health)/world.max_health,"safe":world.is_safe(world.player.position)}):
			attempts+=1
			rng=preload("res://procedural/world_state.gd").stream(world.journey.data.world,"encounters/stranger",str(attempts))
			if rng.unit()<float(event.chance) or attempts>=int(event.guaranteed_attempt):appear()
	world.journey.data.encounter.clock=clock
	world.journey.data.encounter.check_clock=check_clock
	world.journey.data.encounter.attempts=attempts
func appear() -> void:
	if world.journey.data.encounter.met:return
	world.journey.data.encounter.met=true
	stranger.show()
	world.cultivation.rumor("percepcao_qi")
	world.save_progress()
	world.message("Uma figura se abriga perto da praça.")
func nearby() -> bool:
	return stranger.visible and world.player.position.distance_to(stranger.position)<2.8
func interact() -> bool:
	if not nearby():return false
	var e: Dictionary=world.journey.data.encounter
	var iron: Dictionary={}
	for item in world.journey.data.items:
		if item.ref==event.request.item and item.qty>=event.request.quantity:iron=item;break
	if iron.is_empty():
		world.ui.dialogue("Um encontro sob o céu","O desconhecido observa suas mãos.\n\n“Traga três fragmentos de ferro das ruínas. Talvez você aprenda a perceber o que hoje não consegue enxergar.”\n\nUm pedido foi anotado nas suas Crônicas.")
		return true
	var before: Dictionary=world.journey.data.duplicate(true)
	iron.qty-=int(event.request.quantity)
	if iron.qty<=0:world.journey.data.items.erase(iron)
	if world.inventory.add(event.reward.kind,event.reward.ref).is_empty():
		world.journey.data=before
		world.message("Libere um espaço no inventário.")
		return true
	e.done=true
	if not world.save_progress():
		world.journey.data=before
		return true
	stranger.hide()
	world.ui.dialogue("Um pergaminho dobrado","O desconhecido aceita o ferro e deixa um pequeno manual.\n\n“Leia. Depois, permaneça em silêncio e cultive.”\n\nO pergaminho está no seu inventário.")
	return true
