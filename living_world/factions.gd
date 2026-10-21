extends RefCounted
const FACTIONS=["comunidade","caravanas","autoridades","guilda","escola_marcial","fora_da_lei"]

static func standings(data: Dictionary) -> Dictionary:
	var state: Dictionary=data.get("living_world",{})
	return state.get("reputation",{})

static func adjust(state: Dictionary,faction: String,amount: int) -> bool:
	if faction not in FACTIONS or amount<-100 or amount>100:return false
	state.reputation[faction]=clampi(int(state.reputation.get(faction,0))+amount,-100,100)
	return true

static func standing(state: Dictionary,faction: String) -> String:
	var value: int=int(state.reputation.get(faction,0))
	if value<=-60:return "hostil"
	if value<=-20:return "desconfiado"
	if value>=60:return "aliado"
	if value>=20:return "respeitado"
	return "neutro"

static func merchant_price_factor(state: Dictionary,merchant_faction: String) -> float:
	# Projection only. Shops may call this; legacy inventory/economy is unchanged.
	var v: int=int(state.reputation.get(merchant_faction,0))
	return clampf(1.0-float(v)*0.002,0.80,1.20)
