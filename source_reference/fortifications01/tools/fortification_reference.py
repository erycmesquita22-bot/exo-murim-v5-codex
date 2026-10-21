"""EXO Fortifications 01 - independent geometry reference and stress-test oracle.
NOT the Godot runtime. Inputs correspond to Genesis settlement_plan dictionaries.
Uses deterministic arithmetic and no global RNG in the planner.
"""
from __future__ import annotations
import math,hashlib,json,random
from dataclasses import dataclass
from typing import Callable

EPS=1e-8

def add(a,b):return(a[0]+b[0],a[1]+b[1])
def sub(a,b):return(a[0]-b[0],a[1]-b[1])
def mul(a,k):return(a[0]*k,a[1]*k)
def dot(a,b):return a[0]*b[0]+a[1]*b[1]
def cross(a,b):return a[0]*b[1]-a[1]*b[0]
def length(a):return math.hypot(*a)
def unit(a):
 l=length(a);return (a[0]/l,a[1]/l) if l>1e-10 else (1.,0.)
def lerp(a,b,t):return add(a,mul(sub(b,a),t))
def dpointseg(p,a,b):
 v=sub(b,a);t=max(0.,min(1.,dot(sub(p,a),v)/(dot(v,v)+EPS)));return length(sub(p,lerp(a,b,t)))
def intersection(a,b,c,d):
 r=sub(b,a);s=sub(d,c);det=cross(r,s)
 if abs(det)<EPS:return None
 q=sub(c,a);t=cross(q,s)/det;u=cross(q,r)/det
 if -1e-7<=t<=1+1e-7 and -1e-7<=u<=1+1e-7:return max(0.,min(1.,t)),max(0.,min(1.,u))
 return None

def ring_poly(center,forward,side,lo_x,hi_x,lo_y,hi_y,chamfer):
 coords=[(lo_x+chamfer,lo_y),(hi_x-chamfer,lo_y),(hi_x,lo_y+chamfer),(hi_x,hi_y-chamfer),
 (hi_x-chamfer,hi_y),(lo_x+chamfer,hi_y),(lo_x,hi_y-chamfer),(lo_x,lo_y+chamfer)]
 return [add(add(center,mul(side,x)),mul(forward,y)) for x,y in coords]

def signed_area(poly):return sum(cross(poly[i],poly[(i+1)%len(poly)]) for i in range(len(poly)))/2.
def perimeter(poly):return sum(length(sub(poly[(i+1)%len(poly)],poly[i])) for i in range(len(poly)))
def along_poly(poly):
 accum=[0.]
 for i in range(len(poly)):accum.append(accum[-1]+length(sub(poly[(i+1)%len(poly)],poly[i])))
 return accum

def arcdist(s,t,perim):return abs((s-t+perim*.5)%perim-perim*.5)

def point_s(poly,cums,s):
 s=s%cums[-1]
 for i in range(len(poly)):
  if cums[i]-EPS<=s<=cums[i+1]+EPS:
   d=cums[i+1]-cums[i];return lerp(poly[i],poly[(i+1)%len(poly)],(s-cums[i])/d)
 return poly[0]

def water_segments(region):
 return [(region.get('river_hub',(72.,72.)),r['p']) for r in region.get('rivers',[])]

def route_segments(region):
 res=[(r['a'],r['b'],float(r.get('width',5)),str(r.get('kind','street'))) for r in region.get('streets',[])]
 res += [((0.,0.),g['p'],float(g.get('width',7.)),"world_portal") for g in region.get('gates',[])]
 return res

def generate_ring(region,scale):
 lots=region.get('lots',[])
 if not lots:return None,'no_lots'
 streets=region.get('streets',[])
 if not streets:return None,'no_streets'
 direction=unit(sub(streets[0]['b'],streets[0]['a']));side=(-direction[1],direction[0]);center=(0.,0.)
 if scale=='city':
  pts=[]
  for lot in lots:
   r=float(lot.get('halfsize',5.5))+15.5
   p=lot['p'];px=dot(sub(p,center),side);py=dot(sub(p,center),direction)
   pts.append((px-r,py-r));pts.append((px+r,py+r))
  for f in region.get('fixtures',[]):
   p=f['p'];r=float(f.get('halfsize',2.5))+12.;x=dot(p,side);y=dot(p,direction)
   pts.extend([(x-r,y-r),(x+r,y+r)])
  pts.extend([(-13.,-13.),(13.,13.)])
  xmin=min(p[0] for p in pts);xmax=max(p[0] for p in pts)
  ymin=min(p[1] for p in pts);ymax=max(p[1] for p in pts)
  chamfer=min(14.,(xmax-xmin)*.09,(ymax-ymin)*.09)
  kind='city_wall'; selected=None
 else:
  # Small gated pátio: not a full settlement wall. Avoid frontages too close to roads.
  candidates=sorted(lots,key=lambda l:(0 if l.get('function') in ('inn','martial_school','farmstead','administration') else 1,l['id']))
  selected=None
  for lot in candidates:
   side_len=float(lot.get('halfsize',5.5))+3.4
   p=lot['p']
   if float(lot.get('frontage',0))<side_len+4.:continue
   if any(length(sub(p,l['p'])) < side_len+float(l.get('halfsize',5.5))+2. for l in lots if l['id']!=lot['id']):continue
   if any(dpointseg(p,*river)<side_len+11. for river in water_segments(region)):continue
   selected=lot;break
  if selected is None:return None,'no_safe_courtyard'
  p=selected['p'];center=p
  toward=unit(sub(selected['street_point'],p));direction=toward;side=(-direction[1],direction[0]);r=float(selected.get('halfsize',5.5))+3.4
  xmin=-r;xmax=r;ymin=-r;ymax=r;chamfer=1.8
  kind='courtyard_wall'
 poly=ring_poly(center,direction,side,xmin,xmax,ymin,ymax,chamfer)
 half=region.get('half_extent',256.)
 if any(abs(p[0])>half-18 or abs(p[1])>half-18 for p in poly):return None,'perimeter_outside_region'
 if abs(signed_area(poly))<100.:return None,'degenerate_perimeter'
 return {'polygon':poly,'kind':kind,'selected':selected,'direction':direction,'side':side},''

def plan(region):
 scale=region.get('scale','')
 if scale not in ('city','town','village') or not region.get('ready',False):
  return {'status':'invalid','errors':['not_ready_or_scale'],'segments':[],'openings':[],'towers':[]}
 ring,error=generate_ring(region,scale)
 if ring is None:
  return {'status':'skipped','errors':[error],'segments':[],'openings':[],'towers':[],'scale':scale}
 poly=ring['polygon'];cums=along_poly(poly);P=cums[-1]
 roads=route_segments(region) if scale=='city' else [(ring['selected']['door'],ring['selected']['street_point'],4.,'courtyard_entry')]
 waters=water_segments(region) if scale=='city' else []
 centers=[];raw=[]
 for typ,lines in [('gate',roads),('river',[(a,b,12.,'river') for a,b in waters])]:
  for a,b,width,tag in lines:
   for i in range(len(poly)):
    c=poly[i];d=poly[(i+1)%len(poly)];hit=intersection(a,b,c,d)
    if hit is None:continue
    _,t=hit
    edge=unit(sub(d,c));path=unit(sub(b,a));angle=abs(cross(edge,path))
    # Near-tangential roads need a larger safety gap than a perpendicular road.
    requested=max(5.5 if typ=='gate' and scale!='city' else 9.,float(width)+5.)
    opening_width=min(70.,requested/max(.22,angle))
    ss=(cums[i]+length(sub(d,c))*t)%P
    if any(typ==existing['type'] and arcdist(ss,existing['s'],P)<1.5 for existing in raw):continue
    raw.append({'s':ss,'width':opening_width,'type':typ,'source':tag,'angle':round(angle,5)})
 # Mandatory front door opening for courtyard. If geometry fails, reject explicitly.
 if scale!='city' and not any(op['type']=='gate' for op in raw):
  return {'status':'invalid','errors':['courtyard_no_entrance'],'segments':[],'openings':[],'towers':[]}
 # To protect streets parallel and near the walls, also reject any fragment intersecting road clearance.
 def in_gap(s):return any(arcdist(s,x['s'],P)<x['width']*.5+1e-8 for x in raw)
 # Exact subdivision at every opening boundary and every octagon vertex.
 boundaries=sorted(set([0.,P]+cums[1:-1]+[((o['s']+sign*o['width']*.5)%P) for o in raw for sign in (-1,1)]))
 sampler=region.get('height',lambda p:0.)
 walls=[];skipped={'river':0,'road':0,'steep':0,'near_road':0}
 for lo,hi in zip(boundaries,boundaries[1:]):
  if hi-lo<1e-7:continue
  if in_gap((lo+hi)*.5):
   names=[o['type'] for o in raw if arcdist((lo+hi)*.5,o['s'],P)<o['width']*.5+1e-8]
   skipped['river' if 'river' in names else 'road']+=1
   continue
  count=max(1,math.ceil((hi-lo)/2.8))
  for k in range(count):
   s0=lo+(hi-lo)*k/count;s1=lo+(hi-lo)*(k+1)/count
   a=point_s(poly,cums,s0);b=point_s(poly,cums,s1)
   mid=lerp(a,b,.5)
   if scale=='city' and any(dpointseg(mid,x,y)<width*.5+2.5 for x,y,width,_ in roads):
    skipped['near_road']+=1;continue
   if any(dpointseg(mid,x,y)<11. for x,y in waters):
    skipped['river']+=1;continue
   heights=[float(sampler(lerp(a,b,t))) for t in (0.,.25,.5,.75,1.)]
   if not all(math.isfinite(h) for h in heights) or max(heights)-min(heights)>2.4:
    skipped['steep']+=1;continue
   # These heights represent terrain support. Renderer anchors foundation under min sampled elevation.
   walls.append({'a':a,'b':b,'base':min(heights)-.65,'top':max(heights)+(6.2 if scale=='city' else 2.8),'heights':heights})
 towers=[]
 if scale=='city':
  for s in cums[:-1]:
   if not in_gap(s) and all(arcdist(s,o['s'],P)>o['width']*.5+5.5 for o in raw):
    p=point_s(poly,cums,s)
    if not any(dpointseg(p,*r)<14. for r in waters) and not any(dpointseg(p,a,b)<w*.5+5. for a,b,w,_ in roads):towers.append({'p':p,'height':float(sampler(p))})
 result={'status':'ready' if walls and skipped['steep']==0 and skipped['near_road']==0 else 'partial' if walls else 'invalid',
         'version':1,'kind':ring['kind'],'region_id':region.get('region_id',-1),'scale':scale,
         'perimeter_m':round(P,5),'polygon':poly,'segments':walls,'openings':raw,'towers':towers,
         'errors':[] if walls else ['no_valid_wall_segments'],'skipped':skipped,'selected_lot':ring['selected']['id'] if ring['selected'] else None}
 return result

def validate(region,result):
 errors=[];scale=region['scale']
 if result['status'] in ('skipped','invalid'):return errors
 poly=result['polygon'];P=perimeter(poly);center=tuple(sum(p[j] for p in poly)/len(poly) for j in (0,1))
 if abs(P-result['perimeter_m'])>1e-3:errors.append('perimeter')
 if scale=='city':
  # Octagon is convex: half-plane test allows building footprint margin verification.
  area=signed_area(poly);orientation=1 if area>0 else -1
  for lot in region['lots']:
   p=lot['p'];r=float(lot.get('halfsize',5.5))
   for i,a in enumerate(poly):
    b=poly[(i+1)%len(poly)];distance=orientation*cross(sub(b,a),sub(p,a))/length(sub(b,a))
    if distance <r+0.8:errors.append('building_footprint_outside');break
  # Every regional spoke that exits city enclosure must have a gate cut.
  for a,b,w,tag in route_segments(region):
   for i,c in enumerate(poly):
    d=poly[(i+1)%len(poly)];hit=intersection(a,b,c,d)
    if hit is None:continue
    _,t=hit;intersection_p=lerp(c,d,t)
    if any(dpointseg(intersection_p,seg['a'],seg['b'])<w*.5+1. for seg in result['segments']):errors.append('blocked_road')
  for r in result['segments']:
   for a,b,w,_ in route_segments(region):
    if dpointseg(lerp(r['a'],r['b'],.5),a,b)<w*.5+2.-1e-5:errors.append('road_clearance')
   for a,b in water_segments(region):
    if dpointseg(lerp(r['a'],r['b'],.5),a,b)<10.9:errors.append('water_clearance')
 for w in result['segments']:
  if length(sub(w['a'],w['b']))>2.81:errors.append('segment_too_long')
  if w['base']>min(w['heights'])-.6:errors.append('unsupported_base')
  if max(w['heights'])-min(w['heights'])>2.4001:errors.append('dangerous_slope')
  if not all(math.isfinite(x) for x in (*w['a'],*w['b'],w['base'],w['top'])):errors.append('nonfinite')
 if scale!='city' and not any(g['type']=='gate' for g in result['openings']):errors.append('courtyard_no_entrance')
 return errors

def digest(result):
 # Do not hash dictionary order or absolute numerical formatting.
 obj={'s':result['status'],'kind':result.get('kind'),
 'walls':[(tuple(round(t,4) for t in w['a']),tuple(round(t,4) for t in w['b']),round(w['base'],4),round(w['top'],4)) for w in result['segments']],
 'gates':[(round(x['s'],4),round(x['width'],4),x['type'],x['source']) for x in result['openings']],
 'towers':[(tuple(round(t,4) for t in v['p']),round(v['height'],4)) for v in result['towers']]}
 return hashlib.sha256(json.dumps(obj,sort_keys=True).encode()).hexdigest()
