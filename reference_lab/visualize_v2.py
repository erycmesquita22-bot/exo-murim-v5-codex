#!/usr/bin/env python3
"""Visual comparison of the actual atlas JSON from EXO World Genesis v2."""
from pathlib import Path
import json, sys
import numpy as np
from scipy.spatial import cKDTree
import matplotlib.pyplot as plt
from matplotlib.lines import Line2D
from matplotlib.colors import to_rgb
from matplotlib.patches import FancyBboxPatch
from world_genesis_v2 import plan,validate,terrain_and_climate

HERE=Path(__file__).resolve().parent
SEED=int(sys.argv[1]) if len(sys.argv)>1 else 816204
w=plan(SEED);v=validate(w)
(HERE/f'atlas_seed_{SEED}.json').write_text(json.dumps(w,indent=2,ensure_ascii=False))
R=w['regions'];pts=np.array([x['center'] for x in R],float)
color={'grassland':'#9DAA65','temperate_forest':'#487B58','bamboo_forest':'#60A37F','dry_valley':'#B59A70','wetland':'#558F91','rocky_highlands':'#87949B','alpine':'#CBD5CF','mixed_woodland':'#7F995C'}
X,Y=np.meshgrid(np.linspace(.0,1.0,590),np.linspace(.0,1.0,590));flat=np.column_stack([X.ravel(),Y.ravel()]);near=cKDTree(pts).query(flat)[1].reshape(X.shape)
rgba=np.array([to_rgb(color[r['biome']]) for r in R]);rgb=rgba[near]
h,wet,temp=terrain_and_climate(flat,SEED)
h=h.reshape(X.shape)
# Diffuse relief shading; does not claim to be actual 3D region elevation.
gy,gx=np.gradient(h); shade=np.clip(.80+1.5*(-gx+gy)+.23*(h-.45),.53,1.18)
image=np.clip(rgb*shade[:,:,None],0,1)
fig=plt.figure(figsize=(15,11),dpi=170,facecolor='#111B1E')
ax=fig.add_axes([.04,.11,.71,.78],facecolor='#16282A')
ax.imshow(image,extent=(0,1,0,1),origin='lower',interpolation='bilinear')
# Hydro on logical Delaunay neighbors may differ from footpath edges.
for riv in w['rivers_macro']:
 a,b=riv['from'],riv['to']
 ax.plot([pts[a,0],pts[b,0]],[pts[a,1],pts[b,1]],lw=min(4,1.1+.4*riv['flow']),color='#60BBC9',alpha=.66,zorder=4)
for p in w['portals']:
 a,b=p['a'],p['b']
 ax.plot([pts[a,0],pts[b,0]],[pts[a,1],pts[b,1]],lw=1.2,color='#E4D9BA',alpha=.72,zorder=5)
marker={'settlement':'s','ruins':'D','dungeon_approach':'^','wild':'o'}
cc={'settlement':'#FFC475','ruins':'#D6D1C6','dungeon_approach':'#EF7463','wild':'#223B37'}
for cat in ('wild','ruins','dungeon_approach','settlement'):
 ids=[r['id'] for r in R if r['kind']==cat]
 ax.scatter(pts[ids,0],pts[ids,1],s=40 if cat=='wild' else 95,
            marker=marker[cat],color=cc[cat],edgecolor='#111B1E',lw=1.2,zorder=8)
for r in R:
 if r['kind']=='wild':continue
 i=r['id'];ax.annotate(str(i).zfill(2),(pts[i,0],pts[i,1]),size=6.5,
                       color='#F5F4E5',weight='bold',ha='center',va='bottom',xytext=(0,7),textcoords='offset points',zorder=9)
start=w['start_region'];ax.scatter([pts[start,0]],[pts[start,1]],s=440,facecolors='none',edgecolors='#66F6E1',lw=2.5,zorder=10)
ax.set_xlim(0,1);ax.set_ylim(0,1);ax.axis('off')
for spine in ax.spines.values():spine.set_visible(False)
fig.text(.045,.953,'EXO — WORLD GENESIS',color='#F2E5CE',weight='bold',fontsize=22)
fig.text(.045,.916,f'DEPOIS  /  SEED {SEED}  ·  {N if False else len(R)} REGIÕES  ·  {len(w["portals"])} PASSAGENS',color='#C9DDD0',fontsize=12)
fig.text(.76,.85,'GEOGRAFIA',color='#F1D7AA',fontsize=13,weight='bold')
fig.text(.76,.818,'Relevo coerente e clima',color='#E6EAE0',fontsize=9)
fig.text(.76,.798,'ligado à altitude.',color='#E6EAE0',fontsize=9)
fig.text(.76,.745,'CATEGORIAS',color='#F1D7AA',fontsize=13,weight='bold')
for k,(cat,label) in enumerate((('settlement','23 assentamentos'),('ruins','12 ruínas'),('dungeon_approach','10 entradas de masmorra'),('wild','43 regiões naturais'))):
 yy=.71-k*.041
 fig.text(.765,yy,'●',color=cc[cat],fontsize=15)
 fig.text(.786,yy+.004,label,color='#DAE7DB',fontsize=10)
fig.text(.76,.50,'VIAS E ÁGUAS',color='#F1D7AA',fontsize=13,weight='bold')
fig.text(.765,.465,'━  Caminhos regionais',color='#D9DBBB',fontsize=10)
fig.text(.765,.43,'━  Rios macro (proxy)',color='#72CFE3',fontsize=10)
fig.text(.765,.385,'PROPRIEDADES',color='#F1D7AA',fontsize=13,weight='bold')
for i,ss in enumerate((f'{v["cycles"]} rotas cíclicas',f'{len(w["rivers_macro"])} trechos de rio',f'{len(v["biomes"])} biomas observados',f'Maior bioma: {v["max_biome_count"]}/88',f'Serviço a ≤ {v["nearservices_hops_max"]} mapas')):
 fig.text(.765,.35-i*.033,ss,color='#D8E5DC',fontsize=9)
fig.text(.046,.054,'VISUALIZAÇÃO DO ATLAS LÓGICO REAL  ·  NÃO É RENDERIZAÇÃO DO TERRENO JOGÁVEL',color='#C3CFC7',fontsize=10)
result=HERE/f'DEPOIS_atlas_seed_{SEED}.png';fig.savefig(result,dpi=170,facecolor=fig.get_facecolor());plt.close(fig)
print(result)
