#!/usr/bin/env python3
"""G0: integridade e proveniencia. Nao substitui carregar no Godot."""
from pathlib import Path
import json,hashlib,math,re,sys,collections
ROOT=Path(__file__).resolve().parents[1]
r={'kind':'forja_02_integrity_and_static','passed':0,'failed':[],'measures':{}}
def check(cond, tag):
 if cond:r['passed']+=1
 else:r['failed'].append(tag)
c=json.loads((ROOT/'catalog.json').read_text())
a=c['assets'];ids=[x['id'] for x in a]
check(c['version']=='2.0','version_2');check(len(a)==121,'121_assets');check(len(set(ids))==len(ids),'unique_ids')
for item in a:
 path=ROOT/item['file'];check(path.is_file(),'exists_'+item['id'])
 b=item.get('bounds')
 check(isinstance(b,list) and len(b)==2 and all(len(row)==3 for row in b) and all(math.isfinite(float(v)) for row in b for v in row) and all(x<y for x,y in zip(b[0],b[1])),'bounds_'+item['id'])
 check(item['collision'] in ['none','triangle_static','box_leaf','box_static','trunk_only','stems_only','ramp_stairs'],'collision_'+item['id'])
new=json.loads((ROOT/'docs/ASSETS-02-MANIFEST.json').read_text())
check(len(new)==34,'34_generated_assets')
for v in new:
 check(v['id'] in ids,'new_asset_in_catalog_'+v['id'])
 check(v['triangles']>10 and v['mesh_parts']>=3,'not_merely_recolor_'+v['id'])
 check(v['category'] in ['architecture','facade','furniture','street','market','courtyard','workshop','nature_detail'],'valid_category_'+v['id'])
legacy=json.loads((ROOT/'docs/MANIFEST-FONTE-HERDADA.json').read_text())['files']
for filename, digest in legacy.items():
 if filename=='catalog.json':continue # only intentional modification of an inherited file
 f=ROOT/filename;check(f.is_file() and hashlib.sha256(f.read_bytes()).hexdigest()==digest,'legacy_changed_'+filename)
check(len(legacy)==388,'legacy_manifest_size')
for code in ['forja/forja_planner.gd','forja/forja_builder.gd','forja/detail_pass.gd','qa/run_headless.gd','forja/laboratorio.gd']:
 s=(ROOT/code).read_text()
 check('extends ' in s,'gd_extends_'+code)
 check('res://forja/' not in s or (ROOT/'forja').exists(),'gd_paths_'+code)
 check('\r' not in s and '\t' in s,'gd_indent_'+code)
 check(s.count('(')==s.count(')'),'parentheses_'+code)
 check(s.count('[')==s.count(']'),'brackets_'+code)
 check(s.count('{')==s.count('}'),'braces_'+code)
p=(ROOT/'forja/forja_planner.gd').read_text();b=(ROOT/'forja/forja_builder.gd').read_text();d=(ROOT/'forja/detail_pass.gd').read_text()
check('SCHEMA_VERSION = 2' in p,'schema_two');check('terrain_samples_must_be_four' in p,'grades_malformed_reject');check('atomic_batch_rejected' in p,'atomic')
check('Kit.build_house' in b,'reuses_approved_houses');check('Details.apply' in b,'real_detail_pass');check('AnchorGate' in b,'courtyard_gate_anchor')
check('create_trimesh_collision' not in d,'new_details_no_triangle_collision');check('BoxShape3D' in d,'single_obstacle_collision')
for asset in re.findall(r'"([a-z][a-z0-9_]+)"',d):
 if asset in ['dwelling','standard','merchant','teahouse','forge','herb_shop','inn','courtyard','low','medium','high','veranda'] :continue
 if asset in ['forja_asset_ids','detail_profile','essential_count','decor_seed','archetype','palette','stories','width_m','entrance_local','SimpleStaticObstacle','ForjaDetails','ok','count','code','detail_budget_exceeded']:continue
 if asset.startswith(('roof_','market_','public_','courtyard_','stone_','tea_','shop_','herb_','herbalist_','blacksmith_','smith_','bronze_','grain_','silk_','woven_','village_','bamboo_','merchant_')):
  check(asset in ids,'reference_missing_'+asset)
r['measures']={'inherited_preserved':len(legacy)-1,'legacy_catalog_intentionally_extended':True,'catalog_models':len(a),'new_models':len(new),'total_new_triangles':sum(v['triangles'] for v in new),'godot_engine_executed':False}
(ROOT/'qa/static_results_v2.json').write_text(json.dumps(r,indent=2,ensure_ascii=False)+'\n')
print(json.dumps(r,indent=2,ensure_ascii=False));sys.exit(bool(r['failed']))
