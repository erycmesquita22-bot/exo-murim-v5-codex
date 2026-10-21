#!/usr/bin/env python3
"""Static, source-only C03 R6 audit. NOT Godot native gameplay validation."""
from pathlib import Path
import zipfile,hashlib,json,re,sys
R=Path(__file__).resolve().parents[1]
BASE=Path('/mnt/data/EXO-MURIM-CONVERGENCIA-03-ALFA-R5.zip')
EXPECTED='0b8362c083d4c42ebbf412acfb4fa9b74a5a404b963848233291ffc2efb5e7eb'
checks={}
def check(label,yes):checks[label]=bool(yes)
base_sha=hashlib.sha256(BASE.read_bytes()).hexdigest()
check('r5_exact_sha256',base_sha==EXPECTED)
with zipfile.ZipFile(BASE) as z:
 old={name:z.read(name) for name in z.namelist() if not name.endswith('/')}
 check('r5_original_integrity',z.testzip() is None)
changed_files=[];missing_files=[]
for name,data in old.items():
 path=R/name
 if not path.is_file():missing_files.append(name)
 elif path.read_bytes()!=data:changed_files.append(name)
check('no_r5_file_deleted',not missing_files)
check('no_generator_v2_v3_v4_modification',all((R/n).read_bytes()==old[n] for n in ['exo_dungeon/generator/generator_v2.gd','exo_dungeon/generator/generator_v3.gd','exo_dungeon/generator/dungeon_generator.gd','exo_dungeon/runtime/renderer_r2.gd','exo_dungeon/runtime/renderer_v2.gd']))
check('r5_creature_bestiary_preserved',all((R/n).read_bytes()==v for n,v in old.items() if n.startswith(('exo_bestiary/','exo_creature_harmonizacao02/','exo_skin3d/'))))
check('r5_hud_terrain_preserved',all((R/n).read_bytes()==v for n,v in old.items() if n.startswith(('exo_ui/','exo_visual/','genesis/'))))
check('glb_assets_untouched',all((R/n).read_bytes()==v for n,v in old.items() if n.lower().endswith('.glb')))
script={str(p.relative_to(R)):p.read_text(encoding='utf8') for p in R.rglob('*.gd')}
missing_preloads=[]
for name,body in script.items():
 for target in re.findall(r'preload\([\'\"]res://([^\'\"]+)[\'\"]\)',body):
  if not (R/target).is_file():missing_preloads.append([name,target])
check('no_new_unresolved_preloads',all(src in ['godot/demo.gd','exo_core/module_template/test.gd'] for src,tgt in missing_preloads))
json_bad=[]
for file in R.rglob('*.json'):
 try:json.loads(file.read_text())
 except Exception as ex:json_bad.append([str(file.relative_to(R)),str(ex)])
check('all_json_parse',not json_bad)
mod=json.loads((R/'exo_core/modules.json').read_text())
check('one_registration_per_core_module',len(set(d['id'] for d in mod))==len(mod)==17)
check('dungeon_service_has_actual_encounter_and_tick',all(tok in script['exo_dungeon/module/entrypoint.gd'] for tok in ['"defeat_encounter"','"tick_active"','_spawn_nearby_encounters','OfficialEnemy.new()']))
check('official_combat_actor_owned_by_host',all(tok in script['exo_dungeon/module/entrypoint.gd'] for tok in ['core.world.enemies.append(enemy)','core.world.enemies.erase(actor)',' enemy.set_meta("exo_dungeon_id"']))
check('dungeon_defeats_go_to_official_game',all(tok in script['convergence/game.gd'] for tok in ['func _dungeon_enemy_defeated','_dungeon_enemy_defeated(actor):return']))
check('dungeon_xp_uses_existing_ecology_owner','Reward.award(ecology,world.current_region' in script['regional_ecology/director.gd'])
check('physical_reward_point_built','TreasureReward_' in script['exo_dungeon/runtime/dungeon_instance.gd'])
check('e_interaction_detects_reward','"kind":"reward"' in script['exo_dungeon/runtime/exploration_logic.gd'])
check('no_reward_without_physical_distance','distance_to(node.global_position)>3.2:return false' in script['exo_dungeon/module/entrypoint.gd'])
check('official_inventory_stages_drop','func queue_dungeon_pending' in script['inventory.gd'] and 'WorldSeed.mark_pending' in script['inventory.gd'])
check('no_untrusted_permissive_reward_proof','Callable(dungeon,"verify_reward_pickup")' in script['exo_core/core.gd'] and 'trusted_dungeon_reward_proof.call(dungeon_id,reward_id,source)' in script['exo_core/core.gd'])
check('one_commit_atomic_r3','return preload("res://exo_items/integration/atomic_reward_adapter.gd").confirm_pending(world,source,fingerprint' in script['exo_core/core.gd'])
check('dungeon_mark_stage_same_save','dungeon.stage_atomic_reward(dungeon_id,reward_id,"loot/"+source)' in script['exo_core/core.gd'])
check('replay_protection','is_reward_claimed(did,reward_id)' in script['exo_dungeon/module/entrypoint.gd'])
check('rollback_inventory_on_save_failure','core.world.journey.data=before' in script['exo_dungeon/module/entrypoint.gd'])
check('no_claim_before_preflight','Atomic.prepare_pending(core.world.journey.data,source)' in script['exo_dungeon/module/entrypoint.gd'])
check('claim_boss_only_after_defeat','"encounter_not_defeated"' in script['exo_dungeon/module/entrypoint.gd'])
check('door_key_secret_saved','"interaction"' in script['exo_core/core.gd'] and '"interaction_save_failed_and_rolled_back"' in script['exo_dungeon/module/entrypoint.gd'])
check('failed_puzzle_restores_geometry','dungeon.materialize(original_plan,saved_instance)' in script['exo_dungeon/module/entrypoint.gd'])
check('room_discovery_checkpoint','func tick_active(delta: float)' in script['exo_dungeon/module/entrypoint.gd'] and 'mark_discovered(did,str(room.id))' in script['exo_dungeon/module/entrypoint.gd'])
check('one_player_dungeon_transition','actor.global_position=interior.to_global' in script['exo_dungeon/runtime/transition_service.gd'] and 'actor.get_parent()' in script['exo_dungeon/runtime/transition_service.gd'])
check('exterior_paused_in_dungeon','_suspend_exterior_actors()' in script['exo_dungeon/module/entrypoint.gd'] and '_resume_exterior_actors()' in script['exo_dungeon/module/entrypoint.gd'])
check('dungeon_clock_and_city_tick_isolated','if _dungeon_inside():\n\t\tif exo_core!=null:' in script['convergence/game.gd'])
check('fatal_death_recovery','on_fatal_dungeon_damage' in script['combat/player_combat.gd'] and 'interrupt_active_visit' in script['convergence/game.gd'])
check('outside_snapshot_guard','if not convergence_ready or current_region<0 or _dungeon_inside():return' in script['convergence/game.gd'])
check('no_extra_save_in_dungeon_instance','FileAccess.open(' not in script['exo_dungeon/runtime/dungeon_instance.gd'] and 'FileAccess.open(' not in script['exo_dungeon/module/entrypoint.gd'])
check('feature_flags_available',all(k in (R/'project.godot').read_text() for k in ['r6/dungeon_encounters_enabled=true','r6/dungeon_atomic_rewards_enabled=true']))
check('qa_native_script_ready','C03_R6_NATIVE=' in script['exo_dungeon/tests/qa_c03_r6_native.gd'])
check('2019to2026_provenance_docs_preserved',all((R/n).is_file() for n in ['LICENCAS-09.md','exo_creature_harmonizacao02/docs/PROVENIENCIA-COMERCIAL.md']))
# Basic lexical balance: useful static warning only, not a GDScript parser.
lex_fail=[]
for n in ['exo_dungeon/module/entrypoint.gd','exo_core/core.gd','convergence/game.gd','inventory.gd','exo_dungeon/runtime/dungeon_instance.gd','exo_dungeon/runtime/exploration_logic.gd']:
 lines=script[n].splitlines()
 # Blocks have indented noncomment child; don't inspect inline colon scopes.
 if '\t ' in script[n] and n.startswith('exo_dungeon/'):
  lex_fail.append(n)
check('no_suspicious_tabs_in_new_dungeon_code',not lex_fail)
report={'suite':'C03_R6_STATIC_SOURCE_AUDIT','base_r5_sha256':base_sha,'checks':checks,'pass':sum(checks.values()),'fail':sum(not x for x in checks.values()),'failing':[k for k,v in checks.items() if not v],'r5_changed_files':changed_files,'r5_deleted_files':missing_files,'gd_scripts_scanned':len(script),'json_scanned':len(list(R.rglob('*.json'))),'json_errors':json_bad,'missing_preloads':missing_preloads,'native_engine':'NOT_RUN','limitations':'Static Python checks are NOT GDScript parser, scene boot, gameplay, physics, real IO or FPS measurements.'}
out=R/'C03_TRANSFERENCIA/QA-C03-ALFA-R6-STATIC.json';out.write_text(json.dumps(report,ensure_ascii=False,indent=2))
print(json.dumps({k:report[k] for k in ['pass','fail','failing','gd_scripts_scanned','json_scanned','missing_preloads']},ensure_ascii=False))
sys.exit(report['fail']>0)
