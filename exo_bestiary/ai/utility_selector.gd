extends RefCounted
# Seleção contextual de INTENÇÃO. Nenhuma fórmula de dano.
static func choose(profile: Dictionary, ctx: Dictionary) -> String:
    var style: String = str(profile.get("combat_style",profile.get("behavior","pressure")))
    var d := maxf(0.0,float(ctx.get("distance",10.0)))
    var hp := clampf(float(ctx.get("hp_ratio",1.0)),0.0,1.0)
    var allies := maxi(0,int(ctx.get("allies",0)))
    var desired: Array = profile.get("preferred_distance",[1.2,2.5])
    var near := float(desired[0]) if desired.size()>0 else 1.0
    var far := float(desired[1]) if desired.size()>1 else 2.5
    var choices: Dictionary = {"approach":5.0,"attack":5.0,"position":3.0,"defend":2.0,"evade":2.0,"retreat":0.0}
    choices.approach += 13.0 if d > far else -6.0
    choices.position += 13.0 if d < near else 2.0
    choices.attack += 18.0 if d >= near and d <= far and bool(ctx.get("attack_ready",false)) and bool(ctx.get("line_of_sight",false)) else -9.0
    choices.retreat += (1.0-hp)*18.0
    match style:
        "ranged":
            choices.position += 22.0 if d < near else 3.0
            choices.attack += 8.0 if d>=near and bool(ctx.get("attack_ready",false)) else 0.0
        "defensive","counter":
            choices.defend += 17.0 if bool(ctx.get("enemy_winding_up",false)) else 7.0
        "flank":
            choices.position += 12.0 if allies >= 1 else 0.0
        "spacing":
            choices.position += 13.0 if d<near else 3.0
        "technique":
            if not bool(ctx.get("technique_available",false)): choices.attack -= 11.0
        "predator":
            choices.approach += 5.0 if d>far else 0.0
        "territorial":
            choices.defend += 8.0 if d<near else 0.0
    match str(profile.get("special","")):
        "shield_wall": choices.defend += 12.0
        "flanking_burst": choices.position += 14.0 if allies>=1 else 5.0
        "pack_alert": choices.approach += 7.0 if allies>=1 else 2.0
    var order := ["attack","position","defend","evade","approach","retreat"]
    var best := "approach"
    var value := -INF
    for intent in order:
        if float(choices[intent])>value:
            value=float(choices[intent]); best=intent
    return best
