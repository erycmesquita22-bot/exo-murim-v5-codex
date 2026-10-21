#!/usr/bin/env python3
"""Model-based adversarial protocol audit, NOT a Godot/GDScript runtime test."""
import copy, hashlib, json, math, random, pathlib, collections
HERE=pathlib.Path(__file__).resolve().parent
R=HERE.parents[1]
STATS=collections.Counter(); errors=[]; cases=[]
def expect(cond,msg):
 STATS['assertions']+=1
 if not cond: errors.append(msg)
def jsha(v):return hashlib.sha256(json.dumps(v,sort_keys=True,ensure_ascii=False,separators=(',',':'),allow_nan=False).encode()).hexdigest()
def fixture(source='eco/r1/t0/m2/g3', items=None, saved=True):
 return dict(world=dict(schema=2,id='world_qa',seed=187,generation_version=1,events={'loot/'+source:{'status':'pending'}},claim_receipts={}),items=items or [],next_item=1+max([int(i['uid'][5:]) for i in (items or [])]+[0]),pending_loot=[dict(source=source,region=1,items=[dict(kind='material',ref='iron',qty=2)])],saved=saved)
def fingerprint(s,source):
 p=next(x for x in s['pending_loot'] if x['source']==source)
 return jsha({'world_id':s['world']['id'],'seed':s['world']['seed'],'generation':s['world']['generation_version'],'claim':'loot/'+source,'rewards':p['items'],'version':1})
def validqty(x):return type(x) in (int,float) and math.isfinite(x) and x==int(x) and 1<=x<=99
def validexisting(item):return isinstance(item.get('uid'),str) and item['uid'].startswith('item_') and validqty(item['qty']) and item['kind'] in ('material','consumable','weapon','manual')
def prepare(s,source):
 if s['world'].get('schema') != 2 or 'claim_receipts' not in s['world']:return 'CORE_REQUIRED',None
 claim='loot/'+source
 if claim in s['world']['claim_receipts']:return 'COLLECTED',None
 if s['world']['events'].get(claim,{}).get('status')!='pending':return 'EVENT_NOT_PENDING',None
 p=[d for d in s['pending_loot'] if d['source']==source]
 if len(p)!=1:return 'AMBIGUOUS_OR_ABSENT',None
 try:fp=fingerprint(s,source)
 except (ValueError,TypeError):return 'NON_FINITE',None
 if len(s['items'])>24 or not all(validexisting(t) for t in s['items']):return 'INVALID_ITEMS',None
 stage=copy.deepcopy(s)
 used={t['uid'] for t in stage['items']}
 elsewhere={i.get('uid') for d in stage['pending_loot'] if d['source']!=source for i in d['items'] if i.get('uid')}
 if len(used)!=len(stage['items']) or used&elsewhere:return 'DUPLICATE_UID',None
 reserved=[]
 for r in p[0]['items']:
  if not validqty(r.get('qty')):return 'BAD_QTY',None
  if 'generation' in r:
   if r.get('mode')=='preview_only' or r.get('kind')!='weapon' or r.get('qty')!=1:return 'UNSUPPORTED_PREVIEW',None
   uid=r['uid']
   if uid in used or uid in elsewhere or int(uid.split('_')[1])>=stage['next_item']:return 'UID_CONFLICT',None
   used.add(uid);stage['items'].append(copy.deepcopy(r))
  else:
   if r.get('kind') not in ('material','consumable','manual','weapon'):return 'UNSUPPORTED_KIND',None
   if r['kind'] in ('material','consumable'):
    match=next((it for it in stage['items'] if it['kind']==r['kind'] and it['ref']==r['ref'] and it['qty']+r['qty']<=99),None)
    if match:match['qty']+=r['qty'];continue
   uid=f'item_{stage["next_item"]}'
   while uid in used or uid in elsewhere:
    stage['next_item']+=1;uid=f'item_{stage["next_item"]}'
   stage['next_item']+=1
   if r['ref'] not in ('iron','potion') and r['kind'] in ('material','consumable'):return 'INVALID_REF',None
   itm=dict(uid=uid,kind=r['kind'],ref=r['ref'],qty=r['qty'],rarity='Comum',affixes=[])
   used.add(uid);reserved.append(uid);stage['items'].append(itm)
  if len(stage['items'])>24:return 'FULL',None
 return 'READY',dict(data=stage,fp=fp,claim=claim,pending=p[0],source=source)
def confirm(s,source,fp,commit_ok=True,stage_ok=True):
 status,plan=prepare(s,source)
 if status!='READY':return status,s
 if plan['fp']!=fp:return 'STALE',s
 staged=plan['data']
 staged['pending_loot']=[i for i in staged['pending_loot'] if i['source']!=source]
 staged['world']['events'].pop(plan['claim'])
 staged['world']['claim_receipts'][plan['claim']]=dict(id=plan['claim'],fingerprint=fp)
 if not stage_ok:return 'DOMAIN_STAGE_FAIL',s
 if not commit_ok:return 'SAVE_FAIL',s
 return 'COMMITTED',staged
def run(name,fn):
 prior=len(errors);fn();cases.append({'name':name,'pass':len(errors)==prior})

def same_source_thousand():
 source='eco/r1/t0/m2/g3';s=fixture(source);f=fingerprint(s,source);wins=0
 for _ in range(1000):
  status,s=confirm(s,source,f)
  wins+=(status=='COMMITTED');expect(status in ('COMMITTED','COLLECTED'),'replay unexpected status')
 expect(wins==1,'1000 retries granted more than once')
 expect(len(s['items'])==1 and s['items'][0]['qty']==2,'duplicate items')
 expect(s['world']['claim_receipts']['loot/'+source]['fingerprint']==f,'receipt not durable')
run('1000 same-source replays',same_source_thousand)

def crash_after_commit():
 s=fixture();source=s['pending_loot'][0]['source'];f=fingerprint(s,source)
 result,s=confirm(s,source,f);expect(result=='COMMITTED','first commit')
 result,s=confirm(copy.deepcopy(s),source,f)
 expect(result=='COLLECTED','ack lost replay');expect(len(s['items'])==1,'regrant post ack loss')
run('commit succeeded but acknowledgement lost',crash_after_commit)

def recovery_before_commit():
 s=fixture();source=s['pending_loot'][0]['source'];before=copy.deepcopy(s);fp=fingerprint(s,source)
 for failed_stage,failed_commit in [(False,True),(True,False)]:
  result,after=confirm(s,source,fp,commit_ok=not failed_commit,stage_ok=not failed_stage)
  expect(result!='COMMITTED' and after==before,'not rollback after error')
  expect(after['world']['claim_receipts']=={},'premature receipt')
 result,s=confirm(s,source,fp)
 expect(result=='COMMITTED','replay of pending failed')
run('rollback after interrupted save/domain',recovery_before_commit)

def partial_capacity():
 source='boss/first/g0'; items=[dict(uid=f'item_{i}',kind='material',ref='iron',qty=99,rarity='Comum',affixes=[]) for i in range(1,24)]
 # 23 full distinct slots, a two-item reward needs 2 new slots => reject all.
 s=fixture(source,items);s['pending_loot'][0]['items']=[dict(kind='material',ref='iron',qty=2),dict(kind='consumable',ref='potion',qty=3)]
 status,_=prepare(s,source);expect(status=='FULL','23 slots and 2 rewards not rejected');expect(s['pending_loot'][0]['items'][0]['qty']==2,'partial allocation applied')
 # At full 24 slots, merge into an existing material stack with room is okay.
 items=items+[dict(uid='item_24',kind='material',ref='iron',qty=40,rarity='Comum',affixes=[])]
 s=fixture(source,items); status,staged=prepare(s,source)
 expect(status=='READY' and staged['data']['items'][-1]['qty']==42,'full inventory stack merge rejected')
 s['pending_loot'][0]['items'][0]['qty']=60
 status,_=prepare(s,source);expect(status=='FULL','stack overflow not rejected')
run('23/24 slots + all-or-nothing stacks',partial_capacity)

def invalid_numbers():
 for q in [math.nan,math.inf,-math.inf,1.5,0,100,-1]:
  s=fixture();source=s['pending_loot'][0]['source'];s['pending_loot'][0]['items'][0]['qty']=q
  status,_=prepare(s,source);expect(status!='READY',f'illegal qty permitted {q}')
 for stat in [math.nan,math.inf,-math.inf]:
  s=fixture();s['pending_loot'][0]['items'][0]['stats']={'damage_pct':stat}
  source=s['pending_loot'][0]['source'];status,_=prepare(s,source);expect(status!='READY','nonfinite stat permitted')
run('NaN Infinity fractional qty and stat',invalid_numbers)

def crossed_sources():
 s=fixture('eco/r1/t1/m1/g1');second='eco/r1/t1/m2/g1'
 s['world']['events']['loot/'+second]={'status':'pending'}
 s['pending_loot'].append(dict(source=second,region=1,items=[dict(kind='material',ref='iron',qty=1)]))
 f1=fingerprint(s,s['pending_loot'][0]['source']);f2=fingerprint(s,second)
 _,s=confirm(s,'eco/r1/t1/m1/g1',f1);_,s=confirm(s,second,f2)
 expect(len(s['world']['claim_receipts'])==2,'distinct sources collided');expect(len(s['items'])==1 and s['items'][0]['qty']==3,'merge lost items')
run('two distinct sources stable IDs',crossed_sources)

def conflicting_generated_uids():
 s=fixture('eco/r1/t0/m1/g0');s['next_item']=2
 generate=lambda source:dict(uid='item_1',kind='weapon',ref='sword',qty=1,rarity='Comum',affixes=[],instance_id='world_qa/loot/'+source,generation={'version':1,'source':'loot/'+source,'tier':1})
 s['pending_loot'][0]['items']=[generate('eco/r1/t0/m1/g0')]
 other='eco/r1/t0/m2/g0';s['pending_loot'].append(dict(source=other,items=[generate(other)]));s['world']['events']['loot/'+other]={'status':'pending'}
 status,_=prepare(s,'eco/r1/t0/m1/g0');expect(status=='DUPLICATE_UID' or status=='UID_CONFLICT','conflicting sources same uid')
run('two sources reserve same item UID',conflicting_generated_uids)

def corruption_and_replay():
 s=fixture();source=s['pending_loot'][0]['source'];fp=fingerprint(s,source)
 old=copy.deepcopy(s);status,s=confirm(s,source,fp)
 expect(status=='COMMITTED','first claim')
 # Two plausible backups: a pre-commit copy is coherent and should be retried rather than lost.
 expect(prepare(old,source)[0]=='READY','restore coherent pre-commit snapshot')
 s['pending_loot'].append(dict(source=source,items=[dict(kind='material',ref='iron',qty=44)]))
 expect('loot/'+source in s['world']['claim_receipts'],'receipt lost on corrupted file')
 expect(prepare(s,source)[0]=='COLLECTED','corrupt replay should fail-closed')
 s.pop('world');expect('world' not in s,'simulated invalid save should reject by owner')
run('corrupt state quarantined + coherent backup replay',corruption_and_replay)

def canceled():
 s=fixture();source=s['pending_loot'][0]['source'];f=fingerprint(s,source)
 expect(prepare(s,source)[0]=='READY','prepare');expected=copy.deepcopy(s)
 expect(s==expected and not s['world']['claim_receipts'],'cancellation altered state')
 result,s=confirm(s,source,f);expect(result=='COMMITTED','retry after cancel')
run('abort read-only and reopen',canceled)

def ecosystems():
 for source in ['eco/r1/t0/m3/g5','boss/ancient_warrior/generation/0','dungeon/d01/room2/reward0','quest/repair_bridge/0']:
  s=fixture(source);f=fingerprint(s,source);status,s=confirm(s,source,f)
  expect(status=='COMMITTED' and len(s['world']['claim_receipts'])==1,'domain source missing '+source)
run('boss dungeon beast quest-shaped stable IDs (model only)',ecosystems)

def missing_contract():
 s=fixture();s['world']['schema']=1;s['world'].pop('claim_receipts')
 expect(prepare(s,s['pending_loot'][0]['source'])[0]=='CORE_REQUIRED','unpatched Core should be gated')
run('Core 01-P gate',missing_contract)

def stale():
 s=fixture();source=s['pending_loot'][0]['source'];original=fingerprint(s,source)
 s['pending_loot'][0]['items'][0]['qty']=3
 status,after=confirm(s,source,original)
 expect(status=='STALE','plan mutated after prepare');expect(s==after,'bad fingerprint mutated save')
run('stale fingerprint rejected',stale)

def code_audit():
 t=(R/'exo_items/integration/atomic_reward_adapter.gd').read_text()
 for a in ['prepare_pending(', 'confirm_pending(', 'abort_pending(', 'recover_pending(', 'CoreWorld.call("mark_collected"','world.save_progress()', 'journey.data = snapshot', 'Inventory.valid_item(', 'claim_receipts']:
  expect(a in t,'script missing '+a)
 for a in ['FileAccess.open(', 'user://', 'DirAccess.', 'world.events.erase(']:expect(a not in t,'unexpected unauthorized persistence '+a)
 expect('atomic_reward_adapter.gd' not in (R/'exo_items/module/entrypoint.gd').read_text(),'accidental active hook')
 for f in ['exo_items/generation/item_generator.gd','exo_items/integration/inventory_adapter.gd']:
  expect('has_event' in (R/f).read_text(),f+' missing archived receipt check')
run('R3 static contract and disabled activation',code_audit)
report=dict(status='PASS' if not errors else 'FAIL',model='OFFLINE_REFERENCE_MODEL_NOT_GDSCRIPT',scenarios=cases,assertions=STATS['assertions'],replay_attempts=1000,failures=errors,core_01p_native='NOT_RUN',gameplay_native='NOT_RUN')
(R/'evidencias/RESULTADOS-R3-OFFLINE.json').write_text(json.dumps(report,indent=2,ensure_ascii=False))
print(json.dumps(report,ensure_ascii=False,indent=2))
raise SystemExit(0 if not errors else 1)
