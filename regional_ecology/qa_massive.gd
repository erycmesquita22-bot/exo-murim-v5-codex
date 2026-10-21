extends SceneTree
const Planner=preload("res://regional_ecology/territories.gd")
const Rewards=preload("res://regional_ecology/rewards.gd")
const Clock=preload("res://ai_core/world_clock.gd")
class MockData extends RefCounted:
	var spec: Dictionary={}
	var half:=240.0
	func _init(kind: String,rid: int) -> void:spec={"kind":kind,"id":rid,"difficulty":rid%6+1}
	func height_at(p: Vector2) -> float:return 12.0+0.03*p.x+0.04*p.y
	func gate_road_distance(p: Vector2) -> float:return absf(p.y)
	func river_distance(p: Vector2) -> float:return absf(p.x-55.0)
	func pad_distance(_p: Vector2) -> float:return 1000.0
var failures: Array=[]
var checks:=0
func verify(ok: bool,description: String) -> void:
	checks+=1
	if not ok and failures.size()<40:failures.append(description)
func _initialize() -> void:call_deferred("run_suite")
func run_suite() -> void:
	for kind in ["wild","ruins","dungeon_approach","settlement"]:
		for seed in range(1500):
			var region: RefCounted=MockData.new(kind,seed%88)
			var a: Array=Planner.build(region,str(seed))
			var b: Array=Planner.build(region,str(seed))
			verify(a.size()==b.size(),"determinism count")
			verify(a.size()<=4,"territory budget")
			verify(a.is_empty() if kind=="settlement" else a.size()>0,"biome zones")
			for i in range(a.size()):
				verify(a[i].id==b[i].id and a[i].p.distance_to(b[i].p)<0.001,"determinism location")
				verify(region.gate_road_distance(a[i].p)>=9 and region.river_distance(a[i].p)>=15,"road/river exclusion")
				for j in range(i):verify(a[i].p.distance_to(a[j].p)>=34,"site overlap")
	var e: Dictionary=Rewards.ensure({})
	var last:=0
	for i in range(120000):
		var xp: int=Rewards.award(e,i%88,"blade" if i%2==0 else "mage",i%30+1,int(i/10000))
		verify(xp>0 and xp<=132,"xp bounds")
		last+=xp
	verify(e.xp_total==last,"xp conservation")
	for day in range(100):
		var clock: Dictionary={"clock":float(day)*2160.0,"clock_rate":2}
		verify(Clock.hour(clock)==0 and Clock.day(clock)==day,"clock consistency")
	# v2: 2,060 distinct claims never get forgotten during migration/replay.
	var WorldSeed=preload("res://procedural/world_state.gd")
	var save: Dictionary={"world":WorldSeed.create(101,"world_ecology_qa")}
	for i in range(2060):
		var key: String="loot/eco/r%02d/t00/m0/g%04d"%[i%88,i]
		verify(WorldSeed.mark_collected(save.world,key),"claimed_%d"%i)
	verify(save.world.events.is_empty() and save.world.claim_receipts.count==2060,"no_receipt_loss")
	var archive_before: int=save.world.claim_receipts.count
	Rewards.compact_claimed(save,1500)
	verify(save.world.claim_receipts.count==archive_before and not WorldSeed.mark_collected(save.world,"loot/eco/r00/t00/m0/g0000"),"no_replay_after_compaction")
	# Defeat lifecycle without a physics scene: a dead camp cannot instantly renew.
	var ecology: Dictionary=Rewards.ensure({})
	var record: Dictionary=Rewards.territory_state(ecology,32,"eco/r32/t00")
	record.defeated_at=100.0
	verify(not Rewards.permitted(record,639.0),"respawn cooldown blocks early")
	verify(Rewards.permitted(record,640.0),"respawn unlock at six hours")
	# Migration must be idempotent, and hour must wrap after 24 hours.
	var old_clock: Dictionary={"clock":36000.0}
	Clock.migrate(old_clock)
	verify(is_equal_approx(float(old_clock.clock),900.0) and Clock.hour(old_clock)==10,"clock old-to-new")
	Clock.migrate(old_clock)
	verify(is_equal_approx(float(old_clock.clock),900.0),"clock migration idempotent")
	verify(Clock.hour({"clock":2160.0,"clock_rate":2})==0,"hour wrap")
	print("EXO_AI_MASSIVE: %d checks / %d failures"%[checks,failures.size()])
	for f in failures:push_error(str(f))
	quit(1 if not failures.is_empty() else 0)
