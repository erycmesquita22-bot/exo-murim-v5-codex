extends RefCounted
## NPC04: operational agenda. Living World owns IDs/roles; this code only selects executable activities.
const HOURS := 90.0
const WORK := ["trabalho", "atendimento", "organizar_mercadorias", "preparar_banca", "fechar_banca", "treino", "meditacao", "plantio", "colheita", "posto", "administracao", "preparar_remedios", "organizar_oficina"]

static func choose(person: Dictionary, now: float, danger: bool = false, social: bool = false, patrol_leg: int = 0) -> Dictionary:
    var prefs: Dictionary = person.get("preferences", {})
    var duty: int = clampi(int(prefs.get("duty", 55)), 0, 100)
    var outgoing: int = clampi(int(prefs.get("social", 45)), 0, 100)
    var courage: int = clampi(int(prefs.get("risk", 45)), 0, 100)
    var role: String = str(person.get("role", "resident"))
    var habit: String = str(person.get("habit", "pontual"))
    var offset: float = float(person.get("routine_offset", 0.0)) * HOURS / 60.0
    if habit == "matinal": offset += 32.0
    elif habit == "noturno": offset -= 30.0
    if duty > 80: offset *= 0.5
    var clock: float = now + offset
    var h: int = posmod(int(floor(clock / HOURS)), 24)
    var home: String = str(person.get("home_slot", ""))
    var work: String = str(person.get("work_slot", home))
    if home.is_empty(): home = work
    var activity: String = "descanso"
    var slot: String = home
    var priority: int = 20
    if danger:
        if role == "guard" or role == "outlaw":
            activity = "alerta"; slot = work; priority = 100
        elif courage >= 85:
            activity = "observar_risco"; slot = "@square"; priority = 85
        else:
            activity = "evitar_risco"; slot = home; priority = 100
    elif h < 6 or h >= 21:
        if role == "guard":
            activity = "patrulhar"; slot = "@square" if patrol_leg % 2 == 0 else work; priority = 60
        else:
            activity = "descanso"; slot = home
    elif role == "guard":
        activity = "patrulhar" if h < 9 or h >= 18 else "posto"
        slot = ("@square" if patrol_leg % 2 == 0 else work) if activity == "patrulhar" else work
        priority = 55
    elif role == "merchant" or role == "healer":
        if h < 8:
            activity = "preparar_banca"; slot = work
        elif h < 19:
            activity = "atendimento" if role == "merchant" else "preparar_remedios"; slot = work
        elif h < 20:
            activity = "fechar_banca"; slot = work
        else:
            activity = "convivio"; slot = "@square" if outgoing > 55 else home
        priority = 45
    elif role == "master" or role == "disciple":
        if h < 12: activity = "treino"; slot = work
        elif h < 16: activity = "meditacao"; slot = work
        else: activity = "convivio"; slot = "@square"
        priority = 52
    elif role == "courier":
        activity = "viagem" if h >= 8 and h < 18 else "convivio"
        slot = "@square" if activity == "viagem" or outgoing >= 60 else home
        priority = 45
    elif role == "farmer":
        activity = "plantio" if h < 12 else "colheita" if h < 18 else "convivio"
        slot = work if h < 18 else "@square"
        priority = 40
    else:
        if h < 8 or h >= 19:
            activity = "convivio" if outgoing >= 55 else "atividade_reservada"
            slot = "@square" if outgoing >= 55 else home
        else:
            activity = "administracao" if role == "guild_agent" else "organizar_oficina"
            slot = work; priority = 40
    # Personality changes actual destination and duration, not merely displayed text.
    if not danger and activity in ["convivio", "atividade_reservada"] and social and outgoing >= 70:
        activity = "procurar_conhecidos"; slot = "@square"; priority = 50
    if not danger and activity in WORK and duty < 32 and h in [11, 15]:
        activity = "pausa_curta"; slot = "@square" if outgoing > 50 else home; priority = 35
    return {"activity": activity, "slot": slot, "priority": priority, "hour": h}
