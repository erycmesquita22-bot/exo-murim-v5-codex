#!/usr/bin/env python3
"""Static regressions and archive contract for EXO Settlement Genesis 05.
Does NOT claim Godot compilation, physics or gameplay verification.
"""
from __future__ import annotations
import os,json,hashlib,sys,collections
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]

def digest(path:Path)->str:return hashlib.sha256(path.read_bytes()).hexdigest()
def check() -> dict:
    errors=[];counts=collections.Counter()
    for seed in ('101','816204'):
        file=ROOT/'genesis'/('atlas_seed_'+seed+'.json')
        a=json.loads(file.read_text())
        rs=a['regions'];counts['atlas_regions']+=len(rs)
        if len(rs)!=88:errors.append(f'{seed}: region_count')
        kk=collections.Counter(r['kind'] for r in rs)
        for k,n in {'settlement':23,'ruins':12,'dungeon_approach':10,'wild':43}.items():
            if kk[k]!=n:errors.append(f'{seed}: quota {k}: {kk[k]}')
        if len(set(r['id'] for r in rs))!=88:errors.append(f'{seed}: region_ids')
        portals=a['portals'];counts['portal_contracts']+=len(portals)
        for p in portals:
            pa,pb=p['from_a'],p['from_b'];aa,bb=p['a'],p['b']
            if not ((abs(pa[0])>=253 and abs(pb[0])>=253 and pa[0]==-pb[0]) or (abs(pa[1])>=253 and abs(pb[1])>=253 and pa[1]==-pb[1])):errors.append(f'{seed}: portal facing axis {aa}-{bb}')
            if not any(e['gate_id']==p['id'] for e in rs[aa]['entrances']):errors.append(f'{seed}: absent entrance A')
            if not any(e['gate_id']==p['id'] for e in rs[bb]['entrances']):errors.append(f'{seed}: absent entrance B')
            if p['width_m']<=0:errors.append(f'{seed}: portal width')
        adj={r['id']:set(e['neighbor'] for e in r['entrances']) for r in rs}
        seen={a['start_region']};front=list(seen)
        for current in front:
            for nb in adj[current]:
                if nb not in seen:seen.add(nb);front.append(nb)
        if len(seen)!=88:errors.append(f'{seed}: disconnected graph {len(seen)}')
        if any(len(a_)>4 for a_ in adj.values()):errors.append(f'{seed}: degree >4')
        counts['settlement_sites']+=kk['settlement']
        counts['river_edges']+=len(a['rivers_macro'])
    planner=(ROOT/'genesis/settlements/settlement_planner.gd').read_text()
    required=['const VERSION = 2','_reserve_well','no_safe_well_site','lot_blocks_other_door','lot_blocks_fixture_access','fixture_gate_road','insufficient_valid_parcels','blocks_existing_access']
    for token in required:
        if token not in planner:errors.append('missing planner safeguard '+token)
    v=json.loads((ROOT/'SETTLEMENT-VERSION.json').read_text())
    if v.get('planner_version')!=2:errors.append('incorrect planner_version')
    if v.get('validation_status')=='godot_certified':errors.append('false certification')
    # This release may not change gameplay systems or the interface of the 88-region atlas.
    for rel in ('genesis/world_planner.gd','genesis/region_scene.gd','genesis/region_data.gd','genesis/pilot.json','project.godot'):
        if not (ROOT/rel).is_file():errors.append('missing '+rel)
    for p in ROOT.rglob('*.json'):
        try:json.loads(p.read_text())
        except Exception as e:errors.append(f'bad json: {p.relative_to(ROOT)}: {e}')
        counts['json_parsed']+=1
    return {'kind':'STATIC_NOT_GODOT','status':'PASS' if not errors else 'FAIL','errors':errors[:100],'counts':dict(counts),'version':v}
if __name__=='__main__':
    report=check();p=ROOT/'SETTLEMENT-STATIC-05.json';p.write_text(json.dumps(report,indent=2,ensure_ascii=False));print(json.dumps(report,ensure_ascii=False));sys.exit(0 if report['status']=='PASS' else 1)
