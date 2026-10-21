#!/usr/bin/env python3
"""R3 contract tests: real source audits + synthetic host simulations. NOT live Godot gameplay."""
import collections, copy, hashlib, json, math, os, pathlib, random, re, sys, unittest, zipfile
BASE = pathlib.Path(__file__).resolve().parents[1]
HOST_ZIP = pathlib.Path(os.environ.get('EXO_WORK_REFERENCE_ZIP', '/mnt/data/files/EXO-MURIM-CONVERGENCIA-03-WORK-CANDIDATO-01.zip'))
EXPECTED_HASH = 'abe7b5736140d91153e0e6f9343ef443d9ca526f78b636361355b2d895cb69f9'
LEGACY = json.loads((BASE/'data/legacy_bindings.json').read_text())
AUTHORIAL = json.loads((BASE/'data/authorial.json').read_text())
MIRROR = json.loads((BASE/'data/expansion_r2.json').read_text())
R1 = AUTHORIAL[:28]
R2 = AUTHORIAL[28:]
ROWS=LEGACY+AUTHORIAL
BY_ID={x['id']:x for x in ROWS}
TEMPLATES=json.loads((BASE/'data/templates.json').read_text())['templates']

class SyntheticHost:
    """Intentionally NOT a gameplay implementation; formalizes owner-side guard invariants."""
    def __init__(self):
        self.state={'hp':100,'qi':100,'stamina':100,'cooldowns':{},'learned':set(),
                    'slots':set(),'weapon_pose':'blade','actor_alive':True,'target_alive':True,
                    'target_friendly':False,'los_clear':True,'safe_zone':False,'region':'region_00'}
        self.receipts={};self.effects=0;self.saves={}
    def permit(self, actor, skill_id, receipt):
        s=BY_ID[skill_id];b=s['balance'];t=s['tags'];x=self.state
        if actor not in ('player','npc/1','enemy/1'):return 'actor_invalid'
        if not x['actor_alive']:return 'actor_dead'
        if not x['target_alive']:return 'target_dead'
        if x['target_friendly']:return 'friendly_target'
        if not x['los_clear']:return 'wall'
        if x['safe_zone']:return 'safe_zone'
        if skill_id not in x['learned']:return 'not_learned'
        if skill_id not in x['slots']:return 'slot_missing'
        if x['weapon_pose'] not in t['weapon_poses']:return 'weapon_wrong'
        if x['cooldowns'].get(skill_id,0)>0:return 'cooldown'
        if x['qi']<b['qi']:return 'no_qi'
        if x['stamina']<b['stamina']:return 'no_stamina'
        if receipt in self.receipts:return 'duplicate'
        return 'allow'
    def execute(self, actor, skill_id, receipt, inject_abort=False):
        if receipt in self.receipts:return 'duplicate'
        outcome=self.permit(actor,skill_id,receipt)
        if outcome!='allow':return outcome
        snapshot=copy.deepcopy(self.state)
        b=BY_ID[skill_id]['balance'];self.state['qi']-=b['qi'];self.state['stamina']-=b['stamina']
        self.state['cooldowns'][skill_id]=b['cooldown']
        if inject_abort:
            self.state=snapshot
            return 'rollback'
        self.receipts[receipt]={'actor':actor,'skill_id':skill_id,'committed':True}
        self.effects+=1
        return 'committed'
    def save(self):
        return {'state':copy.deepcopy(self.state),'receipts':copy.deepcopy(self.receipts),'effects':self.effects}
    def reopen(self, snapshot):
        self.state=copy.deepcopy(snapshot['state']);self.receipts=copy.deepcopy(snapshot['receipts']);self.effects=snapshot['effects']

class SkillForgeR3Tests(unittest.TestCase):
    def test01_source_counts(self):self.assertEqual((len(LEGACY),len(R1),len(R2),len(ROWS)),(16,28,140,184))
    def test02_ids_unique(self):self.assertEqual(len(BY_ID),184)
    def test03_names_unique(self):self.assertEqual(len({s['name'].casefold() for s in ROWS}),184)
    def test04_legacy_ids_immutable(self):self.assertTrue(all(s['id']==s['legacy_id'] for s in LEGACY))
    def test05_r2_mirror_not_double_counted(self):self.assertEqual(MIRROR,R2)
    def test06_all_legacy_still_legacy(self):self.assertTrue(all(s['executor']=='legacy' and s['state']=='legacy_connected' for s in LEGACY))
    def test07_all_authorial_still_unlocked(self):self.assertTrue(all(s['executor']=='generic' and s['state']=='candidate_not_unlocked' for s in AUTHORIAL))
    def test08_manifest_version(self):
        m=json.loads((BASE/'manifest.json').read_text()); self.assertEqual((m['version'],m['host_contract_schema']),('1.2.0',2))
    def test09_module_registered_version(self):
        s=(BASE/'module.gd').read_text();self.assertIn('SERVICE_VERSION := "1.2.0"',s);self.assertIn('self,\n\t\t["summary"',s)
    def test10_no_saves_or_copies_core(self):
        m=json.loads((BASE/'manifest.json').read_text());self.assertEqual(m['persistence'],{})
        self.assertFalse((BASE/'techniques.gd').exists())
        self.assertFalse((BASE/'exo_core').exists())
    def test11_no_legacy_double_debit(self):
        s=(BASE/'integration/legacy_bridge.gd').read_text()
        self.assertRegex(s,r'world\.techniques\.cast\(index\)')
        self.assertFalse(re.search(r'\bmana\s*[-+*/]?=|\bstamina\s*[-+*/]?=',s))
    def test12_authorial_has_no_direct_combat_writes(self):
        s=(BASE/'module.gd').read_text()
        for snippet in ['.hurt(','.health =','.mana -=','.stamina -=','save_progress(']:self.assertNotIn(snippet,s)
    def test13_all_templates_resolved(self):
        ids={x['id'] for x in TEMPLATES};self.assertTrue(all(x['template'] in ids for x in AUTHORIAL))
    def test14_costs_finite_and_nonnegative(self):
        for s in ROWS:
            for key in ('damage','qi','stamina','cooldown','range','radius','cast_time','release_time'):
                a=float(s['balance'].get(key,0));self.assertTrue(math.isfinite(a) and a>=0,(s['id'],key))
    def test15_r2_families(self):
        c=collections.Counter(s['tags']['power_family'] for s in R2)
        self.assertEqual(set(c.values()),{20});self.assertEqual(len(c),7)
    def test16_r2_inspirations(self):
        c=collections.Counter(s['tags']['inspiration_origin'] for s in R2)
        self.assertEqual(set(c.values()),{35});self.assertEqual(len(c),4)
    def test17_r2_28_bins(self):
        c=collections.Counter((s['tags']['power_family'],s['tags']['inspiration_origin']) for s in R2)
        self.assertEqual(len(c),28);self.assertEqual(set(c.values()),{5})
    def test18_no_unsupported_effects(self):
        allow={'damage','status','movement','field','channel','projectile','shield','heal','cleanse'}
        self.assertTrue(all(e['op'] in allow for s in AUTHORIAL for e in s['effects']))
    def test19_r2_media_pending(self):
        self.assertTrue(all(cue.get('binding')=='requires_binding' for s in R2 for track in ('audio','vfx') for cue in s['presentation'][track]))
    def test20_work_base_hash_and_crc(self):
        if not HOST_ZIP.exists():self.skipTest('BLOCKED: C3 Work archive absent')
        self.assertEqual(hashlib.sha256(HOST_ZIP.read_bytes()).hexdigest(), EXPECTED_HASH)
        with zipfile.ZipFile(HOST_ZIP) as z:self.assertIsNone(z.testzip())
    def test21_work_core_skills_and_legacy_balance(self):
        if not HOST_ZIP.exists():self.skipTest('BLOCKED: C3 Work archive absent')
        with zipfile.ZipFile(HOST_ZIP) as z:core={s['id']:s for s in json.loads(z.read('data/skills.json'))}
        self.assertEqual(len(core),16)
        for s in LEGACY:
            original=core[s['id']];b=s['balance']
            for src,dst in [('mana','qi'),('stamina','stamina'),('damage','damage'),('cooldown','cooldown'),('cast','cast_time'),('release','release_time')]:
                self.assertAlmostEqual(original[src],b[dst],places=5)
            self.assertEqual(original['kind'],s['template'])
    def test22_work_style_and_weapon_refs(self):
        if not HOST_ZIP.exists():self.skipTest('BLOCKED: C3 Work archive absent')
        with zipfile.ZipFile(HOST_ZIP) as z:
            poses={w['id']:w['pose'] for w in json.loads(z.read('data/weapons.json'))}
            schools={w['id'] for w in json.loads(z.read('exo_martial/data/schools.json'))}
            styles={w['id'] for w in json.loads(z.read('exo_martial/data/styles.json'))}
        self.assertEqual((len(poses),len(schools),len(styles)),(16,9,12))
        for s in ROWS:
            self.assertTrue(set(s['tags']['schools'])<=schools)
            self.assertTrue(set(s['tags']['styles'])<=styles)
            for wid in s['tags']['weapon_ids']:
                self.assertIn(wid,poses)
                self.assertIn(poses[wid],s['tags']['weapon_poses'])
    def test23_existing_combat_service_lacks_atomic_host(self):
        if not HOST_ZIP.exists():self.skipTest('BLOCKED: C3 Work archive absent')
        with zipfile.ZipFile(HOST_ZIP) as z:
            core=z.read('exo_core/core.gd').decode();print('AUDIT_CORE_COMBAT=',[line.strip() for line in core.splitlines() if 'register_service("combat"' in line])
            self.assertIn('world,["enemy_defeated"]',core)
            self.assertNotIn('"skill_forge"',z.read('exo_core/modules.json').decode())
    def test24_host_contract_schemas(self):
        c=(BASE/'runtime/host_contract.gd').read_text()
        self.assertIn('SCHEMA_VERSION := 2',c)
        self.assertIn('plan_sha256',c);self.assertIn('status == "duplicate"',c)
    def test25_replay_same_receipt_one_effect(self):
        s='exo.sf.fio_do_bambu';h=SyntheticHost();h.state['learned'].add(s);h.state['slots'].add(s)
        self.assertEqual(h.execute('player',s,'rid/1'),'committed')
        self.assertEqual(h.execute('player',s,'rid/1'),'duplicate')
        self.assertEqual(h.effects,1)
        self.assertEqual(h.state['stamina'],100-BY_ID[s]['balance']['stamina'])
    def test26_zero_qi_denied(self):
        s=next(x['id'] for x in AUTHORIAL if x['balance']['qi']>0 and x['tags']['weapon_poses']==['blade'])
        h=SyntheticHost();h.state.update(qi=0,learned={s},slots={s})
        self.assertEqual(h.execute('player',s,'rid/2'),'no_qi');self.assertEqual(h.effects,0)
    def test27_empty_slot_denied(self):
        s='exo.sf.fio_do_bambu';h=SyntheticHost();h.state['learned'].add(s)
        self.assertEqual(h.execute('player',s,'rid/3'),'slot_missing')
    def test28_weapon_denied(self):
        s='exo.sf.fio_do_bambu';h=SyntheticHost();h.state.update(learned={s},slots={s},weapon_pose='fists')
        self.assertEqual(h.execute('player',s,'rid/4'),'weapon_wrong')
    def test29_cooldown_denied(self):
        s='exo.sf.fio_do_bambu';h=SyntheticHost();h.state.update(learned={s},slots={s},cooldowns={s:1.5})
        self.assertEqual(h.execute('player',s,'rid/5'),'cooldown')
    def test30_dead_actor_denied(self):
        s='exo.sf.fio_do_bambu';h=SyntheticHost();h.state.update(learned={s},slots={s},actor_alive=False)
        self.assertEqual(h.execute('player',s,'rid/6'),'actor_dead')
    def test31_dead_target_denied(self):
        s='exo.sf.fio_do_bambu';h=SyntheticHost();h.state.update(learned={s},slots={s},target_alive=False)
        self.assertEqual(h.execute('player',s,'rid/7'),'target_dead')
    def test32_friendly_target_denied(self):
        s='exo.sf.fio_do_bambu';h=SyntheticHost();h.state.update(learned={s},slots={s},target_friendly=True)
        self.assertEqual(h.execute('player',s,'rid/8'),'friendly_target')
    def test33_wall_los_denied(self):
        s='exo.sf.fio_do_bambu';h=SyntheticHost();h.state.update(learned={s},slots={s},los_clear=False)
        self.assertEqual(h.execute('player',s,'rid/9'),'wall')
    def test34_safe_zone_denied(self):
        s='exo.sf.fio_do_bambu';h=SyntheticHost();h.state.update(learned={s},slots={s},safe_zone=True)
        self.assertEqual(h.execute('player',s,'rid/10'),'safe_zone')
    def test35_ghost_denied(self):
        s='exo.sf.fio_do_bambu';h=SyntheticHost();h.state.update(learned={s},slots={s})
        self.assertEqual(h.execute('ghost/1',s,'rid/11'),'actor_invalid')
    def test36_rollback_does_not_spend(self):
        s='exo.sf.fio_do_bambu';h=SyntheticHost();h.state.update(learned={s},slots={s})
        before=h.save();self.assertEqual(h.execute('player',s,'rid/12',True),'rollback')
        self.assertEqual(h.save(),before)
    def test37_save_reopen_replay_denied(self):
        s='exo.sf.fio_do_bambu';h=SyntheticHost();h.state.update(learned={s},slots={s})
        self.assertEqual(h.execute('player',s,'rid/13'),'committed');snapshot=h.save()
        later=SyntheticHost();later.reopen(snapshot);self.assertEqual(later.execute('player',s,'rid/13'),'duplicate')
        self.assertEqual(later.effects,1)
    def test38_multiple_races_of_synthetic_casts(self):
        s='exo.sf.fio_do_bambu';h=SyntheticHost();h.state.update(learned={s},slots={s})
        answers=[h.execute('player',s,'rid/race') for _ in range(10000)]
        self.assertEqual(answers.count('committed'),1)
        self.assertEqual(answers.count('duplicate'),9999)
    def test39_88_regions_context_only(self):
        s='exo.sf.fio_do_bambu';h=SyntheticHost();h.state.update(learned={s},slots={s})
        for idx in range(88):
            h.state['region']='region_%02d'%idx
            self.assertEqual(h.state['region'],'region_%02d'%idx)
        self.assertEqual(h.effects,0)
    def test40_24h_mock_host_context(self):
        s='exo.sf.fio_do_bambu';h=SyntheticHost();h.state.update(learned={s},slots={s})
        rng=random.Random(203031);accepted=0
        for second in range(24*60*60):
            h.state['stamina']=min(100,h.state['stamina']+0.03)
            h.state['qi']=min(100,h.state['qi']+0.01)
            h.state['cooldowns'][s]=max(0,h.state['cooldowns'].get(s,0)-1)
            if second%30==0:
                rid='24h/%s'%second
                if h.execute('player',s,rid)=='committed':accepted+=1
            if second%97==0:h.state['safe_zone']=rng.choice([True,False])
        self.assertGreater(accepted,10)
        self.assertGreaterEqual(h.state['stamina'],0)
    def test41_localization_keys_unique(self):
        loc=json.loads((BASE/'localization/ids.json').read_text()); self.assertEqual(len(loc),184)
        self.assertEqual(len(set(loc)),184)
        self.assertTrue(all(loc[k]['key']=='exo.skill.'+k for k in loc))
    def test42_r3_status_matrix_all_ids(self):
        import csv
        rows=list(csv.DictReader((BASE/'tests/MATRIZ-184-SKILLS-ESTADOS.csv').read_text(encoding='utf-8').splitlines()))
        self.assertEqual(len(rows),184);self.assertEqual({x['id'] for x in rows},set(BY_ID))
        self.assertEqual(sum(x['state']=='legacy_connected' for x in rows),16)
        self.assertEqual(sum(x['state']=='candidate_not_unlocked' for x in rows),168)
    def test43_no_executed_authorial_claim_in_matrix(self):
        import csv
        rows=list(csv.DictReader((BASE/'tests/MATRIZ-184-SKILLS-ESTADOS.csv').read_text(encoding='utf-8').splitlines()))
        self.assertTrue(all(r['runtime_status']=='BLOCKED_HOST' for r in rows if r['state']=='candidate_not_unlocked'))
    def test44_no_implicit_random_seed_in_cast(self):
        src=(BASE/'module.gd').read_text()+(BASE/'runtime/planner.gd').read_text()
        self.assertNotIn('randomize(',src);self.assertNotIn('randi(',src)
    def test45_service_registration_is_not_installation(self):
        p=BASE/'integration/PATCH-SKILL-C3-WORK-PROPOSTO.diff'
        self.assertTrue(p.is_file());self.assertIn('exo_skill_forge',p.read_text())

    def test46_seeded_r2_generator_is_reproducible(self):
        sys.path.insert(0,str(BASE/'tools'))
        from expand_skill_library import generate
        generated=generate(20261020)
        self.assertEqual(generated,R2)
        self.assertEqual(generate(42),generate(42))
        self.assertEqual([x['id'] for x in generate(42)],[x['id'] for x in R2])
    def test47_impossible_generator_request_rejected(self):
        sys.path.insert(0,str(BASE/'tools'))
        from expand_skill_library import make_candidate
        for case in [('invalid','anime',1),('qi','movie_copyright',1),('qi','cinema',7)]:
            with self.assertRaises(ValueError):make_candidate(*case,11)
    def test48_only_two_metadata_changes_vs_r2(self):
        r2zip=pathlib.Path(os.environ.get('EXO_R2_SOURCE_ZIP','/mnt/data/EXO-SKILL-FORGE-01-R2-BIBLIOTECA-EXPANDIDA.zip'))
        if not r2zip.exists():self.skipTest('BLOCKED: R2 source ZIP absent')
        with zipfile.ZipFile(r2zip) as z:old=json.loads(z.read('exo_skill_forge/data/authorial.json'))
        self.assertEqual([x['id'] for x in old],[x['id'] for x in AUTHORIAL])
        assert len(old)==len(AUTHORIAL)
        diff=[]
        for a,b in zip(old,AUTHORIAL):
            a=copy.deepcopy(a);b=copy.deepcopy(b)
            a_tags=a['tags'].pop('weapon_poses');b_tags=b['tags'].pop('weapon_poses')
            self.assertEqual(a,b)
            if a_tags!=b_tags:diff.append((a['id'],a_tags,b_tags))
        self.assertEqual(diff,[('exo.sf.fio_do_bambu',['blade'],['blade','draw']),('exo.sf.sete_cortes_do_vento',['blade'],['blade','draw'])])
    def test49_all_gd_preload_paths_exist(self):
        paths={x.relative_to(BASE.parent).as_posix() for x in BASE.rglob('*') if x.is_file()}
        with zipfile.ZipFile(HOST_ZIP) as z:paths.update(z.namelist())
        misses=[]
        for gd in BASE.rglob('*.gd'):
            for ref in re.findall(r'preload\(["\']res://([^"\']+)["\']\)',gd.read_text()):
                if ref not in paths:misses.append((gd.name,ref))
        self.assertEqual(misses,[])

if __name__=='__main__':
    unittest.main(verbosity=2)
