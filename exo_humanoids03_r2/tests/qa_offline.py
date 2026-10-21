#!/usr/bin/env python3
"""Honest OFFLINE QA of R2 catalog and inherited Humanoides 03 asset integrity.
Does NOT parse, compile, run or render GDScript. Does NOT certify commercial rights.
"""
import collections, hashlib, json, os, pathlib, struct, zipfile
ROOT=pathlib.Path(__file__).resolve().parents[2]
MOD=ROOT/'exo_humanoids03_r2'
CAT=json.loads((MOD/'data/CATALOGO-VESTUARIO-MURIM.json').read_text(encoding='utf8'))
SOURCE=pathlib.Path(os.environ.get('EXO_HUM03_ZIP',str(ROOT/'EXO-Murim-Humanoides-Identidade-03-CANDIDATO.zip')))
# Set EXO_HUM03_ZIP to perform the original 480-PNG integrity verification.
checks=collections.Counter()
failed=[]
def check(condition,reason):
    checks['total']+=1
    if condition: checks['pass']+=1
    else: checks['failed']+=1;failed.append(reason)

roles=CAT['roles'];presets=CAT['presets']; modules=CAT['modules']
check(CAT['schema']==2,'schema')
check(len(presets)>=12,'presets_count')
check(len(CAT['factions'])>=6,'factions_count')
check(len(roles)>=15,'roles_count')
expected={'bandit_swordsman','bandit_archer','bandit_spearman','dagger_raider','defensive_mercenary','hostile_wanderer','aggressive_cultivator','rival_disciple'}
check(set(CAT['visual_policy']['bestiary02_ids'])==expected,'bestiary02 eight IDs')
for role, picks in roles.items():
    check(len(picks)>0 and all(p in presets for p in picks),f'role references {role}')
for label, style in presets.items():
    for key in ['robe','sleeves','headwear','armor','emblem','extra']:
        check(style[key] in modules[key],f'{label}.{key} valid')
for name,fac in CAT['factions'].items():
    for key in ['cloth','trim','lining','metal']:
        check(len(bytes.fromhex(fac[key]))==3, f'{name}.{key} RGB')

def fnv32(s):
    h=2166136261
    for b in s.encode('utf8'):h=((h^b)*16777619)&0xffffffff
    return h

def choose(evt):
    uid=evt['uid'];role=evt['role'];fac=evt['faction'];prestige=min(3,max(0,evt['prestige']))
    key=f'EXO/R2|{evt["world_seed"]}|{evt["region_id"]}|{uid}|{role}|{fac}|{prestige}'
    pid=roles[role][fnv32(key)%len(roles[role])]
    pal=fac if fac in CAT['factions'] else 'neutral'
    variant=CAT['variants'][fnv32(key+'|variant') % len(CAT['variants'])]
    style=presets[pid].copy();style['palette']=pal;style['prestige']=prestige;style['variant']=variant
    if style['emblem']!='none':style['emblem']=CAT['factions'][pal]['emblem']
    return pid,style

profiles=[]
for i in range(50000):
    evt={'uid':f'world:actor/{i:08d}','role':list(roles)[i%len(roles)],'faction':list(CAT['factions'])[i%len(CAT['factions'])],
         'world_seed':'EXO/SEED/123','region_id':i%88,'prestige':i%4}
    a=choose(evt)
    check(a==choose(dict(evt)),'determinism '+str(i))
    profiles.append((a[0],a[1]['variant']))
check(len(set(profiles))>20,'meaningful variety beyond recolors')
check(choose({'uid':'test','role':'resident','faction':'not_official','world_seed':'x','region_id':0,'prestige':0})[1]['palette']=='neutral','unknown faction fallback')

allpaths=[f for f in ROOT.rglob('*') if f.is_file()]
check(not any(f.suffix.lower() in ['.png','.jpg','.jpeg','.glb','.fbx','.wav','.ogg'] for f in allpaths), 'no inherited media copied into R2')
check(not any(f.name in ('rig.gd','wardrobe.gd','enemy.gd','core.gd') for f in allpaths),'core unmodified')
check((MOD/'scenes/galeria_qa_r2.tscn').exists(),'gallery included')
check((MOD/'scripts/actor_visual_adapter.gd').exists(),'visual adapter included')

assets={'exists':SOURCE.exists(),'count':None,'integrity_pass':None,'categories':{}}
if SOURCE.exists():
    with zipfile.ZipFile(SOURCE) as z:
        cat=json.loads(z.read('exo_humanoids03/data/skin_catalog.json'))
        entries=cat['entries'];found=collections.Counter()
        for e in entries:
            resource=e['resource']; internal=resource.replace('res://','')
            data=z.read(internal)
            check(hashlib.sha256(data).hexdigest()==e['sha256'], f'{internal} integrity')
            check(data[:8]==b'\x89PNG\r\n\x1a\n' and struct.unpack('>II',data[16:24])==(64,64), f'{internal} PNG64x64')
            found[e['category']]+=1
        assets.update(count=len(entries),integrity_pass=all(x==0 for x in [checks['failed']]),categories=dict(found))
        check(found=={'npc':128,'ascendant':64,'trial':288},'480 expected groups')

report={'test':'offline schema/hash checks; NOT Godot QA',
        'counts':dict(checks),'failures':failed[:30],
        'catalog':{'presets':len(presets),'roles':len(roles),'faction_palettes':len(CAT['factions']),
                   'variant_combinations_observed':len(set(profiles)),'deterministic_cases':50000},
        'inherited_media':assets,
        'not_executed':['Godot 4.6.2 parse/runtime','render/QA screenshots','anatomy clipping','PCK export','FPS/mesh/material counts in live scene','rights review']}
(ROOT/'RESULTADO-QA-OFFLINE-R2.json').write_text(json.dumps(report,indent=2,ensure_ascii=False)+'\n',encoding='utf8')
print(json.dumps(report,indent=2,ensure_ascii=False))
raise SystemExit(1 if failed else 0)
