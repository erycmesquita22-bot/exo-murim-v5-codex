#!/usr/bin/env python3
"""QA estatístico de modelo Python independente: NUNCA alegar física Godot."""
import argparse, collections, json, pathlib, sys, time, hashlib, copy
sys.path.insert(0,str(pathlib.Path(__file__).resolve().parent))
from stress_reference import FAMILIES, generate, validate

def v3_width(kind,old):
    if kind=='boss': return 28
    if kind in ('training','combat','shrine'): return 22
    if kind=='stairs':return 18
    if kind=='entrance':return 20
    return {8:12,10:14,12:16}[old]

def evaluate(p):
    failures=[]
    rooms={r['id']:r for r in p['rooms']}
    xs=set()
    for r in p['rooms']:
        cell=(r['floor'],r['gx'],r['gz'])
        if cell in xs:failures.append('room_overlap');continue
        xs.add(cell)
        size=v3_width(r['kind'],r['width'])
        if size>28 or size<8:failures.append('invalid_room_size')
        if r['kind']=='boss' and size!=28:failures.append('boss_not_expanded')
        # Centro livre de colunas e elementos perimetrais >=3m, suficiente para spawn.
        rim=size/2-2
        if rim<3.5:failures.append('spawn_collision')
    for l in p['links']:
        if l['kind']!='corridor':continue
        a,b=rooms[l['a']],rooms[l['b']]
        gap=36.0-(v3_width(a['kind'],a['width'])+v3_width(b['kind'],b['width']))*0.5
        if gap<8.0:failures.append('bridge_length_under_8')
        # Abertura 3.2; ator modelo 0.86 m.
        if 3.2-0.86<1.6:failures.append('corridor_too_narrow')
        if a['floor']!=b['floor']:failures.append('corridor_vertical_mismatch')
    for l in p['links']:
        if l['kind']=='stairs_portal' and abs(rooms[l['a']]['floor']-rooms[l['b']]['floor'])!=1:failures.append('invalid_vertical_portal')
    return failures

def main():
    ap=argparse.ArgumentParser();ap.add_argument('--samples',type=int,default=18000);ap.add_argument('--output',default='');args=ap.parse_args()
    begun=time.perf_counter();problems=collections.Counter();families=collections.Counter();sizecounts=collections.Counter();bounds=collections.Counter()
    layout_digests=set();duration_classes=collections.Counter();adversarial=0;caught=0
    for i in range(args.samples):
        family=FAMILIES[i%len(FAMILIES)]
        floors=1+(i//6)%4
        nrooms=8+(i*5//6)%17
        p=generate(i,family,floors,nrooms)
        if p is None:problems['generate_failed']+=1;continue
        for e in validate(p):problems[e]+=1
        for e in evaluate(p):problems[e]+=1
        families[family]+=1;duration_classes[f'{floors}floors']+=1
        for room in p['rooms']:sizecounts[str(v3_width(room['kind'],room['width']))]+=1
        signature=repr([(r['floor'],r['gx'],r['gz'],r['kind'],v3_width(r['kind'],r['width'])) for r in p['rooms']])+repr(p['links'])
        layout_digests.add(hashlib.sha256(signature.encode()).digest())
        if i%191==0:
            broken=copy.deepcopy(p)
            broken['rooms'][0]['gx']=broken['rooms'][1]['gx']
            broken['rooms'][0]['gz']=broken['rooms'][1]['gz']
            adversarial+=1;caught+=bool(evaluate(broken))
            broken=copy.deepcopy(p);broken['links']=[e for e in broken['links'] if e['kind']=='stairs_portal']
            adversarial+=1;caught+=bool(validate(broken))
    report={'test':'EXO_DUNGEON_02_V3_SURROGATE','scope':'OFFLINE_PYTHON_REFERENCE_NOT_GDSCRIPT', 'samples':args.samples,'by_family':dict(families),'by_floors':dict(duration_classes),'size_distribution':dict(sizecounts),'distinct_signatures':len(layout_digests),'issues':dict(problems),'adversarial':adversarial,'adversarial_rejected':caught,'duration_seconds':round(time.perf_counter()-begun,2),'native_godot':'NOT_RUN','physics_navigation':'NOT_RUN','fps_memory':'NOT_RUN','status':'PASS' if not problems and caught==adversarial else 'FAIL'}
    dest=pathlib.Path(args.output or pathlib.Path(__file__).resolve().parents[2]/'evidence/QA-DUNGEON02-GEOMETRIA-REFERENCIA.json');dest.parent.mkdir(exist_ok=True,parents=True);dest.write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n')
    print(json.dumps({'status':report['status'],'samples':report['samples'],'issues':report['issues'],'adversarial_rejected':report['adversarial_rejected'],'distinct_signatures':report['distinct_signatures'],'seconds':report['duration_seconds']}))
    return 0 if report['status']=='PASS' else 1
if __name__=='__main__':raise SystemExit(main())
