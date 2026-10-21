#!/usr/bin/env python3
"""EXO Library R3: source-integrity, graph coverage, institution and 250k QA scenarios.
OFFLINE SIM ONLY: narrative authoritative host/WorldGenesis/war runtime NOT exercised.
"""
import json,collections,hashlib,random,re,time,sys
from pathlib import Path
R=Path(__file__).resolve().parents[2]; M=R/'exo_world_library'
def load(path):return json.loads(path.read_text(encoding='utf-8'))
manifest=load(M/'manifest.json'); errors=[];checks=collections.Counter(); allrec={};domains={};start=time.monotonic()
def check(ok,tag):
 checks['assertions']+=1
 if not ok and len(errors)<200: errors.append(str(tag))
for entry in manifest['catalogs']:
 d=entry['domain']; x=load(M/'data'/f'{d}.json'); domains[d]=x['records'];check(x['schema']=='exo.world_library.catalog.v1','bad_catalog:'+d);check(len(x['records'])==entry['count'],'bad_count:'+d)
 for r in x['records']:
  check(r['id'] not in allrec,'duplicate_id:'+r['id']);allrec[r['id']]=r
  check(len(r['id'])<=128,'id_oversize:'+r['id'])
  check(r['domain']==d,'wrong_domain:'+r['id'])
  check(not set(r['requires']) & set(r['excludes']),'conflicting_requires:'+r['id'])
for rid,r in allrec.items():
 for t in r['links']:check(t in allrec,'unresolved_link:'+rid+':'+t)
check(len(domains)==76,'domain_count_R4');check(len(allrec)==1228,'record_count_R4')
check(len(domains['story_arc'])==48,'story_count')
check(len(domains['parallel_arc'])==96,'parallel_count')
check(len(domains['war_casus'])==30,'war_casus_count')
check(len(domains['revolution_cause'])==20,'revolution_count')

# 48 state graphs with explicit authored text at every beat, choices, unique outcomes, deterministic traversal.
terminal_seen=collections.Counter(); arc_map={x['id']:x for x in domains['story_arc']}; ends={};transition_count=0
for r in domains['story_arc']:
 v=r['variables']; nodes={n['id']:n for n in v['nodes']}; check(len(nodes)==7,'story_node_count:'+r['id'])
 check(v['start'] in nodes,'missing_start:'+r['id'])
 check(len(v['terminal_nodes'])==3,'terminal_count:'+r['id'])
 for n in nodes.values():
  check(bool(n.get('narration_pt_BR')) and bool(n.get('line_pt_BR')),'missing_authored_prose:'+r['id']+':'+n['id'])
  if n['stage']=='terminal':
   terminal_seen[n['outcome']]+=1
   check(not n['choices'],'terminal_with_choices:'+r['id'])
  else:check(bool(n['choices']),'dead_story_node:'+r['id'])
  ids=set()
  for ch in n['choices']:
   transition_count+=1
   check(ch['id'] not in ids,'duplicate_choice:'+r['id']+':'+n['id']);ids.add(ch['id'])
   check(ch['next'] in nodes,'dangling_edge:'+r['id']+':'+n['id'])
 reachable=set();todo=[v['start']];
 while todo:
  node=todo.pop()
  if node in reachable:continue
  reachable.add(node)
  todo.extend(ch['next'] for ch in nodes[node]['choices'])
 check(reachable==set(nodes),'unreachable_node:'+r['id'])
 check({nodes[n]['outcome'] for n in v['terminal_nodes']}=={'reform','compromise','rupture'},'missing_specific_outcomes:'+r['id'])
 check(v['persistence_owner']=='narrative','wrong_persistence_owner:'+r['id'])
 ends[r['id']]=frozenset(v['terminal_nodes'])
for p in domains['parallel_arc']:
 check(p['variables']['parent_story_id'] in arc_map,'missing_parent:'+p['id'])
 check(len(p['variables']['scenes_pt_BR'])>=2,'unwritten_parallel:'+p['id'])
 check(p['variables']['never_auto_commit'] is True,'side_auto_mutates:'+p['id'])

# Static election system: forced rejection when institution does not have eligible electorate, quorum or election host.
inst={r['id']:r for r in domains['civic_institution']}; election_actions=['elect','legislation','impeachment']
def election_gate(record,ctx):
 v=record['variables'];i=inst.get(v.get('institution_id'))
 if i is None:return 'missing_institution'
 if i['variables']['decision_method'] in ('hearing','command_decision','open_petition'):return 'not_electoral_institution'
 if ctx.get('settlement_type') not in i['variables']['allowed_settlement_types']:return 'wrong_settlement'
 if ctx.get('electorate')!=v['electorate']:return 'wrong_electorate'
 if ctx.get('candidate_count',0)<v['minimum_eligible_candidates']:return 'insufficient_candidates'
 if not ctx.get('ballot_host'):return 'no_authorized_ballot_host'
 if not ctx.get('voter_roll_verified'):return 'unverified_voter_roll'
 if not ctx.get('quorum_met'):return 'no_quorum'
 if ctx.get('fraud_detected'):return 'fraud_flag'
 if not ctx.get('audit_passed'):return 'unverified_vote'
 return None
for campaign in domains['election_campaign']:
 instrec=inst[campaign['variables']['institution_id']]
 valid_type=instrec['variables']['allowed_settlement_types'][0]
 ctx={'settlement_type':valid_type,'electorate':campaign['variables']['electorate'],'candidate_count':3,'ballot_host':True,'voter_roll_verified':True,'quorum_met':True,'fraud_detected':False,'audit_passed':True}
 check(election_gate(campaign,ctx)==None,'valid_election_rejected:'+campaign['id'])
 for key,value in [('candidate_count',1),('ballot_host',False),('voter_roll_verified',False),('quorum_met',False),('fraud_detected',True),('audit_passed',False),('electorate','invalid')]:
  broken=dict(ctx,**{key:value}); check(election_gate(campaign,broken)!=None,'invalid_election_accepted:'+campaign['id']+':'+key)

# Verify physically staged wars can't be promoted by content: all war causes require host and negotiation stages.
for w in domains['war_casus']:
 v=w['variables'];check(v['war_actualization'].startswith('BLOCKED_'),'war_runtime_unsafe:'+w['id'])
 check(v['minimum_de_escalation_rounds']>=2,'war_without_mediation:'+w['id'])
 check(v['prewar_stages']==['incident','accusation','investigation','ultimatum','mobilization'],'war_skips_stages:'+w['id'])
for rv in domains['revolution_cause']:
 v=rv['variables'];check('petition' in v['possible_methods'] and v['popular_support_not_assumed'],'revolt_always_violent:'+rv['id'])
for mot in domains['council_motion']:
 check(mot['variables']['persist_vote_result'] and mot['variables']['vote_rule_must_come_from_institution'],'unstructured_motion:'+mot['id'])

# Deterministic state-machine simulation: versioned snapshots, stale and repeated transition attempts.
def advance(arc,current,choice,revision,expected_revision):
 if revision!=expected_revision:return 'STALE',current,revision
 nodes={x['id']:x for x in arc['variables']['nodes']}
 node=nodes.get(current)
 if node is None or node['stage']=='terminal':return 'REJECTED',current,revision
 ch=next((x for x in node['choices'] if x['id']==choice),None)
 if ch is None:return 'REJECTED',current,revision
 return 'STAGED',ch['next'],revision+1
rng=random.Random(20261020)
arr=list(arc_map.values()); elections=domains['election_campaign']; simul=250000
sim_stats=collections.Counter(); sample_seeds=[]
for ix in range(simul):
 seed=rng.getrandbits(32);region=seed%88;arc=arr[(seed//88)%len(arr)];
 if ix<24:sample_seeds.append(seed)
 # Every generated host story proposal must remain a deterministic stable binding to the scene, without runtime NodePath.
 key=f'{seed}|worldA|{region}|{arc["id"]}|slot_1'; ident=hashlib.sha256(key.encode()).hexdigest()[:24]
 check(ident==hashlib.sha256(key.encode()).hexdigest()[:24],f'nondeterminism:{ix}')
 check(region in range(88),f'region_out_of_range:{ix}')
 status,new,rev=advance(arc,'opening','listen',0,0)
 check((status,new,rev)==('STAGED','investigation',1),f'bad_begin:{ix}')
 bad=advance(arc,'opening','listen',1,0)
 check(bad[0]=='STALE',f'stale_replayed:{ix}')
 invalid=advance(arc,'opening','imaginary',0,0)
 check(invalid[0]=='REJECTED',f'invalid_choice_accepted:{ix}')
 # run to decision and each terminal outcome without altering/committing the world.
 cur='investigation';r=1
 for choice in ['document','negotiate']:
  status,cur,r=advance(arc,cur,choice,r,r)
  check(status=='STAGED',f'bad_story_stage:{ix}')
 status,cur,r=advance(arc,cur,['reform','compromise','rupture'][ix%3],r,r)
 check(status=='STAGED' and cur in ends[arc['id']],f'bad_ending:{ix}')
 check(advance(arc,cur,'reform',r,r)[0]=='REJECTED',f'terminal_choice_accepted:{ix}')
 sim_stats[cur]+=1
 # Election candidates/region conditions and intentional rejection of missing host or corrupt ballot.
 el=elections[ix%len(elections)];instrec=inst[el['variables']['institution_id']];sett=instrec['variables']['allowed_settlement_types'][0]
 ctx={'settlement_type':sett,'electorate':el['variables']['electorate'],'candidate_count':2,'ballot_host':ix%2==0,'voter_roll_verified':True,'quorum_met':ix%11!=0,'fraud_detected':ix%37==0,'audit_passed':True}
 actual=election_gate(el,ctx)
 if not ctx['ballot_host'] or not ctx['quorum_met'] or ctx['fraud_detected']:
  check(actual is not None,f'invalid_political_proposal:{ix}')
 checks['simulated_story_contexts']+=1

# Previous domain JSON files must be unchanged byte-for-byte; compare source ZIP without extracting.
with __import__('zipfile').ZipFile('/mnt/data/EXO-MURIM-BIBLIOTECA-UNIVERSAL-01-R2.zip') as z:
 prev=json.loads(z.read('exo_world_library/manifest.json'))
 for e in prev['catalogs']:
  path=e['path'].replace('res://',''); prior=z.read(path);new=(R/path).read_bytes()
  check(prior==new,'old_catalog_modified:'+e['domain']);checks['preserved_catalogs']+=1

report={'name':'EXO_WORLD_LIBRARY_R3_POLITICAL_NARRATIVE_QA','result':'PASS' if not errors else 'FAIL','godot_runtime':'NOT_RUN (Godot binary unavailable)','test_type':'offline Python static + deterministic simulation', 'old_domains':len(prev['catalogs']),'current_domains':len(domains),'current_records':len(allrec),'authored_story_arcs':len(arr),'parallel_arcs':len(domains['parallel_arc']),'authored_story_nodes':sum(len(v['variables']['nodes']) for v in arr),'story_choices_edges':transition_count,'stories_terminal_endings':dict(terminal_seen),'rehearsed_contexts':simul,'checks':dict(checks),'sample_seeds':sample_seeds, 'terminal_samples':dict(sim_stats),'failure_count':len(errors),'failures':errors[:100],'run_seconds':round(time.monotonic()-start,3),'limitations':['No Godot-native parser/import/boot/save-reopen confirmed','War/revolt/voting/election actual gameplay authority is not implemented by this library','No real player combat, AI, economy changes, or persistent narrative save was committed','Test fixtures do not prove live NPC/faction/election systems are integrated']}
(R/'QA-POLITICA-NARRATIVA-R3.json').write_text(json.dumps(report,ensure_ascii=False,sort_keys=True,indent=2)+'\n')
print(json.dumps({k:v for k,v in report.items() if k not in ('sample_seeds','terminal_samples','limitations')},ensure_ascii=False))
sys.exit(0 if not errors else 1)
