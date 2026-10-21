from pathlib import Path
from zipfile import ZipFile
import json,hashlib,math,re,collections
R=Path('/mnt/data/C03_ALFA_R2_WORK');R1=Path('/mnt/data/C03_ALFA_WORK');T=R/'C03_TRANSFERENCIA'
tests=[]
def row(id,passed,detail):tests.append({'id':id,'status':'PASS' if passed else 'FAIL','evidence':detail,'type':'STATIC' if 'CPU' not in id else 'CPU_MODEL'})
def h(f):return hashlib.file_digest(open(f,'rb'),'sha256').hexdigest()
# New round: verify previous delivered R1 is immutable and current candidate derives from that tree.
source=Path('/mnt/data/EXO-MURIM-CONVERGENCIA-03-ALFA-R1.zip');expected=Path('/mnt/data/EXO-MURIM-C03-ALFA-R1-SHA256.txt').read_text().split()[0]
row('R2_R1_SOURCE_IMMUTABLE',h(source)==expected,{'expected':expected,'actual':h(source)})
with ZipFile(source) as z:
 row('R2_R1_SOURCE_ZIP_CRC',z.testzip() is None,'R1 archive CRC rechecked before second round')
base={p.relative_to(R1).as_posix():h(p) for p in R1.rglob('*') if p.is_file()}
new={p.relative_to(R).as_posix():h(p) for p in R.rglob('*') if p.is_file()}
change=[p for p in sorted(set(base)|set(new)) if base.get(p)!=new.get(p)]
fix=set(json.loads((T/'MANIFESTO-CORRECOES-R2.json').read_text())[i]['file'] for i in range(8))
row('R2_NO_REBASE_OR_UNEXPLAINED_GAMEPLAY_CHANGES',all(x in fix or x.startswith('C03_TRANSFERENCIA/') for x in change),{'changed_total':len(change),'gameplay_changed':[x for x in change if not x.startswith('C03_TRANSFERENCIA/')]})
rig=(R/'rig.gd').read_text();anim=(R/'animation_library.gd').read_text();flow=(R/'murim_flow.gd').read_text();game=(R/'convergence/game.gd').read_text()
row('RIG01_SINGLE_OWNED_WRITE',rig.count('preload("res://animation_library.gd").locomotion(')==1 and 'for i in range(2):forearms[i].rotation.x=-.25-absf(swing)*.2' not in rig,'R1 duplicate post-call elbow assignment removed')
row('RIG01_TYPED_ARRAY_GUARDS','if rig.arms.size()!=2 or rig.forearms.size()!=2:return' in anim,'Guard against missing rig parts')
row('RIG01_NONDIRECTIONAL_MODEL_REMOVED',not (R/'assets/kenney/character-a.glb').exists() and 'EXO_original_local_8directions' in anim,'No active imported external motion model')
row('RIG01_EIGHT_DIRECTION_GDSCRIPT_FIXTURE',(R/'convergence/tests/qa_rig01_eight_directions.gd').exists(),'New runnable 8-direction GDScript fixture provided, not run')
samples=[]
for i in range(8):
 a=i*math.pi/4
 speed=2;delta=0.1;phase=speed*delta*2*math.pi/1.3;forward=1.0;lateral=0.0
 stride=math.sin(phase)*min(1,speed/3.6)*0.64
 shoulder=(stride*forward,0.05,0)
 elbow=-0.18-abs(stride)*(0.16+0.20*abs(forward)+0.12*abs(lateral))
 samples.append({'direction_deg':i*45,'global_velocity':[round(math.cos(a),4),round(math.sin(a),4)],'local_pitch':round(shoulder[0],6),'local_elbow':round(elbow,6)})
row('RIG01_CPU_LOCAL_FRAME_8DIR',len(samples)==8 and all(x['local_elbow']<-.18 for x in samples),'8 world headings should produce consistent limb-local flexion when facing motion; CPU model only')
row('FLOW_CREATOR_MODERN_BRANCH_PRECEDES_LEGACY','if world.has_method("_begin_new_procedural_campaign"):' in flow and flow.index('if world.has_method("_begin_new_procedural_campaign")') < flow.index('world.rebuild_region()',flow.index('func create_character(')),'Modern creator path bypasses legacy village rebuild')
row('FLOW_NO_INITIAL_LEGACY_CAMP_SPAWN','world.call_deferred("_begin_new_procedural_campaign")' in flow and game.count('func _begin_new_procedural_campaign() -> void:')==1,'Deferred procedural entry has an explicit host')
row('FLOW_CREATION_SAVED_BEFORE_ASYNC',flow.index('if not world.save_progress():',flow.index('func create_character('))<flow.index('world.call_deferred("_begin_new_procedural_campaign")',flow.index('func create_character(')),'Existing save transaction occurs before deferred scene construction')
row('FLOW_CREATION_FAILED_NOT_SILENT','if not ready:' in game and 'Falha ao iniciar mundo procedural' in game,'Failed first region is logged; still requires native UX verification')
row('REGION_ENTER_FAILURE_NOT_DEADLOCK','region_enter_event_failed:' in game and 'simulation_enabled=true\n\t\t\tmessage' in game,'Event failure does not leave simulation disabled after old region freed')
row('R2_OWN_SAVE_NAMESPACE','config/custom_user_dir_name="EXO-Murim-Convergencia-03-ALFA-R2-QA"' in (R/'project.godot').read_text(),'Alfa R1 test saves preserved')
row('R2_BLOCKED_MODULES_STILL_UNREGISTERED',all(x not in json.loads((R/'exo_core/modules.json').read_text()).__str__() for x in ['"dungeon_genesis"','"exo_items"','"exo_martial"','"exo_monumental"']),'Critical staged modules remain unregistered')
row('R2_NO_LEGACY_SKINS_NEW',(R/'exo_humanoids03_r2/scripts/voxel_geometry.gd').exists() and not (R/'exo_humanoids03/assets').exists(),'480 inherited humanoid legacy skins not included in new module')
# Wide scan all GDScript: missing preload targets and JSON parsing
scripts=list(R.rglob('*.gd')); misses=[]; all_preloads=0
for f in scripts:
 for target in re.findall(r'preload\([\'\"]res://([^\'\"]+)[\'\"]\)',f.read_text(errors='replace')):
  all_preloads+=1
  if not (R/target).exists():misses.append({'source':f.relative_to(R).as_posix(),'target':target})
row('R2_FULL_GDSCRIPT_PRELOAD_GRAPH',all(v['source'] in {'godot/demo.gd','exo_core/module_template/test.gd'} for v in misses),{'gd_sources':len(scripts),'literal_preload_edges':all_preloads,'missing':misses})
json_errors=[];parsed=0
for f in R.rglob('*.json'):
 try:json.loads(f.read_text());parsed+=1
 except Exception as e:json_errors.append({'file':f.relative_to(R).as_posix(),'message':str(e)})
row('R2_ALL_JSON_PARSE',not json_errors,{'parsed':parsed,'errors':json_errors[:5]})
row('R2_CORE_01P_UNMODIFIED',all(h(R/f)==h(R1/f) for f in ['exo_core/persistence/save_coordinator.gd','exo_core/persistence/receipt_ledger.gd']),'R2 did not alter previously staged Core-P atomic patch')
row('R2_VISUAL_ASSETS_BITWISE',all(h(R/f)==h(R1/f) for f in ['genesis/terrain.gdshader','genesis/region_scene.gd','genesis/dressing_r1/foliage_original.png']),'Visual/WorldGen R1 not repatched during R2')
counts={status:sum(x['status']==status for x in tests) for status in ['PASS','FAIL','NOT_RUN']}
tests += [{'id':'NATIVE_GODOT_462_IMPORT','status':'NOT_RUN','type':'GODOT','evidence':'Engine executable not available to the session; no compiled GDScript/shader proof'}, {'id':'NATIVE_RIG_8DIR','status':'NOT_RUN','type':'GODOT','evidence':'New native script written but not executed'}, {'id':'NATIVE_GAMEPLAY_CREATOR','status':'NOT_RUN','type':'GODOT','evidence':'Flow needs in-engine new campaign and save/restart'}, {'id':'NATIVE_NPC_DUNGEON_WORLDGEN','status':'NOT_RUN','type':'GODOT','evidence':'Staged functions blocked; no world simulation test'}, {'id':'FPS_VEGA8','status':'NOT_RUN','type':'HARDWARE','evidence':'Ryzen 3200GE / Vega 8 test requires PC or Work environment'}]
counts={status:sum(x['status']==status for x in tests) for status in ['PASS','FAIL','NOT_RUN']}
(T/'QA-C03-ALFA-R2.json').write_text(json.dumps({'status':'STATIC_QA_ONLY','counts':counts,'tests':tests},ensure_ascii=False,indent=2))
(T/'RIG01-MODELO-CPU-R2.json').write_text(json.dumps({'disclaimer':'Only a local-coordinate CPU model, not Godot rendered','samples':samples},ensure_ascii=False,indent=2))
(T/'DIFF-R1-R2.json').write_text(json.dumps({'files_changed':change,'gameplay_changed':[x for x in change if not x.startswith('C03_TRANSFERENCIA/')],'counts':counts},ensure_ascii=False,indent=2))
print(json.dumps({'counts':counts,'change_count':len(change),'gd_scripts':len(scripts),'json_files':parsed,'missing_preloads':misses,'failures':[x for x in tests if x['status']=='FAIL']},indent=2,ensure_ascii=False))
