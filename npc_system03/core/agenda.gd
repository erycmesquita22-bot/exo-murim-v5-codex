extends RefCounted
const Planner = preload("res://npc_system02/planner.gd")
const Stations = preload("res://npc_system03/core/stations.gd")
const Stable = preload("res://npc_system03/core/stable.gd")
# Agenda is an advisory layer; never calls resident._change_destination or mutates save.
const TASK_SEMANTIC := {
	"atendimento":"market_stall", "preparar_banca":"market_stall", "fechar_banca":"market_stall",
	"organizar_mercadorias":"market_stall", "patrulhar":"patrol_waypoint", "posto":"guard_post",
	"treino":"training_courtyard", "treino_individual":"training_courtyard",
	"meditacao":"martial_hall", "preparar_remedios":"healer_station", "organizar_oficina":"workshop_station",
	"trabalho":"workshop_station", "convivio":"social_area"}
static func choose(person: Dictionary, clock: float, context: Dictionary = {}) -> Dictionary:
	var uid: String = str(person.get("id", ""))
	if uid.is_empty() or int(person.get("generation_version", 1)) != 1:
		return {"status":"BLOCKED","reason":"invalid_person"}
	var plan: Dictionary = Planner.choose(person, clock, context)
	var activity: String = str(plan.get("activity", "espera"))
	var slot: String = str(plan.get("slot", ""))
	var risk: int = int(person.get("preferences", {}).get("risk", 45))
	var discipline: int = int(person.get("preferences", {}).get("duty", 55))
	var hour: int = posmod(int(floor(clock / 90.0)), 24)
	var threat: int = clampi(int(context.get("danger_level", 0)), 0, 3)
	if threat > 0 and activity != "conversa_jogador":
		if str(person.get("role", "")) == "guard":
			activity = "alerta" if threat > 1 else "investigar"
		elif risk < 45 or threat >= 3:
			activity = "evitar_risco"
		elif risk >= 75 and threat == 1:
			activity = "observar_risco"
	var work_type: String = ""
	if str(person.get("role", "")) == "merchant" and activity in ["atendimento", "organizar_mercadorias"]:
		work_type = "assistir_cliente" if discipline >= 65 else "reorganizar_banca"
	elif str(person.get("role", "")) == "guard" and activity in ["patrulhar", "posto"]:
		work_type = "observar_setor"
	elif str(person.get("role", "")) in ["master", "disciple"] and activity in ["treino", "treino_individual"]:
		work_type = "praticar_formas"
	elif str(person.get("role", "")) == "farmer" and activity in ["plantio", "colheita"]:
		work_type = "cultivar_canteiro"
	var cadence: int = 2 + Stable.choose(str(context.get("seed", "0")), uid, "cadence:"+str(hour), 3)
	var proposal: Dictionary = {"status":"PROPOSED","npc_id":uid,"activity":activity,"slot":slot,
		"work_type":work_type,"priority":int(plan.get("priority", 10)),
		"decision_interval_seconds":cadence,"clock":clock,"owner":"living_world",
		"requires_actor":activity in ["investigar", "patrulhar", "atendimento"],
		"committed":false,"route_approved":false}
	var semantic: String = str(TASK_SEMANTIC.get(activity, ""))
	if not semantic.is_empty() and bool(context.get("use_city", false)):
		var station: Dictionary = Stations.propose(person, semantic, context)
		if str(station.get("status", "")) == "PROPOSED":
			proposal["station_id"] = str(station.get("station_id", ""))
			proposal["slot"] = str(station.get("route_slot", ""))
			proposal["route_approved"] = true
		else:
			proposal["station_fallback_reason"] = str(station.get("reason", "no_station"))
	# Never claim an unverified route is safe. The host must validate on acceptance.
	return proposal

static func day_preview(person: Dictionary, start_clock: float, context: Dictionary = {}) -> Array:
	var result: Array = []
	for h in range(24):
		var entry: Dictionary = choose(person, start_clock + float(h) * 90.0, context)
		result.append({"hour":h,"proposal":entry})
	return result
