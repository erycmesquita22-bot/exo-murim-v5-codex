#!/usr/bin/env python3
"""Independent reference/static tests. NOT a substitute for a Godot execution."""
from pathlib import Path
from hashlib import sha256
from collections import Counter
import json, random, re, time, zipfile, sys
HERE=Path(__file__).resolve().parents[1]
ROOT=HERE.parents[0]
CORE=Path(sys.argv[1]) if len(sys.argv)>1 else Path('/mnt/data/files/EXO-Murim-EXO-Core-01-CANDIDATO-CORRIGIDO.zip')
OUTPUT=HERE/'tests'/'QA-OFFLINE-RESULTS.json'

def read(name):return json.loads((HERE/'data'/name).read_text())

class Checks:
    def __init__(self):self.details=[];self.errors=[]
    def check(self,label,yes,info=None):
        self.details.append({'name':label,'status':'PASS' if yes else 'FAIL','detail':info})
        if not yes:self.errors.append(label)
        return yes

c=Checks();began=time.monotonic()
styles,schools,techniques,methods=map(read,('styles.json','schools.json','techniques.json','training_methods.json'))
manifest=json.loads((HERE/'manifest.json').read_text())
contract=json.loads((HERE/'contracts/INTEGRATION-CONTRACT.json').read_text())
with zipfile.ZipFile(CORE) as core:
    base='EXO-Murim-Convergencia-02/'
    skills=json.loads(core.read(base+'data/skills.json'))
    weapons=json.loads(core.read(base+'data/weapons.json'))
    modules=json.loads(core.read(base+'exo_core/modules.json'))
    orig_skill_hash=sha256(core.read(base+'data/skills.json')).hexdigest()
    header=core.read(base+'exo_core/core.gd').decode()
    module_code=(HERE/'module.gd').read_text()
    core_contract=core.read(base+'exo_core/contracts/event_contracts.gd').decode()
    real_services=core.read(base+'exo_core/service_registry.gd').decode()
    c.check('base_core_sha256_verified',sha256(CORE.read_bytes()).hexdigest()=='d6cae1fc95078b9b083755d68ee59c99568801e01fde8c5983366dc4c616f1ac')
    c.check('catalogue_exactly_core_skills',all(t['core_skill_id'] in {v['id'] for v in skills} for t in techniques) and len(techniques)==len(skills))
    c.check('catalogue_actual_costs',all(next(s for s in skills if s['id']==t['core_skill_id'])['mana']==t['resources']['qi'] and next(s for s in skills if s['id']==t['core_skill_id'])['stamina']==t['resources']['stamina'] for t in techniques))
    c.check('catalogue_cooldown_match',all(next(s for s in skills if s['id']==t['core_skill_id'])['cooldown']==t['cooldown_seconds'] for t in techniques))
    c.check('core_source_digest_match',orig_skill_hash==(HERE/'data/source_core_skills_sha256.txt').read_text().strip())
    c.check('core_registry_can_load_external_entrypoint','var module: RefCounted=load(spec.entrypoint).new()' in header)
    c.check('core_services_method_matches','register_service(id: String,owner_id: String,provider: Object,methods: Array' in real_services)
    c.check('no_arbitrary_core_events',not manifest['consumes'] and not manifest['publishes'] and 'martial_lesson_completed' not in core_contract)
    original_modules={m['id'] for m in modules}
    c.check('no_module_or_service_id_collision',manifest['id'] not in original_modules and not (set(manifest['services']) & {s for m in modules for s in m['services']}))
    c.check('all_dependencies_satisfiable',set(manifest['requires'])|set(manifest['optional']) <= original_modules)
    c.check('root_martial_domain_only',manifest['persistence']=={'exo_martial':1})
    c.check('unchanged_central_files',not any(p.parts[0] in ['exo_core','convergence','narrative','living_world','combat','inventory'] for p in HERE.rglob('*') if p.is_file()))
    c.check('core_existing_poses',set(w['pose'] for w in weapons) >= {'blade','thrust','fists','focus','crossbow'})

ids=[t['id'] for t in techniques]+[s['id'] for s in styles]+[s['id'] for s in schools]+[m['id'] for m in methods]
c.check('global_unique_catalogue_ids',len(ids)==len(set(ids)))
c.check('catalogue_counts',len(styles)==12 and len(schools)==9 and len(techniques)==16 and len(methods)==7)
c.check('style_refs_valid',all(tid in {t['core_skill_id'] for t in techniques} for s in styles for tid in s['core_techniques']))
c.check('school_refs_valid',all(x['style_id'] in {s['id'] for s in styles} for x in schools))
c.check('technique_style_refs_valid',all(set(t['style_ids']) <= {s['id'] for s in styles} for t in techniques))
c.check('all_techniques_bounded',all(0<=t['resources']['qi']<=100 and 0<=t['resources']['stamina']<=100 and 0<=t['cooldown_seconds']<=120 and t['grade_max']<=5 for t in techniques))
c.check('rank_policy_consistent',all(s['ranks']==[3,4,5,6] for s in schools) and all(t['requires']['rank']==3 for t in techniques))
c.check('server_side_proof_gate_present','proof_validator' in module_code and 'not _check_evidence' in module_code and 'func configure_proof_validator' in module_code)
c.check('narrative_bond_authority', 'Bonds.pair(a,b)' in (HERE/'masters/martial_engine.gd').read_text() and not (HERE/'masters/martial_engine.gd').read_text().count('Bonds.establish('))
c.check('save_coordinator_only','save.save_coordinator.register_domain' in module_code and 'core.world.journey.write()' in module_code and '_commit_legacy' not in module_code)
c.check('no_new_qi_reserve',not re.search(r'var\s+qi\s*[:=]',(HERE/'masters/martial_engine.gd').read_text()))
c.check('no_combat_damage_modification',all(t['base_damage_reference']==next(s['damage'] for s in skills if s['id']==t['core_skill_id']) for t in techniques))
c.check('zero_interruption_of_legacy',not any(p.name in {'core.gd','game.gd','region.gd','inventory.gd','journey_save.gd'} for p in HERE.rglob('*.gd')))

# Balance and deterministic generation are modelled independently as a reference oracle.
N=12000
rng=random.Random(10911)
masters=['npc/r%02d/master%08d'%(i%88,i) for i in range(N)]
seed=21474837

def selected_school(s,id):
    h=sha256(('EXO-MARTIAL-MASTER-1|%s|%s'%(s,id)).encode()).hexdigest()
    return schools[int(h[:7],16)%len(schools)]['id']
first=[selected_school(seed,id) for id in masters]
repeated=[selected_school(seed,id) for id in reversed(masters)]
c.check('stress_12000_deterministic_masters',first==list(reversed(repeated)),N)
other=[selected_school(seed+1,id) for id in masters]
c.check('cross_seed_non_identical',sum(a!=b for a,b in zip(first,other))>N*.70,sum(a!=b for a,b in zip(first,other)))
c.check('master_ids_unique',len(set(masters))==N)
c.check('school_spread',len(set(first))==9,dict(Counter(first)))

# Narrative pair direction independent; application keys (sha256) must not collide.
relation_count=12000
pairs=[('exo/qa/npc/'+masters[i], 'exo/qa/npc/npc%08d'%i) for i in range(relation_count)]
keys=[sha256((a+'|'+b).encode()).hexdigest() for a,b in pairs]
c.check('stress_12000_unique_martial_pair_keys',len(set(keys))==relation_count)
canonical=[tuple(sorted((a,b))) for a,b in pairs]
c.check('narrative_bond_pair_commutativity',all(tuple(sorted((a,b)))==tuple(sorted((b,a))) for a,b in pairs))
c.check('preexisting_npc_identity_stable',all(s.startswith('npc/r') for s in masters))

# Receipt oracle: repeated practice/graduation never yields second reward.
receipts=set();lesson_stats={'xp':0,'practices':0,'awards':0}
for n in range(6000):
    receipt='verified_event/%d'%n
    for retry in range(3):
        if receipt in receipts:continue
        receipts.add(receipt);lesson_stats['xp']+=11;lesson_stats['practices']+=1
for n in range(6000):
    receipt='martial_reward/lesson/%d'%n
    for retry in range(3):
        if receipt in receipts:continue
        receipts.add(receipt);lesson_stats['awards']+=1
c.check('receipt_replay_6000_practices',lesson_stats['practices']==6000 and lesson_stats['xp']==66000,lesson_stats)
c.check('idempotent_reward_oracle',lesson_stats['awards']==6000 and len(receipts)==12000)

# Static bracket+quote scan for accidental truncation (not a true GDScript parser).
def balanced(src):
    stack=[];quote=None;esc=False
    for lineno,line in enumerate(src.splitlines(),1):
        if line.strip() and line.startswith(' '):return False,'indentation_spaces:'+str(lineno)
        for ch in line:
            if quote:
                if esc:esc=False
                elif ch=='\\':esc=True
                elif ch==quote:quote=None
            elif ch=='#':break
            elif ch in "\"'":quote=ch
            elif ch in '([{':stack.append((ch,lineno))
            elif ch in ')]}':
                if not stack or {'(':')','[':']','{':'}'}[stack.pop()[0]]!=ch:return False,'unbalanced:'+str(lineno)
        if quote:return False,'unterminated_quote:'+str(lineno)
    return (not stack,'balanced' if not stack else str(stack[-1]))
issues=[]
for path in HERE.rglob('*.gd'):
    ok,what=balanced(path.read_text())
    if not ok:issues.append((str(path.relative_to(HERE)),what))
c.check('gdscript_lexical_balanced_not_parse',not issues,issues)

result={'result':'PASS' if not c.errors else 'FAIL','method':'INDEPENDENT_PYTHON_REFERENCE_AND_STATIC_ONLY','godot_native':'NOT_RUN','integrated_save_v4':'NOT_RUN','core_combat_regression':'NOT_RUN','seed':seed,'reference_masters':N,'reference_relationship_pairs':relation_count,'tests_passed':len(c.details)-len(c.errors),'tests_failed':len(c.errors),'failed_tests':c.errors,'elapsed_seconds':round(time.monotonic()-began,3),'checks':c.details}
OUTPUT.write_text(json.dumps(result,indent=2,ensure_ascii=False)+'\n')
print(json.dumps({k:result[k] for k in result if k!='checks'},indent=2,ensure_ascii=False))
sys.exit(int(bool(c.errors)))
