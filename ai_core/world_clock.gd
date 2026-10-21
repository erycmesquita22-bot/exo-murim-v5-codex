extends RefCounted
# A 36-minute day. Numeric state from earlier saves was real seconds (one
# hour of simulated time per real hour): convert once, never on every load.
const SECONDS_PER_HOUR := 90.0
const VERSION := 2
static func migrate(state: Dictionary) -> void:
	if int(state.get("clock_rate",1)) < VERSION:
		state["clock"] = maxf(0.0,float(state.get("clock",36000.0))/40.0)
		state["clock_rate"] = VERSION
static func hour(state: Dictionary) -> int:
	return posmod(int(floor(float(state.get("clock",0.0))/SECONDS_PER_HOUR)),24)
static func day(state: Dictionary) -> int:
	return maxi(0,int(floor(float(state.get("clock",0.0))/(SECONDS_PER_HOUR*24.0))))
static func advance(state: Dictionary,delta: float) -> void:
	state["clock"] = float(state.get("clock",0.0))+maxf(0.0,delta)
