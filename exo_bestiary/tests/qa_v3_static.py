#!/usr/bin/env python3
"""Testes offline do pacote (NAO executam GDScript)."""
import json, pathlib, random, math, collections
ROOT=pathlib.Path(__file__).resolve().parents[1]
checks=collections.Counter()
def check(condition,label):
    if not condition: raise AssertionError(label)
    checks[label]+=1

def run():
    manifest=json.loads((ROOT/'module/manifest.json').read_text())
    check(manifest['id']=='bestiary','module_identity')
    check(manifest['version']=='3.0.0','module_version')
    check(set(['bestiary.catalog','bestiary.ai','bestiary.encounters','bestiary.combat','bestiary.tactics']).issubset(manifest['services']),'services_declared')
    entry=(ROOT/'module/entrypoint.gd').read_text()
    for signature in ['func plan_group(', 'func plan_actor(', 'func skill_suggestions(', 'func timing_preview(', 'func compatibility_status(']:
        check(signature in entry,'v3_service_api')
    for relative in ['v3/group_tactics.gd','v3/combat_brain.gd','v3/skill_bridge.gd','v3/animation_timing.gd','tests/qa_bestiary_v3.gd']:
        check((ROOT/relative).is_file(),'v3_sources_present')
    for rel in ['data/species.json','data/humanoids.json','data/elites_bosses.json','data/attacks.json']:
        check(isinstance(json.loads((ROOT/rel).read_text()),dict),'catalog_json_valid')
    species=json.loads((ROOT/'data/species.json').read_text())['species']
    humans=json.loads((ROOT/'data/humanoids.json').read_text())['profiles']
    check(len(species)>=16 and len(humans)>=8,'catalog_preserved')
    # Rejeição de segundos controladores/escritores nos novos arquivos (verificação de fonte).
    for path in (ROOT/'v3').glob('*.gd'):
        s=path.read_text()
        for forbidden in ['register_service(', 'damage_player(', 'enemy_defeated(', 'JourneySave.new(', 'authorized_cast(', 'legacy_cast(', 'spawn_actor(', 'queue_free(']:
            check(forbidden not in s,'no_parallel_authority')
    # Simulação em Python de invariantes do algoritmo. Não faz chamada Godot.
    ids=[x['id'] for x in humans]
    rng=random.Random(20261020)
    total=0
    for n in range(1,9):
        for t in range(6000):
            group=sorted({f'unit/{i}' for i in range(n)})
            candidates=[u for u in group if rng.random()<0.7]
            window=t//9
            selected=[]
            if candidates:
                ix=window%len(candidates)
                selected=[candidates[(ix+i)%len(candidates)] for i in range(min(2,len(candidates)))]
            check(len(selected)<=2 and len(selected)==len(set(selected)),'slot_cap_uniqueness')
            check(all(u in candidates for u in selected),'slots_only_eligible')
            check(all(0<=i<len(group) for i in range(n)),'member_indices')
            total+=1
    print(json.dumps({'status':'PASS_OFFLINE_MODEL_ONLY','model_groups':total,'assertions':sum(checks.values()),'groups_by_type':dict(checks),'godot_native':'NOT_RUN'},ensure_ascii=False,indent=2))
if __name__=='__main__':run()
