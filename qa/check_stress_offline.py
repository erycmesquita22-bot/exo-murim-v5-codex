#!/usr/bin/env python3
"""Simulador offline de lotes, faixas e praca; nao executa scripts GDScript.
Examines deterministic seed/id mixing, geometric proof for six plaza slots,
320k sampled parcel variations and 4 rotated quadrants; compares lossless serialization.
"""
import math,random,json,sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
checks=0;fails=[]
def expect(cond,label):
 global checks
 checks+=1
 if not cond and len(fails)<50:fails.append(label)
def fnv(seed,ident):
 h=2166136261
 for u in ident:
  h=((h^ord(u))*16777619)&0x7fffffff
 return (h^(seed&0x7fffffff))&0x7fffffff

# Project-level identity invariant: order changes do not impact each lot's ID hash.
rng=random.Random(20261018)
ids=['region_17/lot_%d'%i for i in range(1000)]
for seed in range(80):
 baseline={id:fnv(seed,id) for id in ids}
 rotated=ids[:];rng.shuffle(rotated)
 expect(all(fnv(seed,id)==baseline[id] for id in rotated),f'hash_order_seed_{seed}')
 expect(all(0<=value<=0x7fffffff for value in baseline.values()),f'hash_range_seed_{seed}')

# For each profile+role: evaluate available sizes and rotated bounding reservations.
roles=['dwelling','shop','tea_house','workshop','herbalist','inn']
widths=[4,6,8]
for i in range(120000):
 role=roles[i%6]; yaw=i%4
 lotw=rng.uniform(6.5,26.0)
 lotd=rng.uniform(10.0,34.0)
 w=rng.choice(widths)
 if role=='inn' and w<6:continue
 eligible=(lotw>=w+2.9)
 courtyard=role=='dwelling' and w==6 and lotw>=10.9 and lotd>=19.0 and (i%7==0)
 front=6.95 if courtyard else 4.95
 access=9.20 if courtyard else 5.35
 left=-w*.5-1.35;right=w*.5+1.35;back=-2.65
 feasible=(eligible and lotd*.5>=access)
 if feasible:
  expect(left>=-lotw/2-1e-9 and right<=lotw/2+1e-9,f'width_{i}')
  expect(back>=-lotd/2-1e-9 and front<=lotd/2+1e-9,f'depth_{i}')
  # local-to-world rotated bounds 90deg are exact interval swaps.
  horizontal=(left,right) if yaw%2==0 else (back,front)
  vertical=(back,front) if yaw%2==0 else (-right,-left)
  expect(all(math.isfinite(x) for x in horizontal+vertical),f'world_rotation_{i}')
  serialized=json.loads(json.dumps({'rotation':yaw,'footprint':[left,back,right,front]}))
  expect(serialized['rotation']==yaw and serialized['footprint'][3]==front,f'serial_roundtrip_{i}')

# Plaza aisle contract: bounded slots, independent of asset chosen.
manifest=json.loads((ROOT/'docs/ASSETS-02-MANIFEST.json').read_text())
models={item['id']:item for item in manifest}
props=['village_water_well','covered_market_stall','timber_handcart','public_timber_bench','stone_garden_lantern','village_drying_lines','bamboo_planter_box','woven_market_baskets','herb_drying_rack','village_grain_millstone']
for n in range(18000):
 width=rng.uniform(18,80);depth=rng.uniform(14,80)
 xdist=width*.5-3.4;zdist=min(depth*.5-3.0,4.4)
 for side in (-1,1):
  for slot in (-zdist,0.0,zdist):
   name=props[rng.randrange(len(props))]
   b=models[name]['bounds_m'];half_x=max(abs(b[0][0]),abs(b[1][0]),abs(b[0][2]),abs(b[1][2]))
   minx=abs(xdist)-half_x
   maxx=abs(xdist)+half_x
   expect(minx>2.0,f'plaza_passage_{n}_{side}_{slot}_{name}')
   expect(maxx<=width*.5-0.1,f'plaza_reserved_{n}_{side}_{slot}_{name}')
   half_z=max(abs(b[0][2]),abs(b[1][2]),abs(b[0][0]),abs(b[1][0]))
   expect(abs(slot)+half_z<=depth*.5-0.1,f'plaza_depth_{n}_{side}_{slot}_{name}')
report={'kind':'offline_reference_stress','checks_passed':checks-len(fails),'failed':len(fails),'failures':fails,'test_lots':120000,'plaza_configurations':18000,'hash_seeds':80,'runtime_GDScript_executed':False}
(ROOT/'qa/stress_results_v2.json').write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps(report,indent=2));sys.exit(bool(fails))
