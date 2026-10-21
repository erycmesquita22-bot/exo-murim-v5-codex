#!/usr/bin/env python3
"""Modelo geométrico independente, não executa GDScript/Física. FAIL explícito."""
from __future__ import annotations
import collections, hashlib, json, math, random, sys
from pathlib import Path

FAMILIES=('ruins','cavern','temple','sect_hideout','mine','tomb')
WIDTHS=(12,14,16,18,20,22,28)
def seedint(token): return int(hashlib.sha256(token.encode()).hexdigest()[:7],16)
def mask(width,family,room_id):
    n=int(width/2); r=width*.5; occupied=set(); token=family+'|'+room_id
    for iz in range(n):
        for ix in range(n):
            x=(ix+.5)*2-r; z=(iz+.5)*2-r; ax=abs(x); az=abs(z); center=ax<=2 or az<=2
            if family=='temple': keep=(ax<=r*.46 and az<=r*.85) or (az<=r*.40 and ax<=r*.90)
            elif family=='cavern':
                jitter=((seedint(token+f'|{ix//2}|{iz//2}')%31)-15)/100
                keep=x*x/(r*r)+z*z/(r*r)<=.82+jitter
            elif family=='tomb': keep=(ax<=r*.42 and az<=r*.9) or (az>=r*.32 and az<=r*.78 and ax<=r*.82)
            elif family=='sect_hideout': keep=(az<=r*.43 and ax<=r*.92) or (ax<=r*.44 and az<=r*.92) or (x<=-r*.30 and z<=-r*.30)
            elif family=='mine':
                branch=seedint(token+'|shaft')%2
                keep=ax<=r*.37 or az<=r*.32 or (x>0 and z>0 and branch==0 and az<=r*.70) or (x<0 and z<0 and branch==1 and ax<=r*.70)
            else: keep=(ax<=r*.76 and az<=r*.76) and not (x>r*.2 and z>r*.2 and seedint(token+'|missing')%3!=0)
            if keep or center:occupied.add((ix,iz))
    return occupied

def connected(cells):
    queue=collections.deque([next(iter(cells))]); found=set(queue)
    while queue:
        x,z=queue.popleft()
        for d in ((1,0),(-1,0),(0,1),(0,-1)):
            p=(x+d[0],z+d[1]);
            if p in cells and p not in found:found.add(p);queue.append(p)
    return found==cells

def corridor(id,family,locked):
    v=seedint(family+'|'+id)
    return (4 if v%5>0 else 6,0 if locked or v%4==0 else (2 if v%2==0 else -2),v%3==0)

def run():
    issues=[]; shapes=collections.defaultdict(set); sample=0; door_coverage=0
    for family in FAMILIES:
        for seed in range(1000):
            w=WIDTHS[seed%len(WIDTHS)];rid=f'QA-{seed}';m=mask(w,family,rid);sample+=1
            if not connected(m): issues.append((family,seed,'mask_disconnected'))
            n=w//2
            for edge in ('north','south','east','west'):
                exit_tiles={(x,z) for x,z in m if ((edge=='north' and z==0) or (edge=='south' and z==n-1) or (edge=='west' and x==0) or (edge=='east' and x==n-1)) and (abs(((x if edge in ('north','south') else z)+.5)-n*.5)<=1.01)}
                door_coverage+=1
                if len(exit_tiles)<2:issues.append((family,seed,'blocked_mouth',edge))
            shapes[family].add(tuple(sorted(m)))
            if mask(w,family,rid)!=m:issues.append((family,seed,'nondeterminism'))
    for i in range(20000):
        family=FAMILIES[i%6];a=corridor(f'R{i}~R{i+1}',family,i%7==0);b=corridor(f'R{i}~R{i+1}',family,i%7==0)
        if a!=b or (i%7==0 and a[1]!=0) or a[0] not in (4,6) or abs(a[1])>2:issues.append(('corridor',i,a))
    if min(map(len,shapes.values()))<5:issues.append(('low_structural_diversity',{k:len(v) for k,v in shapes.items()}))
    # Shapes must not degenerate to identical rectangles for their full sample.
    for family in FAMILIES:
        if all(len(cells)==(WIDTHS[i%7]//2)**2 for i,cells in enumerate([mask(WIDTHS[i%7],family,f'QA-{i}') for i in range(30)])):
            issues.append(('rectangular_family',family))
    report={'suite':'geometry_independent_reference_only','engine':'Python reference (NOT GDScript)','tested_masks':sample,'door_mouths_tested':door_coverage,'corridor_descriptors_tested':20000,'signatures_per_family':{k:len(v) for k,v in shapes.items()},'issues':issues[:20],'issue_count':len(issues),'native_godot':'NOT_RUN','status':'PASS' if not issues else 'FAIL'}
    dest=Path(__file__).resolve().parents[2]/'evidence'/'QA-R2-GEOMETRIA-REFERENCIA.json';dest.parent.mkdir(parents=True,exist_ok=True);dest.write_text(json.dumps(report,indent=2,ensure_ascii=False)+'\n')
    print(json.dumps({k:v for k,v in report.items() if k not in ('issues',)},ensure_ascii=False));return int(bool(issues))
if __name__=='__main__':sys.exit(run())
