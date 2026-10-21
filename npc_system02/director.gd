extends RefCounted
# Region-scoped orchestration only. Does not own saves, dialogue, navigation or AI combat.
const Crowd=preload("res://npc_system02/crowd.gd")
const Planner=preload("res://npc_system02/planner.gd")
const Social=preload("res://npc_system02/social.gd")
var host: Variant
var crowd= Crowd.new()
var crowd_clock:=0.0
var social_clock:=0.0
var social_cursor:=0
var stats: Dictionary={"crowd_updates":0,"social_checks":0,"social_events":0,"far_ticks":0,"social_rejected":0,"social_candidates":0}
func _init(game: Node3D) -> void:host=game
func tick(delta: float,actors: Array,clock: float) -> void:
	if actors.is_empty():return
	crowd_clock-=delta
	if crowd_clock<=0.0:
		crowd_clock=.32
		crowd.rebuild(actors)
		for actor in actors:actor.nearby_residents=crowd.near(actor)
		stats.crowd_updates=int(stats.crowd_updates)+1
	var player_pos: Vector3=host.player.position
	var hour: int=posmod(int(floor(clock/90.0)),24)
	for actor in actors:
		var d2: float=actor.position.distance_squared_to(player_pos)
		var danger: bool=(float(host.get("combat_timer"))>0.0 and d2<100.0)
		actor.near_player=d2<225.0
		actor.attention_near=d2<16.0
		actor.player_interest_position=player_pos
		actor.danger_nearby=danger
		actor.visual_active=actor.presentation_visible and d2<3600.0
		if d2>6400.0:
			actor.step_far(delta,clock)
			stats.far_ticks=int(stats.far_ticks)+1
		else:actor.step(delta,hour,clock)
	# Very low budget social processing, only idle, unoccupied visible neighbors.
	social_clock-=delta
	if social_clock>0.0:return
	social_clock=1.2
	if actors.is_empty():return
	var actor: Variant=actors[social_cursor%actors.size()]
	social_cursor+=1
	stats.social_checks=int(stats.social_checks)+1
	if not is_instance_valid(actor) or actor.sheltered or actor.social_time>0.0 or actor.social_cooldown>0.0:return
	if actor.activity_name not in ["convivio","espera","procurar_conhecidos","pausa_curta","pausa_treino"] or not actor.arrived:return
	# Social choice is scored; roster order does not determine the partner.
	var narrator: Dictionary=host.journey.data.get("narrative",{})
	var best: Variant=null;var best_score: float=-INF
	for other in actor.nearby_residents:
		if not is_instance_valid(other) or not other.arrived or other.sheltered:continue
		if other.social_time>0 or other.social_cooldown>0 or other.activity_name not in ["convivio","espera","procurar_conhecidos","pausa_curta","pausa_treino"]:continue
		var distance: float=actor.position.distance_squared_to(other.position)
		if distance>5.0 or distance<.5:continue # don't make two agents stand in the same spot
		stats.social_candidates=int(stats.social_candidates)+1
		if not Social.eligible(actor.identity,other.identity,clock,narrator,true):continue
		var affinity: float=Social.affinity(actor.identity,other.identity,narrator)+Social.affinity(other.identity,actor.identity,narrator)
		var chance: int=int(actor.identity.get("preferences",{}).get("social",40))
		if chance<25 and affinity<20:continue
		var score: float=affinity-distance*2.0
		if score<(-8.0 if chance>=80 else 6.0):continue
		if score>best_score:best=other;best_score=score
	if best==null:
		stats.social_rejected=int(stats.social_rejected)+1;return
	if not Social.meet(actor.identity,best.identity,clock,narrator,true):return
	actor.begin_social(best)
	best.begin_social(actor)
	stats.social_events=int(stats.social_events)+1

func abstract_report(people: Array,clock: float) -> Array:
	var report: Array=[]
	for person in people:report.append({"npc_id":person.id,"snapshot":Planner.snapshot_at(person,clock)})
	return report
