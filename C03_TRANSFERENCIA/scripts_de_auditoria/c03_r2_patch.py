from pathlib import Path
import hashlib,json
R=Path('/mnt/data/C03_ALFA_R2_WORK')
changes=[]
def sh(s):return hashlib.sha256(s).hexdigest()
def patch(rel,old,new,why):
 p=R/rel;s=p.read_text(encoding='utf8'); assert s.count(old)==1,(rel,s.count(old),old[:150]);v=s.replace(old,new);p.write_text(v,encoding='utf8');changes.append({'file':rel,'before':sh(s.encode()),'after':sh(v.encode()),'reason':why})
def add(rel,v,why):
 p=R/rel; assert not p.exists();p.parent.mkdir(parents=True,exist_ok=True);p.write_text(v,encoding='utf8');changes.append({'file':rel,'before':None,'after':sh(v.encode()),'reason':why})
# RIG01 source-level code conflict: R1 computed elbow flexion and immediately overwrote it.
patch('rig.gd','''	if arms_free:
		arms[0].rotation.x = swing*direction.y*0.8
		arms[1].rotation.x = -swing*direction.y*0.8
		arms[0].rotation.z += swing*direction.x*0.25
		arms[1].rotation.z -= swing*direction.x*0.25

	preload("res://animation_library.gd").locomotion(self,gait_phase,sprint,arms_free,direction.y,speed,direction.x)
	if arms_free:
		for i in range(2):forearms[i].rotation.x=-.25-absf(swing)*.2''','''	# A single animation owner writes shoulder and elbow transforms.
	# Never overwrite the local-space elbow rotation after this call.
	preload("res://animation_library.gd").locomotion(self,gait_phase,sprint,arms_free,direction.y,speed,direction.x)''','RIG01 remove double-writes to shoulders and forearms; arm local-space pose is final')
# Keep R1 local motion but ensure left/right kinematic phase use matching sides, and avoid accidental array type assumptions.
patch('animation_library.gd','''static func locomotion(rig: Node3D, phase: float, sprint: bool, arms_free: bool, forward: float, speed: float, lateral: float=0.0) -> void:
 if not arms_free or speed<0.06:return''','''static func locomotion(rig: Variant, phase: float, sprint: bool, arms_free: bool, forward: float, speed: float, lateral: float=0.0) -> void:
 if not arms_free or speed<0.06:return
 if not is_instance_valid(rig):return
 if rig.arms.size()!=2 or rig.forearms.size()!=2:return''','RIG01 robust rig references; Variant matches runtime rig with extra fields')
# Fix the user-reported accidental legacy village construction during character creation.
old='''	clear_actors()
	god.hide()
	world.rebuild_region()
	sync_village_sites()
	for actor in field_enemies:
		actor.enabled=true
	world.resume_checkpoint()
	apply_character()
	world.prepare_player_spawn(world.village_anchor("camp",Vector3(1.5,0.03,30)))
	world.update_camera()
	world.ui.close_flow()
	# Convergencia 03: first playable area comes from atlas, not legacy initial enclosure.
	# Deferred until the creator callback releases the UI tree; old prologue assets
	# remain available only as references while shared quests/training are migrated.
	if world.has_method("change_region") and world.has_method("starting_region"):
		world.call_deferred("change_region",world.starting_region(),"")
		world.message("Nascimento: "+str(birthplace.title)+" • viajando para as regiões procedurais.")
		return true'''
new='''	clear_actors()
	god.hide()
	# For Convergence 03 a new campaign NEVER rebuilds or respawns in the retired
	# village before the seed-based atlas is ready. The old prologue remains a
	# separate historical/test flow until its other dependencies are detached.
	if world.has_method("_begin_new_procedural_campaign"):
		apply_character()
		world.player.velocity=Vector3.ZERO
		world.ui.close_flow()
		world.set_paused(false)
		world.call_deferred("_begin_new_procedural_campaign")
		world.message("Nascimento: "+str(birthplace.title)+" • preparando região procedural.")
		return true
	# Compatibility only for non-Convergence test scenes with no atlas host.
	world.rebuild_region()
	sync_village_sites()
	for actor in field_enemies:
		actor.enabled=true
	world.resume_checkpoint()
	apply_character()
	world.prepare_player_spawn(world.village_anchor("camp",Vector3(1.5,0.03,30)))
	world.update_camera()
	world.ui.close_flow()'''
patch('murim_flow.gd',old,new,'FLOW01 create new campaign via procedural host without legacy rebuild or camp spawn')
patch('convergence/game.gd','''func starting_region() -> int:
''','''func _begin_new_procedural_campaign() -> void:
 # Deferred from the character creator after closing the UI. All journey
 # records were saved before this callback, which cannot spawn in the old camp.
 if not convergence_ready or flow.phase!="adventure":
  generation_failure="procedural_start_not_ready"
  message("Mundo procedural indisponível: confira os logs de inicialização.")
  return
 var target_region: int=starting_region()
 var ready: bool=await change_region(target_region,"")
 if not ready:
  push_error("EXO Convergence 03: failed procedural first region " + str(target_region) + " / " + generation_failure)
  message("Falha ao iniciar mundo procedural. Não foi realizado retorno automático à vila antiga.")

func starting_region() -> int:
''','FLOW01 explicit Godot deferred startup entrypoint with fail-closed message')
# Resolve stale output after a failed event: game was permanently frozen with the region already switched.
patch('convergence/game.gd','''		if not dispatched.ok:
			generation_failure=str(dispatched);push_error(generation_failure);changing_region=false;simulation_enabled=false;return false''','''		if not dispatched.ok:
			# The former region has already been freed; do not deadlock the game with
			# an unusable actor. Keep the pending integration error visible for QA,
			# and never claim a persistent region_entered receipt was emitted.
			generation_failure="region_enter_event_failed:"+str(dispatched)
			push_error(generation_failure)
			changing_region=false
			simulation_enabled=true
			message("Falha no evento de chegada. Esta região ainda precisa de validação do salvamento.")
			return false''','WORLD01 avoid permanent freeze on event publication failure; expose incomplete event state')
# QA native fixture: actual engine run is reserved for user PC/Work, but executable and self-contained.
add('convergence/tests/qa_rig01_eight_directions.gd','''extends SceneTree
# C03 ALFA R2: execute with Godot 4.6.2 --headless --path ... --script res://convergence/tests/qa_rig01_eight_directions.gd
const Rig = preload("res://rig.gd")
var failure_count: int=0
func _initialize() -> void:
 call_deferred("_run")
func _run() -> void:
 var rig=Rig.new()
 root.add_child(rig)
 for k in range(8):
  var a: float=float(k)*TAU/8.0
  var motion:=Vector3(cos(a),0.0,sin(a)) * 2.0
  rig.rotation.y=atan2(-motion.x,-motion.z)
  rig.pose(0.1,false,false,true)
  rig.locomotion(motion,0.1,false,true,true)
  if str(rig.get_meta("motion_source",""))!="EXO_original_local_8directions":
   push_error("RIG01 missing animation metadata direction "+str(k));failure_count+=1
  if absf(rig.forearms[0].rotation.x+0.18)<0.001:
   push_error("RIG01 elbow did not bend direction "+str(k));failure_count+=1
  if not rig.arms[0].rotation.is_finite() or not rig.forearms[0].rotation.is_finite():
   push_error("RIG01 NaN direction "+str(k));failure_count+=1
 if failure_count>0:
  push_error("RIG01 native QA failed "+str(failure_count))
  quit(1)
 else:
  print("RIG01 eight directions: PASS (transform test, not visual clipping proof)")
  quit(0)
''','Add eight-direction real GDScript native QA fixture, not executed here')
# Update project identity and separate save namespace to protect Alfa R1 QA.
patch('project.godot','config/name="EXO-Murim — Convergencia 03 ALFA R1"','config/name="EXO-Murim — Convergencia 03 ALFA R2"','Build R2 unique title')
patch('project.godot','config/custom_user_dir_name="EXO-Murim-Convergencia-03-ALFA-QA"','config/custom_user_dir_name="EXO-Murim-Convergencia-03-ALFA-R2-QA"','Isolate QA saves per Alfa generation')
q=R/'C03_TRANSFERENCIA'; (q/'MANIFESTO-CORRECOES-R2.json').write_text(json.dumps(changes,indent=2,ensure_ascii=False),encoding='utf8')
print('R2 changed',len(changes),'files',*[x['file'] for x in changes],sep='\n')
