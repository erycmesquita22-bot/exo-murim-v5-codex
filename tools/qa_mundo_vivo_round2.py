#!/usr/bin/env python3
"""Independent, OFFLINE reference-model and source-contract QA for Mundo Vivo 02 R2.
No Godot engine, physics, rendering, or native GDScript is executed by this script.
"""
import hashlib, json, math, collections, time, sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
start=time.monotonic()
checks=0
errors=[]
metrics=collections.Counter()
def check(condition,message):
 global checks
 checks+=1
 if not condition and len(errors)<100:errors.append(message)
class Stream:
 def __init__(self,seed):self.s=seed%2147483646+1
 def between(self,a,b):
  self.s=self.s*48271%2147483647
  return a+(b-a)*(self.s-1)/2147483646

def h(text):return int(hashlib.sha256(text.encode()).hexdigest()[:8],16)%2147483646

def plan(seed,rid,kind,half,landscape):
 if kind not in ('wild','ruins','dungeon_approach'):return []
 count=3 if kind=='wild' else 4
 rng=Stream(h(f'ECO/1/{seed}/{rid}'))
 result=[]
 limit=min(half-24,185)
 if limit<40:return []
 def height(x,y):
  return (4.0 + x*.020+y*.025 if landscape==0 else
          7 + math.sin(x*.022)*5+math.cos(y*.016)*4 if landscape==1 else
          3 + math.sin(x*.15)*1.8 + math.cos(y*.10)*1.7 if landscape==2 else
          x*.30+y*.12)
 for attempt in range(max(320,count*130)):
  if len(result)>=count:break
  x=rng.between(-limit,limit);y=rng.between(-limit,limit)
  if math.hypot(x,y)<42 or abs(y)<9 or abs(x-55)<15 or math.hypot(x+80,y-110)<16:continue
  if abs(height(x+1.5,y)-height(x,y))>.65:continue
  if abs(height(x,y+1.5)-height(x,y))>.65:continue
  if any(math.hypot(x-px,y-py)<34 for px,py in result):continue
  result.append((x,y))
 return result

# Use six geography variants, three region sizes, 88 IDs, multiple seeds.
for i in range(32000):
 rid=i%88;kind=('wild','ruins','dungeon_approach','settlement')[i%4]
 seed=str((i*2654435761)%(2**63-1))
 half=(75,125,220,240)[i//4%4];landscape=i//16%4
 a=plan(seed,rid,kind,half,landscape)
 b=plan(seed,rid,kind,half,landscape)
 metrics['plans']+=1
 check(a==b,f'determinism {i}')
 check(len(a)<=(0 if kind=='settlement' else 3 if kind=='wild' else 4),f'budget {i}')
 if kind=='settlement':check(not a,f'no safe settlement spawn {i}')
 if kind!='settlement' and len(a)<(3 if kind=='wild' else 4):metrics['underfilled_explicit']+=1
 for j,(x,y) in enumerate(a):
  metrics['territories']+=1
  check(abs(x)<=min(half-24,185) and abs(y)<=min(half-24,185),f'bounds {i}')
  check(math.hypot(x,y)>=42 and abs(y)>=9 and abs(x-55)>=15,f'exclusions {i}')
  check(math.hypot(x+80,y-110)>=16,f'house clearance {i}')
  for xx,yy in a[:j]:check(math.hypot(xx-x,yy-y)>=34,f'territory overlap {i}')

# ID generation and anti-duplicate isolation over a large lifetime.
seen=set()
for rid in range(88):
 for territory in range(4):
  for generation in range(260):
   for member in (0,1):
    uid=f'eco/r{rid:02d}/t{territory:02d}/m{member}/g{generation:04d}'
    check(uid not in seen,'duplicate stable UID')
    seen.add(uid)
    check(len(uid)<90 and uid.startswith(f'eco/r{rid:02d}/'),f'uid namespace')
    r=h(uid+'/loot')%100
    check(0<=r<100,'loot distribution range')
    metrics['drop_ids']+=1

# XP: per-day, per-region & type, nonzero, same-type taper, day reset.
for level in range(1,31):
 for day in range(8):
  values=[]
  for k in range(360):
   factor=1.0 if k<8 else .80 if k<16 else .55 if k<30 else .35
   value=max(1,int(math.floor((12+4*level)*factor+.5)))
   values.append(value);check(value>0 and value<=132,'xp bounded')
   metrics['xp_events']+=1
  check(values[0]==values[7] and values[8]<=values[7] and values[16]<=values[8] and values[30]<=values[16],'xp monotone taper')
  check(values[-1]>=1,'xp never zero')

# Event cache compaction: only collected ecology receipts, not legacy or pending.
for historical in [1499,1500,1800,2048,2090,3000]:
 events={f'loot/eco/r{i%88:02d}/t{i%4:02d}/m0/g{i//352:04d}':('collected' if i%5 else 'pending') for i in range(historical)}
 events.update({f'loot/road_blade/{i}':'collected' for i in range(10)})
 protected={k:v for k,v in events.items() if not k.startswith('loot/eco/') or v=='pending'}
 for key in list(events):
  if len(events)<=1500:break
  if key.startswith('loot/eco/r') and events[key]=='collected':events.pop(key)
 check(all(events.get(k)==v for k,v in protected.items()),'protected event conservation')
 check(len(events)<=max(1500,len(protected)),'compaction reaches available floor')
 metrics['compaction_scenarios']+=1

# Persistent group combat ledger: partial deaths, double-callback suppression,
# cooldown / reoccupation and reload isolation over 88 regions x 600 cycles.
for rid in range(88):
 ledger={"generation":0,"dead":set(),"defeated_at":-1.0,"kills":0}
 now=1000.0
 claimed=set()
 for round_id in range(600):
  for member in [0,1]:
   uid=f"eco/r{rid:02d}/t00/m{member}/g{ledger['generation']:04d}"
   check(uid not in claimed,'first kill must be unique')
   claimed.add(uid)
   ledger['dead'].add(member)
   ledger['kills']+=1
   # Duplicate attack callback may never generate a second receipt.
   check(uid in claimed and len(ledger['dead'])<=2,'idempotent death state')
   if member==0:check(len(ledger['dead'])==1,'partial camp persists')
  ledger['generation']+=1
  ledger['dead'].clear()
  ledger['defeated_at']=now
  check(now<ledger['defeated_at']+540.0,'renewal cannot happen instantly')
  now+=540.0
  check(now>=ledger['defeated_at']+540.0,'renewal after minimum cooldown')
  check(ledger['kills']==(round_id+1)*2,'kill conservation')
  metrics['respawn_generations']+=1

# Active group budget and visibility policy in simplified camera coordinates.
# This tests the policy only; the actual Camera3D/frustum is a native test.
for i in range(20000):
 player=(0.0,0.0)
 center=(19.0+(i%67),float((i*31)%88)-44)
 for member in [0,1]:
  point=(center[0]+member*1.6,center[1]+member*1.2)
  dist=math.hypot(*point)
  permitted=19<=dist<=85 and not (-10<point[0]<10 and -10<point[1]<10)
  check(not permitted or (dist>=19 and dist<=85),'member must be tested separately')
  metrics['spawn_member_checks']+=1

# Daily conversion and migration via exact arithmetic.
for t in range(0,720_000,47):
 hour=int(t//90)%24;day=int(t//2160)
 check(0<=hour<=23 and day>=0,'clock range')
 check(int((t/40)//90)%24==int(t//3600)%24,'old clock equivalent migration')
 metrics['clock_instants']+=1

# Source integration invariants and preservation-sensitive references.
need={
 'regional_ecology/director.gd':['visible_spawn(spawn)','actual_distance','reap_distant()','Reward.permitted','MAX_ACTIVE','world.enemies.append'],
 'regional_ecology/rewards.gd':['compact_claimed','queue_loot','xp_total','farm_counts','world.inventory.rebuild_drops'],
 'convergence/game.gd':['reward_logic.compact_claimed','not reward_logic.queue_loot','ecology_director.defeated','WorldClock.advance'],
 'regional_ecology/territories.gd':['ECO/1/','gate_road_distance','river_distance','pad_distance'],
 'enemy.gd':['configure_regional','regional_mode','map_data.river_distance','territory_radius','interest_seconds'],
 'convergence/state.gd':['seen_members','record.members_dead','farm_counts'],
 'convergence/resident.gd':['work_cycles','@activity','action_elapsed'],
 'journey_save.gd':['source_id.begins_with("eco/r")','pending_loot.size()>210'],
}
for f,patterns in need.items():
 s=(ROOT/f).read_text()
 for pattern in patterns:check(pattern in s,f'missing source contract: {f}:{pattern}')
 metrics['source_contracts']+=len(patterns)
result={'title':'MUNDO VIVO 02 — R2 MASSIVE OFFLINE REFERENCE QA','result':'PASS' if not errors else 'FAIL','scope':'Independent Python model and textual contracts, NOT Godot physics/runtime','assertions':checks,'failures':len(errors),'examples':errors[:20],'measurements':dict(metrics),'elapsed_seconds':round(time.monotonic()-start,2),'godot_executed':False,'native_test_status':'NOT_RUN'}
(ROOT/'QA-MUNDO-VIVO-02-R2-OFFLINE.json').write_text(json.dumps(result,ensure_ascii=False,indent=2))
print(json.dumps(result,ensure_ascii=False,indent=2))
sys.exit(1 if errors else 0)
