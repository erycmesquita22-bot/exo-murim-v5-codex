extends RefCounted
# Bare hands are a combat mode, never an inventory weapon or a synonym for gauntlets.
const STEPS=[
	{"name":"Soco esquerdo","duration":.36,"hit":.46,"power":.9},
	{"name":"Soco direito","duration":.40,"hit":.45,"power":1.0},
	{"name":"Palma aberta","duration":.48,"hit":.50,"power":1.1},
	{"name":"Palma enraizada","duration":.62,"hit":.55,"power":1.35}]
static func spec() -> Dictionary:
	return {"id":"unarmed","name":"Mãos livres","pose":"unarmed","hands":0,"damage":9,"reach":1.45,"duration":.4,"hit":.46,"cone":.65,"ranged":false,"description":"Soco esquerdo, direito, palma e finalização enraizada."}
static func extension(progress: float,index: int) -> float:
	var hit: float=STEPS[index].hit
	return smoothstep(.06,hit,progress)*(1.0-smoothstep(hit+.045,.98,progress))
static func legacy(r: Node3D,index: int,p: float) -> void:
	for i in range(2):r.arms[i].rotation=Vector3(.7,(-.15 if i==0 else .15),(-.12 if i==0 else .12))
	if p<0:return
	var e:=extension(p,index);var hand:=1 if index in [0,2] else 0;var side:=1.0 if hand==0 else -1.0
	r.arms[hand].rotation=Vector3(.7+e*.9,-side*.18,-side*.12)
	# Preserve square limbs while extending the elbow through the contact window.
	r.forearms[hand].rotation.x=-.85+e*.7
	r.forearms[1-hand].rotation.x=-.65
	r.torso.rotation.y=side*e*(.28 if index==3 else .18)
	r.torso.rotation.x=-e*.06
	if index==3:
		r.legs[0].rotation.x=.18*e;r.legs[1].rotation.x=-.14*e
