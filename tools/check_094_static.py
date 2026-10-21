#!/usr/bin/env python3
"""Static safeguards only: cannot replace loading the Godot project."""
import hashlib,json,pathlib,collections,sys,re
p=pathlib.Path(__file__).resolve().parents[1]
checks=[]
def check(ok,reason):
 checks.append((bool(ok),reason))
for name in ['project.godot','main.gd','region.gd','world/landscape.gd','world/biome_plan.gd','world/village_composition.gd','map_view.gd','qa094.gd','qa094_playable.gd']:
 check((p/name).exists(),'arquivo '+name)
for item in p.rglob('*.json'):
 try:json.loads(item.read_text())
 except Exception as e:check(False,'JSON inválido '+str(item)+': '+str(e))
s=(p/'region.gd').read_text();main=(p/'main.gd').read_text();flow=(p/'murim_flow.gd').read_text()
# Avoid type inference from seed streams exposed as RefCounted; between() is dynamically dispatched.
check(re.search(r'var\s+\w+\s*:=\s*[^\n]*\.between\(',s) is None, 'region.gd: RNG streams require explicit float types')
check(all(f'var {v}: float=' in s for v in ('x','z')), 'region.gd: explicit typed local placement')
check('for x in [-26,26]' not in s and 'for z in [-45,45]' not in s,'muros antigos removidos')
check('Vector3(-12,0,30)' in s and 'Vector3(12,0,31)' in s,'serviços centrais preservados')
check('world.rebuild_region()' in flow and 'rebuild_region()' in main,'recriação com seed selecionada')
check('world.inventory.seed_profile()' in flow and 'world.save_progress()' in flow,'inventário/registro existentes')
check('loot/explore_' in main and 'save_progress()' in main,'coleta persistente')
check('preload("res://region.gd")' not in (p/'world/landscape.gd').read_text(),'sem preload cíclico')
# Reproduce Park-Miller / SHA-256 domain streams independently to confirm distribution.
MOD=2147483647
profiles=collections.Counter()
for seed in range(400):
 key=f'{seed}|1|landscape/layout_v1|village/birth'
 h=int(hashlib.sha256(key.encode()).hexdigest()[:8],16)%(MOD-1)
 roll=(((h%(MOD-1))+1)*48271%MOD)%100
 profile='empobrecida' if roll<20 else 'comum' if roll<70 else 'prospera' if roll<95 else 'especial'
 profiles[profile]+=1
check(all(profiles[k]>0 for k in ('empobrecida','comum','prospera','especial')),'quatro perfis nas primeiras 400 seeds')
check(sum(profiles.values())==400,'contagem dos sorteios')
# Compare original source approved files only (values sourced from immutable 09.3.3 baseline).
expected={'rig.gd':'370d7d1f64091db72e76e58e26782b0a46a61adae3aec290d858023f1bfefceb','wardrobe.gd':'4ba2d658d4914d036619e6ffcca935b8ef087da77021de75fa316ab61fa1d88f','arsenal.gd':'6e341406c97caaf9fd13fd7bc755948b1cdc4339b7956efc9077be7a43d8fbe8','combat/martial_motion.gd':'5acb7ef2a7bd57a18df6dfa5b3212b2519977b4c3d3e57f32fa3d1d4625f0d5a','ui/character_creation.gd':'eb6d9a6d79df2cd83997b2d7c22738c8e6cbdf02dd78d2bd9e9c71e7957cd523'}
for f,h in expected.items():check(hashlib.sha256((p/f).read_bytes()).hexdigest()==h,'preservado '+f)
for ok,description in checks:print(('PASS ' if ok else 'FAIL ')+description)
print('Perfis testados:',dict(profiles),'| total checks:',len(checks))
sys.exit(0 if all(c[0] for c in checks) else 1)
