#!/usr/bin/env python3
"""Modelo adversarial INDEPENDENTE em Python, nao executa GDScript nem Godot.
Reproduz topologia/locks/fisica analitica para amostragem massiva de escolhas RNG.
Uso: python exo_dungeon/tests/stress_reference.py --samples 36000
"""
import argparse, collections, hashlib, json, math, random, statistics, time, pathlib
DIRS=((1,0),(-1,0),(0,1),(0,-1))
FAMILIES=("ruins","cavern","temple","sect_hideout","mine","tomb")

def floor_plan(rng, floor, count, family, final):
    rooms=[dict(id=f'F{floor:02}-R00',floor=floor,gx=0,gz=0,depth=0,parent=None,kind='entrance',keys=[],width=10)]
    positions={(0,0)}; edges=[]
    for i in range(1,count):
        opts=[]
        for idx,r in enumerate(rooms):
            for dx,dz in DIRS:
                p=(r['gx']+dx,r['gz']+dz)
                if abs(p[0])<=10 and abs(p[1])<=10 and p not in positions:opts.append((idx,p))
        if not opts:return None
        if i==2:
            deeper=[choice for choice in opts if rooms[choice[0]]['depth']>=1]
            if deeper:opts=deeper
        pi,(x,z)=rng.choice(opts); parent=rooms[pi]
        room=dict(id=f'F{floor:02}-R{i:02}',floor=floor,gx=x,gz=z,depth=parent['depth']+1,parent=parent['id'],kind='common',keys=[],width=rng.choice([8,10,12]))
        rooms.append(room);positions.add((x,z));edges.append(dict(a=parent['id'],b=room['id'],requires='',secret=False,kind='corridor'))
    existing={frozenset([e['a'],e['b']]) for e in edges}
    for i,a in enumerate(rooms):
        for b in rooms[i+1:]:
            if abs(a['gx']-b['gx'])+abs(a['gz']-b['gz'])==1 and frozenset([a['id'],b['id']]) not in existing and rng.random()<0.34:
                edges.append(dict(a=a['id'],b=b['id'],requires='',secret=False,kind='corridor'))
    goal=max(rooms[1:],key=lambda r:r['depth']);goal['kind']='boss' if final else 'stairs'
    for room in rooms[1:]:
        if room==goal:continue
        roll=rng.random()
        if family=='mine' and roll<0.25:room['kind']='resource'
        elif family=='cavern' and roll<0.20:room['kind']='natural_hazard'
        elif family=='temple' and roll<0.25:room['kind']='shrine'
        elif family=='sect_hideout' and roll<0.27:room['kind']='training'
        elif family=='tomb' and roll<0.23:room['kind']='trap'
        elif roll<0.27:room['kind']='combat'
        elif roll<0.42:room['kind']='treasure'
        elif roll<0.54:room['kind']='rest'
        elif roll<0.65:room['kind']='puzzle'
        elif roll<0.76:room['kind']='trap'
    by={r['id']:r for r in rooms}
    route=[goal['id']];cur=goal
    while cur['parent'] is not None:
        route.append(cur['parent']);cur=by[cur['parent']]
    route=route[::-1]
    main=set(route)
    secret_candidates=[r for r in rooms[1:] if r['id'] not in main and not any(k['parent']==r['id'] for k in rooms)]
    if secret_candidates and rng.random()<dict(ruins=.76,cavern=.58,temple=.64,sect_hideout=.55,mine=.53,tomb=.70)[family]:
        sec=rng.choice(secret_candidates);sec['kind']='secret'
        for e in edges:
            if sec['id'] in (e['a'],e['b']):e['secret']=True
    if goal['depth']>=3 and rng.random()<0.78:
        split=max(2,len(route)//2);target=route[split]
        key=f'key_F{floor:02}_{target}'
        subtree={target}
        change=True
        while change:
            change=False
            for room in rooms:
                if room['id'] not in subtree and room['parent'] in subtree:
                    subtree.add(room['id']);change=True
        safe=[r for r in rooms if r['id'] not in subtree and r['kind']!='secret']
        possible=[r for r in safe if r['id']!=route[split-1]]
        holder=max(possible,key=lambda r:r['depth']) if possible else by[route[split-1]]
        if holder['depth']<1:holder=by[route[split-1]]
        holder['keys'].append(key)
        for e in edges:
            if (e['a'] in subtree)!=(e['b'] in subtree):e['requires']=key
    return dict(rooms=rooms,links=edges,entry=rooms[0]['id'],goal=goal['id'],route=route)

def walk(plan, allow_key=True, banned=None, no_secret=True):
    by={r['id']:r for r in plan['rooms']};reached={plan['entry']};keys=set();loops=0
    while loops<len(by)*3:
        old=(len(reached),len(keys));loops+=1
        if allow_key:
            for rid in tuple(reached):keys.update(k for k in by[rid]['keys'] if k!=banned)
        for e in plan['links']:
            if no_secret and e['secret']:continue
            if e['requires'] and e['requires'] not in keys:continue
            if e['a'] in reached:reached.add(e['b'])
            if e['b'] in reached:reached.add(e['a'])
        if (len(reached),len(keys))==old:break
    return reached,keys

def validate(plan):
    issues=[];by={r['id']:r for r in plan['rooms']}
    if len(by)!=len(plan['rooms']):issues.append('duplicate_room')
    if len({(r['floor'],r['gx'],r['gz']) for r in plan['rooms']})!=len(plan['rooms']):issues.append('overlap')
    if plan['entry'] not in by or plan['goal'] not in by:return ['missing_endpoints']
    held={k:r['id'] for r in plan['rooms'] for k in r['keys']}; locks={e['requires'] for e in plan['links'] if e['requires']}
    for unused in (set(held)-locks):issues.append('orphan_key')
    for e in plan['links']:
        if e['a'] not in by or e['b'] not in by:return ['bad_endpoint']
        if e['requires'] and e['requires'] not in held:issues.append('missing_key')
        if e['secret'] and not (by[e['a']]['kind']=='secret' or by[e['b']]['kind']=='secret'):issues.append('bad_secret')
        if e['kind']=='corridor':
            a,b=by[e['a']],by[e['b']]
            if a['floor']!=b['floor'] or abs(a['gx']-b['gx'])+abs(a['gz']-b['gz'])!=1:issues.append('bad_corridor')
            if (16-(a['width']+b['width'])/2)<3.9:issues.append('no_corridor_clearance')
            # 3.2m entre trilhos e 3.2m abertura: jogador medio ~0.8m cabe.
            if a['width']<8 or b['width']<8:issues.append('invalid_width')
    reached,keys=walk(plan)
    if plan['goal'] not in reached:issues.append('goal_unreachable')
    if any(r['id'] not in reached and r['kind']!='secret' for r in plan['rooms']):issues.append('required_room_unreachable')
    if locks and plan['goal'] in walk(plan,False)[0]:issues.append('lock_bypass')
    for k in locks:
        before,_=walk(plan,True,banned=k)
        if held[k] not in before:issues.append('self_locked_key')
        for e in plan['links']:
            if e['requires']==k and not e['secret'] and ((e['a'] in before)==(e['b'] in before)):
                issues.append('ineffective_or_unreachable_gate')
    # Com todas as chaves, todas as salas secretas devem ter um link fisico alcancavel.
    reached_all,_=walk(plan,no_secret=False)
    for r in plan['rooms']:
        if r['kind']=='secret' and r['id'] not in reached_all:issues.append('dead_secret')
    return issues

def generate(seed,family,floors,count):
    rng=random.Random(int.from_bytes(hashlib.sha256(f'{seed}/{family}'.encode()).digest()[:8],'big'))
    all_rooms=[];all_edges=[];floor_plans=[]
    for fi in range(floors):
        f=floor_plan(rng,fi,count,family,fi==floors-1)
        if f is None:return None
        floor_plans.append(f);all_rooms.extend(f['rooms']);all_edges.extend(f['links'])
        if fi>0:all_edges.append(dict(a=floor_plans[fi-1]['goal'],b=f['entry'],kind='stairs_portal',requires='',secret=False))
    return dict(rooms=all_rooms,links=all_edges,entry=floor_plans[0]['entry'],goal=floor_plans[-1]['goal'],floor_plans=floor_plans)

def main():
    ap=argparse.ArgumentParser();ap.add_argument('--samples',type=int,default=36000);ap.add_argument('--output',default='');args=ap.parse_args()
    started=time.perf_counter(); errors=collections.Counter();perfamily=collections.Counter(); samples=0
    gates=0;secret=0;stairs=0;room_totals=0; loops_total=0;short_boss=0;unoriginal=0
    signatures=set();min_rooms=10**9; max_rooms=0; adversarial=0; caught=0
    for seed in range(args.samples):
        family=FAMILIES[seed%len(FAMILIES)];floors=1+seed%4; count=5+(seed*7)%20
        p=generate(seed,family,floors,count)
        samples+=1
        if p is None:errors['generator_failed']+=1;continue
        issues=validate(p)
        for issue in issues:errors[issue]+=1
        perfamily[family]+=1
        g={e['requires'] for e in p['links'] if e['requires']}
        gates+=bool(g);secret+=any(r['kind']=='secret' for r in p['rooms'])
        stairs+=sum(e['kind']=='stairs_portal' for e in p['links'])
        room_totals+=len(p['rooms']);min_rooms=min(min_rooms,len(p['rooms']));max_rooms=max(max_rooms,len(p['rooms']))
        loops_total+=len(p['links'])-len(p['rooms'])+1
        if p['floor_plans'][-1]['route'].__len__()<=2:short_boss+=1
        sig=repr([(r['floor'],r['gx'],r['gz'],r['kind'],r['width'],tuple(r['keys'])) for r in p['rooms']])+repr(p['links'])
        if sig in signatures:unoriginal+=1
        signatures.add(sig)
        if seed%250==0:
            bad=dict(p,links=[dict(e) for e in p['links']]);bad['links']=[e for e in bad['links'] if e['kind']=='stairs_portal']
            adversarial+=1;caught+=bool(validate(bad))
            if g:
                # Remover uma fechadura aleatoria. O atalho deve ser denunciado quando criar desvio.
                changed=dict(p,links=[dict(e) for e in p['links']]);target=next(e for e in changed['links'] if e['requires'] and not e['secret'])
                changed['links'].remove(target);target['requires']='';changed['links'].append(target)
                adversarial+=1
                caught+=bool(validate(changed))
    duration=time.perf_counter()-started
    result=dict(suite='EXO_DUNGEON_PYTHON_REFERENCE_STRESS',scope='SURROGATE_PYTHON_NOT_GDSCRIPT',attempted=samples,generated=samples-errors['generator_failed'],families=dict(perfamily),issues=dict(errors),pass_reference_model=not errors,distinct_signatures=len(signatures),duplicate_signatures=unoriginal,any_gate=gates,has_secret=secret,total_links_cycles=loops_total,rooms_min=min_rooms,rooms_max=max_rooms,rooms_mean=round(room_totals/max(1,samples),2),floor_transitions=stairs,shallow_goals=short_boss,adversarial_trials=adversarial,adversarial_rejected=caught,duration_seconds=round(duration,2),native_godot_status='NOT_RUN',notes='Simulacao em Python com RNG proprio; NAO avalia GDScript nativo, parser, fisica ou saves reais.')
    out=pathlib.Path(args.output or pathlib.Path(__file__).resolve().parents[2]/'evidence'/'QA-REFERENCIA-MASSIVO.json');out.parent.mkdir(parents=True,exist_ok=True);out.write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n');print(json.dumps(result,ensure_ascii=False))
    if errors or caught<adversarial:raise SystemExit(1)
if __name__=='__main__':main()
