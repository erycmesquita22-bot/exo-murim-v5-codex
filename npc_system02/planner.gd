extends RefCounted
# Utility-based agenda: personality changes priorities, occupation constrains tasks.
# All decisions are discrete ticks in the existing 90s/hour WorldClock.
const WorldClock=preload("res://ai_core/world_clock.gd")
const People=preload("res://living_world/people.gd")
const Stations=preload("res://npc_system02/stations.gd")
static func trait_value(person: Dictionary,name: String,fallback: int=50) -> int:
	return clampi(int(person.get("preferences",{}).get(name,fallback)),0,100)
static func choose(person: Dictionary,clock: float,context: Dictionary={}) -> Dictionary:
	var habit: String=str(person.get("habit","pontual"))
	var drift: float=float(person.get("routine_offset",0))
	if habit=="matinal":drift+=30.0
	elif habit=="noturno":drift-=28.0
	if trait_value(person,"duty")>=82:drift*=.55
	var shifted: float=clock+drift*WorldClock.SECONDS_PER_HOUR/60.0
	var h: int=posmod(int(floor(shifted/WorldClock.SECONDS_PER_HOUR)),24)
	var base: String=People.activity(person,h)
	var role: String=str(person.get("role","resident"))
	var phase: int=posmod(int(floor(shifted/(WorldClock.SECONDS_PER_HOUR*.5)))+abs(str(person.get("id","")).hash())%3,4)
	var duty: int=trait_value(person,"duty");var sociability: int=trait_value(person,"social")
	var ambition: int=trait_value(person,"ambition");var bold: int=trait_value(person,"risk")
	if role=="merchant":
		if h==7:base="organizar_mercadorias" if phase%2==0 else "preparar_banca"
		elif h==18:base="fechar_banca"
		elif base=="trabalho":base="atendimento" if phase<3 else "organizar_mercadorias"
	elif role=="healer" and base=="trabalho":
		base="preparar_remedios" if phase in [0,1] else "atendimento"
	elif role=="guild_agent" and base=="trabalho":
		base="administracao" if phase<3 else "revisar_registros"
	elif role=="resident" and base=="trabalho":
		base="organizar_oficina" if phase in [0,1] else "trabalho"
	elif role=="farmer" and base in ["plantio","colheita"]:
		if duty<45 and phase==3:base="pausa_curta"
	elif role in ["master","disciple"] and base in ["treino","meditacao"]:
		if phase==3 and duty<75:base="pausa_treino"
		elif ambition>=72 and base=="meditacao" and h<17:base="treino_individual"
	var home: String=str(person.get("home_slot",""));var work: String=str(person.get("work_slot",home))
	var slot: String="@square" if base in ["convivio","espera"] else home if base in ["descanso","fora_de_servico"] else "@activity"
	if base=="convivio" and sociability<25:
		base="atividade_reservada";slot="@activity" if not work.is_empty() else home
	if base in ["pausa_curta","pausa_treino"]:slot="@square" if sociability>=65 else "@activity"
	if role in ["guard","outlaw"] and base=="ronda":slot="@square" if int(context.get("patrol_leg",0))%2==0 else "@activity"
	if role=="courier" and base=="viagem":slot="@square" if h%3==0 else "@activity"
	if work.is_empty() and slot=="@activity":slot=home
	# Named stations are resolved only if physically provided by a newer region;
	# older Cidade Viva regions retain all their original route IDs.
	var named: String=""
	if role=="merchant" and base in ["atendimento","organizar_mercadorias","preparar_banca","fechar_banca"]:named="market_stall"
	elif role in ["master","disciple"] and base in ["treino","treino_individual","meditacao"]:named="training_courtyard"
	elif role=="guard" and base=="posto":named="guard_post"
	elif role in ["resident","healer"] and base in ["trabalho","organizar_oficina","preparar_remedios"]:named="workshop_station"
	if not named.is_empty():slot=Stations.resolve(named,person,context.get("station_routes",{}))
	var danger: int=int(context.get("danger_level",2 if bool(context.get("danger",false)) else 0))
	if float(context.get("talk_seconds",0.0))>0:
		return {"activity":"conversa_jogador","slot":str(context.get("current_slot",slot)),"priority":100}
	if danger>=2 or danger>=1 and bold<35:
		if role in ["guard","outlaw"]:return {"activity":"alerta","slot":"@activity","priority":94}
		if bold>=78 and danger==2:return {"activity":"observar_risco","slot":slot,"priority":76}
		return {"activity":"evitar_risco","slot":home if not home.is_empty() else "@square","priority":95}
	if danger==1 and (role=="guard" or bold>=72 and trait_value(person,"curiosity")>=65):
		return {"activity":"investigar","slot":"@square" if role=="guard" else slot,"priority":81}
	if bool(context.get("social_opportunity",false)) and sociability>=72 and base in ["convivio","espera","pausa_curta"]:
		base="procurar_conhecidos";slot="@square"
	if role in ["guard","outlaw"] and base=="ronda":base="patrulhar"
	return {"activity":base,"slot":slot,"priority":16 if duty>=80 and base not in ["convivio","espera"] else 10}
static func snapshot_at(person: Dictionary,clock: float) -> Dictionary:
	var plan: Dictionary=choose(person,clock)
	return {"activity":plan.activity,"to_slot":plan.slot,"from_slot":plan.slot,"abstract":true,"clock":clock}
