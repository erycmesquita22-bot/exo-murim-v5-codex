"""Editable HWA02 local blueprint based on exported placements and POIs."""
import math,json
from pathlib import Path
import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.patches import Rectangle,Polygon,FancyArrowPatch
from matplotlib.colors import LinearSegmentedColormap
from matplotlib import patheffects
ROOT=Path(__file__).resolve().parents[1]
m=json.loads((ROOT/'data'/'HWA02_manifest.json').read_text())
fig,ax=plt.subplots(figsize=(13,11),facecolor='#F6F1E4')
ax.set_facecolor('#F0EAD9')
x=np.linspace(-118,118,155);zs=np.linspace(-112,112,145);XX,ZZ=np.meshgrid(x,zs)
r=lambda z:66+8*np.sin((z+20)/41)+z*.045
hh=.2+.17*np.sin(XX*.072+ZZ*.013)+.17*np.cos(ZZ*.093-XX*.024) + np.maximum(0,(-XX-57)/55)**1.8*11.5 +np.maximum(0,(-ZZ-65)/45)*np.maximum(0,(-XX-55)/65)*6 -2.25*np.maximum(0,1-np.abs(XX-r(ZZ))/12)**1.35
colors=['#C0CCAA','#96AC83','#698C6E','#50755E','#425F4F']
cm=LinearSegmentedColormap.from_list('Haneul',colors)
ax.contourf(XX,-ZZ,hh,levels=[-3,-.3,1,3,7,14,30],cmap=cm,alpha=.82)
ax.contour(XX,-ZZ,hh,levels=[0,2,4,7,11,17],colors='#324B3D',alpha=.25,linewidths=.7)
# main river / shallow-bank
zz=np.linspace(-111,111,210);rx=r(zz)
ax.fill_betweenx(-zz,rx-6.3,rx+6.3,color='#4B8A99',zorder=5,alpha=.93)
ax.plot(rx,-zz,color='#BFD5CC',lw=1,alpha=.8,zorder=5)
# footpaths
roads=[([(-14,-112),(-14,-94),(-12,-76),(-9,-54),(-8,-34),(-11,-11),(-11,6),(-14,27),(-13,46),(-9,70),(-10,98)],4.1),
 ([(-10,-19),(-22,-19),(-35,-21),(-48,-21)],3.6),
 ([(-11,4),(2,6),(18,10),(29,21),(39,38),(44,44)],3),
 ([(-14,39),(-29,48),(-48,62),(-65,83)],2.7),
 ([(-12,-53),(4,-53),(14,-41),(31,-33)],2.8)]
for line,width in roads:
 ax.plot([v[0] for v in line],[-v[1] for v in line],color='#897D59',lw=width+2,alpha=.8,zorder=9,solid_capstyle='round')
 ax.plot([v[0] for v in line],[-v[1] for v in line],color='#D2BD8D',lw=width,alpha=.95,zorder=10,solid_capstyle='round')
ax.add_patch(Rectangle((-11-12,-5-10),24,20,fill=True,color='#D1C2A6',zorder=9))
# mansion extents and courtyards
ax.add_patch(Rectangle((-48-22.5, 44-22),45,44,fill=True,facecolor='#C7B9A2',edgecolor='#694F40',hatch='...',linewidth=2.5,alpha=.82,zorder=11))
# rice plots
for ix in range(3):
 for iz in range(2):
  cx=-92+ix*17;cz=37+iz*22
  if cx<-80 and cz>65:continue
  ax.add_patch(Rectangle((cx-7,-cz-8.5),14,17,facecolor='#86AC7E',edgecolor='#4B7357',lw=1.2,hatch='///',zorder=12))
# buildings from real placement manifest; x,z -> x,-z
for q in m['placements']:
 xx,zz=q['position_xz'];w,depth=q['dimensions_wd']
 col='#273C43' if q['class']=='manor' else '#53646B'
 rec=Rectangle((xx-w/2,-zz-depth/2),w,depth,angle=0,facecolor=col,edgecolor='#FAF3E2',linewidth=1.0,zorder=20)
 ax.add_patch(rec)
 if q['class']=='manor':
  ax.plot([xx],[ -zz],'o',color='#D6B56A',ms=3,zorder=21)
# legends and labels
labelstyles=dict(fontsize=9,fontweight='bold',color='#223634',path_effects=[patheffects.withStroke(linewidth=3, foreground='#F5EFDF')])
labels=[('PORTÃO NORTE',(-14,102)),('SOLAR DA FAMÍLIA',(-48,23)),('PRAÇA',(-13,-4)),('CAIS / BALSA',(59,-43)),('ARROZAIS',(-79,-91)),('SANTUÁRIO',(-8,-89))]
for name,(xx,yy) in labels:
 ax.text(xx,yy,name,ha='center',va='center',zorder=35,**labelstyles)
ax.annotate('Rio Hwa',xy=(67,61),rotation=90,color='#EAF3E7',fontsize=11,fontweight='bold',ha='center',zorder=30)
ax.plot([-12],[-65],marker='*',markersize=16,color='#D2A84E',markeredgecolor='#1F3439',zorder=29)
ax.annotate('NASCIMENTO',xy=(-12,-65),xytext=(-54,-107),fontsize=10,color='#273934',fontweight='bold',arrowprops=dict(arrowstyle='->',color='#273934',lw=1.6),zorder=38)
# keys / reference
ax.set_xlim(-128,128);ax.set_ylim(-119,119);ax.set_aspect('equal')
ax.set_xlabel('Leste (+X), metros locais',fontsize=12,color='#30433A')
ax.set_ylabel('Norte (-Z), metros locais',fontsize=12,color='#30433A')
ax.grid(color='#4B6A58',alpha=.15,linestyle=':',zorder=0)
for spine in ax.spines.values():spine.set_color('#4F6155');spine.set_linewidth(1)
ax.tick_params(colors='#394A3C')
ax.annotate('N',xy=(110,112),xytext=(110,90),ha='center',fontsize=16,color='#294A3A',fontweight='bold',arrowprops=dict(arrowstyle='-|>',color='#294A3A',lw=2.5))
ax.plot([-109,-59],[-113,-113],color='#263E36',lw=3)
for xx in [-109,-59]:ax.plot([xx,xx],[-115,-111],color='#263E36',lw=2)
ax.text(-84,-108,'50 m',ha='center',fontweight='bold',color='#263E36')
fig.suptitle('EXO–MURIM  |  HWA-02 · VILA DO VAU DE HANEUL',fontsize=20,fontweight='bold',color='#263B36',y=.97)
fig.text(.13,.915,'PLANTA DE IMPLANTAÇÃO  V0.1   ·   236 × 224 m   ·   Norte para cima   ·   Terreno fixo, ocupação variável',fontsize=10,color='#5A6254')
fig.text(.13,.055,'FAIXAS: altitudes locais  |  Escuro: construções  |  Azul: rio  |  Verde hachurado: arrozais\nSIMULAÇÃO: somente símbolos da família, NPCs, regras e eventos variam por partida; vias, rio e casas são permanentes.',fontsize=9,color='#475348')
fig.subplots_adjust(left=.14,right=.92,top=.88,bottom=.13)
fig.savefig(ROOT/'previews'/'05_planta_tecnica_HWA02.png',dpi=155,facecolor=fig.get_facecolor())
fig.savefig(ROOT/'previews'/'05_planta_tecnica_HWA02.svg',facecolor=fig.get_facecolor())
print('technical map generated')
