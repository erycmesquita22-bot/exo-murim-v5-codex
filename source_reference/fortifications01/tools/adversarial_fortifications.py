"""Additional independent mutation, edge-case, and invariance checks for Fortifications 01."""
import json,math,random,sys
from pathlib import Path
from stress_fortifications import region
from fortification_reference import plan,validate,digest,intersection,length,sub,lerp,dpointseg

checks=0;fails=[];totals={}
def check(b,label):
 global checks
 checks+=1
 if not b:fails.append(label)

def run():
 # Exact examples cover source-geometry corner cases, narrow gate passages,
 # overlapping road/river openings and all-wall-invalide slope; no Godot used.
 for seed in range(250):
  for scale in ('city','town','village'):
   c=region(seed+50000,scale,hard=False)
   p=plan(c)
   check(not validate(c,p),f'invariants_{seed}_{scale}')
   if p['status'] not in ('ready','partial'):continue
   # Paths going through courtyard entrances may not be closed by any wall.
   if scale!='city':
    selected=next((x for x in c['lots'] if x['id']==p['selected_lot']),None)
    check(selected is not None,f'courtyard_lot_missing_{seed}')
    if selected:
     for segment in p['segments']:
      check(not (intersection(selected['door'],selected['street_point'],segment['a'],segment['b']) is not None),f'courtyard_blocks_entrance_{seed}')
   # Do not rely on input parcel iteration order or call order.
   c['lots'].reverse()
   check(digest(p)==digest(plan(c)),f'input_lot_order_{seed}_{scale}')
   # A neighboring world seed that changes a parcel produces a changed plan.
   if scale=='city' and seed%10==0:
    edge=max(c['lots'],key=lambda lot:lot['p'][0]); edge['p']=(edge['p'][0]+40.0,edge['p'][1])
    check(digest(p)!=digest(plan(c)),f'boundary_sensitivity_{seed}')
 # Illegal contracts must return explicit status instead of crashing or silent drop.
 r=region(12,'city')
 for key,value in [('ready',False),('scale','wrong'),('lots',[]),('streets',[])]:
  x=dict(r);x[key]=value
  p=plan(x)
  check(p['status'] in ('skipped','invalid'),f'reject_missing_{key}')
 # Forced severe roughness: never export a wall floating in air.
 c=region(12,'city')
 c['height']=lambda v:(v[0]*17.0+v[1]*13.)
 p=plan(c)
 check(p['status'] in ('invalid','partial'), 'cliff_not_ready')
 check(not validate(c,p),'cliff_no_unsupported_wall')
 # Corner-extreme parcel intentionally tests chamfer protecting building footprints.
 c=region(45,'city')
 c['lots']=c['lots'][:1]
 for point in [(95,95),(-115,115),(120,-95),(-110,-110)]:
  lot=dict(c['lots'][0]);lot['id']=f'corner_{point[0]}_{point[1]}';lot['p']=point;c['lots'].append(lot)
 p=plan(c)
 check(not validate(c,p),'corner_bounding_envelope')
 # Very shallow road angle across enclosure should either have wide opening or
 # explicitly drop near-road segments (partial); no road-intersection may be blocked.
 for k in range(400):
  c=region(k+12000,'city',hard=k%3==0)
  start=(-150.0+ k%11, -180.0)
  end=(150.0+ k%11, 180.0)
  c['streets'].append({'a':start,'b':end,'width':9.0,'kind':'test_diagonal'})
  p=plan(c)
  check(not validate(c,p),f'extra_road_{k}')
  if p['status'] in ('ready','partial'):
   for seg in p['segments']:
    hit=intersection(start,end,seg['a'],seg['b'])
    check(hit is None,f'diagonal_blocked_{k}')
 return {'scope':'Independent reference planner and mutation tests; NOT Godot','checks':checks,'failures':len(fails),
         'examples':fails[:25], 'status':'PASS' if not fails else 'FAIL'}

if __name__=='__main__':
 r=run();p=Path(__file__).parent.parent/'results/QA-FORTIFICACOES-01-ADVERSARIAL.json';p.write_text(json.dumps(r,indent=2));print(json.dumps(r,indent=2));sys.exit(0 if r['status']=='PASS' else 1)
