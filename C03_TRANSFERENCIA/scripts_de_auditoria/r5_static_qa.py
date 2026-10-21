from pathlib import Path
import sys
import json,hashlib,struct,re,zipfile,datetime
root=Path(sys.argv[1]).resolve() if len(sys.argv)>1 else Path(__file__).resolve().parents[2]
base=sys.argv[2] if len(sys.argv)>2 else str(root.parent/'EXO-MURIM-CONVERGENCIA-03-ALFA-R4.zip')
checks=[]
def check(id,cond,detail=''):
 checks.append({'id':id,'status':'PASS' if cond else 'FAIL','evidence':detail})
with zipfile.ZipFile(base) as z:
 check('R5_R4_BASE_ZIP_CRC',z.testzip() is None)
 source_names=set(z.namelist())
 changed=[]
 for info in z.infolist():
  p=root/info.filename
  if not p.exists() or (p.is_file() and hashlib.sha256(p.read_bytes()).digest()!=hashlib.sha256(z.read(info.filename)).digest()):changed.append(info.filename)
 expected={'exo_bestiary/integration/regional_fauna_actor.gd','exo_core/integrations/creature_visuals.gd','exo_core/modules.json','project.godot','C03_TRANSFERENCIA/ESTADO-INTEGRACAO-C03.json','C03_TRANSFERENCIA/INSTRUCOES-CONTINUACAO-WORK.md'}
 check('R5_STRICT_R4_DELTA',set(changed)==expected,str(sorted(changed)))
 check('R5_R4_FROZEN_BESTIARY_GENESIS',all(n not in changed for n in ['regional_ecology/director.gd','regional_ecology/territories.gd','regional_ecology/rewards.gd','inventory.gd','exo_core/event_bus.gd','exo_core/integrations/monumental_plans.gd','convergence/game.gd']))
 check('R5_R4_ASSETS_UNMODIFIED',all(not n.lower().endswith(('.glb','.png','.jpg','.ogg','.wav','.gdshader','.tscn')) for n in changed))
 check('R5_NO_DELETIONS',all((root/n).exists() for n in source_names))
check('R5_BASE_SHA_VALID',hashlib.sha256(open(base,'rb').read()).hexdigest()=='08e2f49e6e9ed87cc08d1e25fc5d31808b17171fc3a3a282cc8a50f1efca28e6')
mods=json.loads((root/'exo_core/modules.json').read_text())
ids=[x['id'] for x in mods]
check('R5_MOD_COUNT_PRESERVED',len(ids)==17 and len(set(ids))==17, str(ids))
svcs=[s for m in mods for s in m.get('services',[])]
check('R5_SERVICE_OWNERS_UNIQUE',len(svcs)==len(set(svcs)))
vc=next(m for m in mods if m['id']=='creature_visuals')
check('R5_CORE_VISUAL_REGISTRY',vc['version']=='1.1.0' and vc['runtime_binding']=='res://exo_creature_harmonizacao02/integration/runtime_visual_binding.gd')
check('R5_CORE_HAS_BESTIARY',any(x['id']=='bestiary' and x.get('integration_mode','').startswith('regional_fauna') for x in mods))
s=(root/'exo_bestiary/integration/regional_fauna_actor.gd').read_text()
b=(root/'exo_creature_harmonizacao02/integration/runtime_visual_binding.gd').read_text()
check('R5_VISUAL_ACTOR_SETUP',s.index('configure(profile,variant)')<s.index('_install_harmonized_visual('))
check('R5_VISUAL_CALLS_SUPER',s.count('super._physics_process(delta)')==1 and '    _r5_visual_tick(delta)' in s)
check('R5_VISUAL_HOST_HP_PERSISTED',all(x in s for x in ['world.enemy_defeated(self)','world.damage_player','revive_after_failed_commit','attack_requested.connect','hp=maxi(0,hp-maxi(0,amount))']))
check('R5_VISUAL_NO_ADDITIONAL_LOOT',not any(x in b for x in ['enemy_defeated','reward_claimed','save_progress','mark_collected','damage_player','collect(']))
check('R5_VISUAL_FALLBACK_FLAG','r5/harmonized_creatures_enabled' in s and 'r5/harmonized_creatures_enabled=true' in (root/'project.godot').read_text())
check('R5_VISUAL_FALLBACK_VOXEL','ResourceLoader.exists' in b and 'old.visible = true' in b and 'old.visible = false' in b and 'holder.scale = Vector3.ONE' in b)
check('R5_VISUAL_ORIENTATION_SINGLE_SCALE','holder.scale = Vector3.ONE' in b and 'instance.rotation' not in b and 'instance.scale' not in b)
check('R5_VISUAL_ATTACK_AUTHORITY','_r5_play_action("attack", 0.34)' in s and s.index('if not world.can_hit') < s.index('_r5_play_action("attack", 0.34)') < s.index('world.damage_player'))
check('R5_ANIM_STATE_MACHINE',all(x in s for x in ['_r5_visual_lock','_r5_visual_tick(delta)','_r5_play_action("hit", 0.22)','_r5_play_action("attack", 0.34)']))
check('R5_SCENE_PREFIX_FAIL_CLOSED', 'scene_path.begins_with("res://exo_creature_harmonizacao02/scenes/")' in b and '.ends_with(".tscn")' in b)
check('R5_NATIVE_TEST_PRESENT', (root/'exo_creature_harmonizacao02/tests/qa_c03_r5_visual_runtime.gd').exists())
try:
 parsed=0
 for p in root.rglob('*.json'): json.loads(p.read_text());parsed+=1
 check('R5_ALL_JSON_PARSE',True,str(parsed))
except Exception as exc:check('R5_ALL_JSON_PARSE',False,str(exc))
cat=json.loads((root/'exo_creature_harmonizacao02/data/CATALOGO-CRIATURAS-UNIFICADO.json').read_text())
records=cat['assets_by_species']
check('R5_GLBS_REAL_CATALOG_17',len(records)==17,str(sorted(records)))
missing=['wild_ox','wild_buffalo','qi_serpent']
check('R5_UNCOVERED_BESTIARY_3',all(x not in records for x in missing))
from glob import glob
for species_id,entry in records.items():
 chosen=entry['recommended_variant']
 scene=str(chosen['scene']).replace('res://',''); model=str(chosen['model']).replace('res://','')
 check('R5_SCENE_EXISTS_'+species_id,(root/scene).exists(),scene)
 check('R5_MODEL_EXISTS_'+species_id,(root/model).exists(),model)
 if (root/scene).exists():
  ts=(root/scene).read_text()
  check('R5_SCENE_MODEL_REF_'+species_id, chosen['model'] in ts and 'ForwardMinusZ' in ts and 'rotation = Vector3(0, 1.5707963, 0)' in ts,scene)
paths=sorted((root/'exo_creature_harmonizacao02/models').rglob('*.glb'))
check('R5_HARMONIZED_MODELS_20',len(paths)==20,str(len(paths)))
for p in paths:
 by=p.read_bytes();label=p.relative_to(root).as_posix()
 check('R5_GLB_HEADER_'+p.parent.name+'_'+p.stem,len(by)>=20 and by[:4]==b'glTF' and struct.unpack_from('<I',by,8)[0]==len(by),label)
 if len(by)>=20 and by[:4]==b'glTF':
  chunklen,chunkid=struct.unpack_from('<I4s',by,12)
  try:
   js=json.loads(by[20:20+chunklen]); ok=chunkid==b'JSON' and len(js.get('meshes',[]))>0 and len(js.get('animations',[]))>=3
  except Exception:ok=False
  check('R5_GLB_GLTF_MESH_ANIM_'+p.parent.name+'_'+p.stem,ok,str(p))
preloads=list(root.rglob('*.gd'))
unresolved=[]
for p in preloads:
 for ref in re.findall(r'preload\(\s*"res://([^\"]+)"\s*\)',p.read_text(errors='replace')):
  if not (root/ref).exists():unresolved.append((str(p.relative_to(root)),ref))
check('R5_NEW_SCRIPT_PRELOADS_RESOLVED',all('runtime_visual_binding' not in x[0] and 'regional_fauna_actor' not in x[0] for x in unresolved),str([x for x in unresolved if ('runtime_visual_binding' in x[0] or 'regional_fauna_actor' in x[0])]))
not_run=['GODOT_462_IMPORT','GODOT_R5_NATIVE_MODEL_BIND','GODOT_8_FAUNA_VISIBILITY','GODOT_8DIR_AND_ANIMS','GODOT_COMBAT_LOOT_SAVE_REOPEN','GODOT_FPS_VEGA8','GODOT_RENDER_EIGHT_BIOMES','GODOT_PERSISTENCE_01P','GODOT_CHECK_COMPILATION_AFTER_IMPORT']
record={'project':'EXO-Murim','version':'Convergencia03 ALFA R5','qa_kind':'STATIC_SOURCE_AND_GLB_INTEGRITY','source_zip':'EXO-MURIM-CONVERGENCIA-03-ALFA-R4.zip','source_sha256':hashlib.sha256(open(base,'rb').read()).hexdigest(),'checks':checks,'summary':{'pass':sum(c['status']=='PASS' for c in checks),'fail':sum(c['status']=='FAIL' for c in checks),'not_run_native':len(not_run)},'not_run':[{'id':x,'status':'NOT_RUN','reason':'Godot 4.6.2 Standard nao instalado; ambiente sem acesso a internet'} for x in not_run], 'preload_refs_unresolved_in_full_tree':unresolved}
(dest:=root/'C03_TRANSFERENCIA').mkdir(exist_ok=True)
(dest/'QA-C03-ALFA-R5.json').write_text(json.dumps(record,ensure_ascii=False,indent=2)+'\n')
print(json.dumps({'summary':record['summary'],'failed':[c for c in checks if c['status']=='FAIL'],'unresolved_preload_count':len(unresolved)},ensure_ascii=False,indent=2))
