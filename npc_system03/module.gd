extends RefCounted
# Optional service only. No module re-registration, automatic spawn or save writer.
const Agenda = preload("res://npc_system03/core/agenda.gd")
const Identity = preload("res://npc_system03/core/identity.gd")
const Social = preload("res://npc_system03/core/social.gd")
const Stations = preload("res://npc_system03/core/stations.gd")
const Queue = preload("res://npc_system03/core/queue.gd")
const LOD = preload("res://npc_system03/core/lod.gd")
const Patrol = preload("res://npc_system03/core/patrol.gd")
const Sources = preload("res://npc_system03/adapters/optional_sources.gd")
var core: RefCounted
var queue = Queue.new()
const VERSION := "0.1.0"

func initialize(context: RefCounted) -> bool:
	if context == null or context.get("services") == null or not context.services.has_method("register_service"):
		return false
	var methods: Array = ["agenda_for", "day_preview", "appearance_preview", "encounter_preview",
		"romance_preview", "city_stations", "station_destination", "register_queue", "request_queue",
		"release_queue", "crowd_view", "library_view", "lod_view", "patrol_next", "compatibility_status"]
	if not bool(context.services.register_service("npc03.agenda", "npc_system03", self, methods, VERSION)):
		return false
	core = context
	return true

func agenda_for(person: Dictionary, clock: float, context: Dictionary = {}) -> Dictionary:
	return Agenda.choose(person, clock, context)

func day_preview(person: Dictionary, start_clock: float, context: Dictionary = {}) -> Array:
	return Agenda.day_preview(person, start_clock, context)

func appearance_preview(person: Dictionary, seed_text: String) -> Dictionary:
	return Identity.preview(person, seed_text)

func encounter_preview(a: Dictionary, b: Dictionary, clock: float, narrative: Dictionary = {}, physical: bool = false) -> Dictionary:
	return Social.encounter(a, b, clock, narrative, physical)

func romance_preview(a: Dictionary, b: Dictionary, clock: float, narrative: Dictionary = {}, physical: bool = false) -> Dictionary:
	return Social.romance(a, b, clock, narrative, physical)

func city_stations(area_snapshot: Dictionary) -> Dictionary:
	return Sources.city_slots(area_snapshot)

func station_destination(person: Dictionary, semantic: String, context: Dictionary) -> Dictionary:
	return Stations.propose(person, semantic, context)

func register_queue(station: Dictionary) -> Dictionary:
	return queue.register_station(station)

func request_queue(station_id: String, npc_id: String) -> Dictionary:
	return queue.request(station_id, npc_id)

func release_queue(station_id: String, npc_id: String) -> bool:
	return queue.release(station_id, npc_id)

func crowd_view(real_npc_ids: Array, zone: Dictionary) -> Dictionary:
	return Sources.crowd_constraints(real_npc_ids, zone)

func library_view(request: Dictionary) -> Dictionary:
	return Sources.library_proposal(request)

func lod_view(distance_squared: float, visible: bool, in_conversation: bool, in_combat: bool) -> Dictionary:
	return LOD.advise(distance_squared, visible, in_conversation, in_combat)

func patrol_next(person: Dictionary, previous: Dictionary, context: Dictionary) -> Dictionary:
	return Patrol.next_stop(person, previous, context)

func compatibility_status() -> Dictionary:
	return {"module":"npc_system03", "version":VERSION,"base":"C3 Work Candidato 01",
		"service":"npc03.agenda", "mode":"optional_proposals_only", "owns_save":false,
		"writes_core":false,"crowd_actor_conversion":false,
		"city_r4":"contract_pending", "visual_preview_only":true,
		"native_qa":"NOT_RUN","committed":false}

func shutdown() -> void:
	queue.clear_region()
	core = null
