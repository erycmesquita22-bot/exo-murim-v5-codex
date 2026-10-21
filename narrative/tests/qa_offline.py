#!/usr/bin/env python3
"""Static/independent model QA. Explicitly NOT Godot/GDScript execution."""
from __future__ import annotations
import collections, hashlib, json, os, pathlib, random, re, subprocess, sys, tempfile, time, zipfile
ROOT=pathlib.Path(__file__).resolve().parents[2]
OUT=ROOT/'narrative/tests/qa_offline_result.json'
BASE=pathlib.Path(os.environ.get('EXO_NARRATIVE_BASE_ZIP', str(ROOT.parent/'EXO-Murim-Jornada-Dinamica-01.zip')))
C={'checks':0,'failures':[],'sections':collections.Counter()}
def check(cond,label,section,inc=1):
    C['checks']+=inc; C['sections'][section]+=inc
    if not cond:C['failures'].append(f'{section}: {label}')
def bfs(atlas,start):
    q=collections.deque([start]);seen={start};parent={}
    while q:
        r=q.popleft()
        for portal in atlas['regions'][r]['entrances']:
            n=int(portal['neighbor'])
            if n not in seen:seen.add(n);parent[n]=r;q.append(n)
    return seen,parent
def test_atlases():
    datasets={}
    for suffix in ['101','816204']:
        path=ROOT/f'genesis/atlas_seed_{suffix}.json';a=json.loads(path.read_text());datasets[suffix]=a
        check(len(a['regions'])==88,'88 regions '+suffix,'atlas')
        check(len(set(i['id'] for i in a['regions']))==88,'unique ids '+suffix,'atlas')
        for r in range(88):
            seen,_=bfs(a,r)
            check(len(seen)==88,f'graph disconnected {suffix} r{r}','atlas')
        ruins=[r['id'] for r in a['regions'] if r['kind']=='ruins']
        settlements=[r['id'] for r in a['regions'] if r['kind']=='settlement']
        check(len(ruins)==12 and len(settlements)==23,'quota '+suffix,'atlas')
        for origin in settlements:
            seen,_=bfs(a,origin)
            check(any(r in seen for r in ruins),f'no accessible ruins {suffix}:{origin}','atlas')
    return datasets
def seed_val(seed,char):
    k=f'EXO|NARRATIVE|DESTINY|1|{seed}|{char}'
    state=int(hashlib.sha256(k.encode()).hexdigest()[:8],16)%(2147483647-1)+1
    picks=[]
    for n in [6,5,100]:
        state=(state*48271)%2147483647;picks.append(state%n)
    return tuple(picks)
def test_destiny():
    distributions=collections.Counter()
    for i in range(12000):
        value=seed_val(str(i),'traveler')
        check(value==seed_val(str(i),'traveler'),f'randomness changed {i}','destiny')
        check(0<=value[0]<6 and 0<=value[1]<5 and 0<=value[2]<100,'randomness out of range','destiny')
        distributions[value[0]]+=1
    check(len(distributions)==6,'no diversity','destiny')
    return distributions
def test_receipts():
    ledger=set();influence=collections.Counter();memories=collections.defaultdict(list)
    rng=random.Random(903)
    for i in range(25000):
        id=f'eco/r{rng.randrange(88)}/t{rng.randrange(10)}/m{i%5}/g{i//400+1}/seq{i}'
        faction='caminho_celestial' if i%2 else 'culto_abismo'
        if id not in ledger:
            
            if len(ledger)<12000:
                ledger.add(id);influence[faction]-=1
        before=influence[faction]
        if id in ledger: pass  # replay must be a no-op
        check(influence[faction]==before,'duplicate mutated influence','receipts')
        npc='npc/r%02d/%03d'%((i%300)%88,i%300)
        memories[npc].append({'id':id,'importance':i%8+1,'permanent':i%25==0 and not any(m['permanent'] for m in memories[npc])})
        if len(memories[npc])>16:
            transient=[(m['importance']*1000+ix,ix) for ix,m in enumerate(memories[npc]) if not m['permanent']]
            if transient:memories[npc].pop(min(transient)[1])
        check(len(memories[npc])<=16,'memory exceeded cap','memory')
    check(len(ledger)==12000,'receipt quota failed to stop ledger growth','receipts')
    return {'unique_receipts':len(ledger),'npc_memory_owners':len(memories)}
def test_story_models(atlases):
    count=0
    for a in atlases.values():
        for region in a['regions']:
            if region['kind']!='settlement':continue
            origin=region['id'];seen,_=bfs(a,origin)
            ruins=next((x for x in sorted(seen) if a['regions'][x]['kind']=='ruins'),None)
            check(ruins is not None,'no manual location','stories')
            decisions={};influence=collections.Counter()
            if ruins is not None:
                manual='story/manual/%s/%s'% (a['seed'],ruins)
                if manual not in decisions:
                    decisions[manual]='manual_shared';influence[(ruins,'cronicas_silenciosas')]+=8
                before=influence[(ruins,'cronicas_silenciosas')]
                if manual not in decisions:influence[(ruins,'cronicas_silenciosas')]+=8
                check(before==8 and influence[(ruins,'cronicas_silenciosas')]==8,'manual twice','stories')
            dispute='dispute/%s'%origin
            if dispute not in decisions:
                decisions[dispute]='support_celestial';influence[(origin,'caminho_celestial')]+=10;influence[(origin,'culto_abismo')]-=5
            check(influence[(origin,'caminho_celestial')]==10 and influence[(origin,'culto_abismo')]==-5,'dispute model','stories')
            count+=1
    return count
def test_persistence():
    fixture={'schema':1,'history':[{'id':'quest/a','region':86}],'decisions':{'story/a':{'resolution':'manual_shared'}},'receipts':{'quest/a':True}}
    with tempfile.TemporaryDirectory() as d:
        path=pathlib.Path(d)/'state.json';path.write_text(json.dumps(fixture))
        child='import json,sys; j=json.load(open(sys.argv[1])); assert len(j["receipts"])==1; j["receipts"].setdefault("quest/a",True); json.dump(j,open(sys.argv[1],"w"))'
        p=subprocess.run([sys.executable,'-c',child,str(path)],capture_output=True,text=True)
        check(p.returncode==0,'reload failed subprocess '+p.stderr,'persistence')
        restored=json.loads(path.read_text())
        check(restored==fixture,'cross-process model changed','persistence')
def test_static():
    pathlist=list((ROOT/'narrative').rglob('*.gd'))+[ROOT/'journey_dynamic/quest_manager.gd',ROOT/'convergence/game.gd',ROOT/'journey_save.gd',ROOT/'journey_dynamic/quest_ui_adapter.gd']
    for fp in pathlist:
        text=fp.read_text()
        for preload in re.findall(r'preload\("(res://[^"]+)"\)',text):
            check((ROOT/preload.removeprefix('res://')).exists(),f'unresolved {fp.name}: {preload}','static')
        # Lexer guard for accidentally embedded newlines in simple strings.
        quote=False;esc=False
        for char in text:
            if esc:esc=False;continue
            if char=='\\':esc=True;continue
            if char=='"':quote=not quote
            if char=='\n':check(not quote,f'newline in string {fp.name}','static')
        check(not quote,'unterminated string '+fp.name,'static')
    for f in ['narrative/core/narrative_state.gd','narrative/core/narrative_events.gd','narrative/adapters/journey_bridge.gd','narrative/core/narrative_scheduler.gd','narrative/tests/qa_native.gd','narrative/tests/qa_reopen.gd']:
        check((ROOT/f).exists(),'file missing '+f,'static')
    for file in (ROOT/'narrative/data').glob('*.json'):
        check(isinstance(json.loads(file.read_text()),dict),'invalid data JSON','static')
    s=(ROOT/'journey_save.gd').read_text()
    check('preload("res://narrative/core/narrative_state.gd").valid' in s,'save guard missing','static')
    check('value.narrative=preload("res://living_world/state.gd").restore_numbers' in s,'JSON restoration missing','static')
    check((ROOT/'project.godot').read_text().find('gl_compatibility')>=0,'renderer changed','static')
    if not BASE.is_file():
        C['comparison']={'status':'NOT_RUN','reason':'Provide EXO_NARRATIVE_BASE_ZIP to compare SHA/CRC with baseline ZIP'}
        return
    with zipfile.ZipFile(BASE) as z:
        files=[p for p in z.namelist() if not p.endswith('/')]
        preserved=changed=removed=0
        for entry in files:
            rel='/'.join(entry.split('/')[1:]); f=ROOT/rel
            if not f.is_file():removed+=1; continue
            original=z.getinfo(entry); new_bytes=f.read_bytes()
            import zlib
            if len(new_bytes)==original.file_size and zlib.crc32(new_bytes)&0xffffffff==original.CRC:preserved+=1
            else:changed+=1
        check(removed==0,'original file removed','preservation')
        check(changed<=5,'too many existing files changed: '+str(changed),'preservation')
        C['comparison']={'baseline_files':len(files),'preserved':preserved,'modified':changed,'removed':removed}
start=time.perf_counter();atlases=test_atlases();distribution=test_destiny();meta=test_receipts();scenario_count=test_story_models(atlases);test_persistence();test_static()
result={'title':'EXO NUCLEO NARRATIVO 01 — OFFLINE / INDEPENDENT MODEL','status':'PASS' if not C['failures'] else 'FAIL','godot_executed':False,'native_test_status':'NOT_RUN','checks':C['checks'],'failures':C['failures'][:30],'sections':dict(C['sections']),'destiny_origin_counts':dict(distribution),'story_fixture_regions':scenario_count,'receipts_model':meta,'file_comparison':C.get('comparison',{}),'elapsed_s':round(time.perf_counter()-start,3),'limits':'Python independent fixture + source integrity only. No GDScript parsing or Godot/runtime confirmation.'}
OUT.write_text(json.dumps(result,indent=2,ensure_ascii=False)+'\n')
print(json.dumps(result,ensure_ascii=False,indent=2))
sys.exit(0 if result['status']=='PASS' else 1)
