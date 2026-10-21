from __future__ import annotations
from pathlib import Path
import json, math, random, collections
import numpy as np
from PIL import Image,ImageDraw,ImageFont,ImageFilter
import cv2, trimesh
from reportlab.pdfgen import canvas
from reportlab.lib.utils import ImageReader

R=Path(__file__).resolve().parents[1]
D=R/'00_CATALOGO';demo=R/'13_CENAS_DEMO'
M=json.loads((R/'07_DOCUMENTACAO/MANIFESTO_COLECAO_02.json').read_text())
F='/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf';B='/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf'
def ft(s,b=False):return ImageFont.truetype(B if b else F,s)
BG=(16,23,27);PANEL=(27,35,38);MUTED=(181,185,172);TEXT=(231,231,213);GOLD=(202,165,104);ACCENT=(78,111,104)

def txt(d,xy,s,size=19,color=TEXT,b=False):d.text(xy,str(s),font=ft(size,b),fill=color)
def round_rect(d,xy,fill=PANEL,r=18,stroke=(60,75,72),w=2):d.rounded_rectangle(xy,radius=r,fill=fill,outline=stroke,width=w)

def board(title,sub,w=2200,h=1500):
 img=Image.new('RGB',(w,h),BG);d=ImageDraw.Draw(img)
 d.rectangle((0,0,w,13),fill=GOLD)
 txt(d,(50,35),'EXO-MURIM',49,TEXT,True)
 txt(d,(52,100),title,36,GOLD,True)
 txt(d,(52,150),sub,19,MUTED)
 d.line((52,200,w-52,200),fill=(70,88,83),width=2)
 return img,d

def label(d,xy,name,size=17):
 if len(name)>29:name=name[:27]+'…'
 txt(d,xy,name.replace('_',' ').title(),size,TEXT)

def texpage(filelist,title,sub,cols=7,rows=5,side=180):
 imgs=[]
 for fn in filelist:
  try:imgs.append((fn,Image.open(R/fn).convert('RGB')))
  except Exception as e:print('missing',fn,e)
 w=2180;h=290+int(math.ceil(len(imgs)/cols))*235
 im,d=board(title,sub,w,h)
 x0=60;y0=228;gap=13;cell=(w-2*x0-(cols-1)*gap)//cols
 for i,(f,pic) in enumerate(imgs):
  c=i%cols;rr=i//cols;x=x0+c*(cell+gap);y=y0+rr*235
  round_rect(d,(x,y,x+cell,y+218),fill=(35,45,46),r=9,stroke=(57,69,69),w=1)
  q=pic.resize((cell-22,cell-22),Image.Resampling.NEAREST)
  im.paste(q,(x+11,y+11))
  label(d,(x+10,y+cell+14),Path(f).stem,size=14)
 return im

def meshrender(p,size=(270,223)):
 sc=trimesh.load(R/p,force='scene')
 meshes=sc.dump(concatenate=False)
 data=[m for m in meshes if hasattr(m,'faces') and len(m.faces)>0]
 allv=np.vstack([m.vertices for m in data]);lo=allv.min(axis=0);hi=allv.max(axis=0);center=(lo+hi)/2
 xaxis=np.array([.80,0,-.60]);yaxis=np.array([-.32,.90,-.37]);xaxis/=np.linalg.norm(xaxis);yaxis/=np.linalg.norm(yaxis);depth=np.cross(xaxis,yaxis)
 proj=np.column_stack(((allv-center)@xaxis,(allv-center)@yaxis))
 rng=proj.max(axis=0)-proj.min(axis=0);scale=min((size[0]-35)/max(rng[0],.01),(size[1]-35)/max(rng[1],.01))
 im=Image.new('RGB',size,(30,40,43));d=ImageDraw.Draw(im)
 polys=[]
 for m in data:
  co=np.asarray(m.visual.vertex_colors)
  if co.ndim!=2 or len(co)!=len(m.vertices):co=np.full((len(m.vertices),4),180,np.uint8)
  fcs=m.faces;vs=m.vertices
  for inds in fcs:
   tri=vs[inds];cen=tri.mean(axis=0)-center
   v=(tri-center)
   pts=[(size[0]/2+float(t@xaxis)*scale,size[1]*.54-float(t@yaxis)*scale) for t in v]
   normal=np.cross(tri[1]-tri[0],tri[2]-tri[0]);normal=normal/(np.linalg.norm(normal)+1e-7)
   bright=np.clip(.66+.32*max(0,float(normal@np.array([-.35,.85,.30]))),.47,1)
   col=np.asarray(co[inds,:3]).mean(axis=0)*bright
   polys.append((float(cen@depth),pts,tuple(np.clip(col,0,255).astype('uint8'))))
 for _,pts,col in sorted(polys,key=lambda a:a[0]):d.polygon(pts,fill=col)
 return im

# 71 individual images physically rendered from the new GLBs.
for i,spec in enumerate(M['new_glbs']):
 pic=meshrender(spec['file'],(320,255))
 pic.save(D/f"item_{spec['id']}.png")
 if i%15==0:print('thumb',i,flush=True)

CAT=[('09_TOPOGRAFIA_GLB','FORMAS DO TERRENO','Penhascos, margens de rio, passagens de caverna e patamares.'),
 ('10_ARQUITETURA_GLB','CONSTRUCAO MODULAR MURIM','Paredes, encaixes, portas, janelas, pilares e telhados.'),
 ('11_RUINAS_GLB','RUINAS E MASMORRAS','Paredes danificadas, corredores, arcos, pilares e escadas.'),
 ('12_NATUREZA_GLB','VEGETACAO E ROCHAS','Silhuetas modulares de arvores, bambus, rochedos e pinheiros.')]
for group,title,sub in CAT:
 items=[x for x in M['new_glbs'] if x['category']==group]
 cols=5;cellw=398;cellh=332
 w=2180;h=245+int(math.ceil(len(items)/cols))*cellh+75
 im,d=board(title,sub,w,h)
 for i,rec in enumerate(items):
  x=65+(i%cols)*413;y=226+(i//cols)*cellh
  round_rect(d,(x,y,x+cellw,y+cellh-12),(33,44,47),14,(64,77,77),2)
  pic=Image.open(D/f"item_{rec['id']}.png").convert('RGB')
  im.paste(pic,(x+39,y+14));label(d,(x+13,y+273),rec['id'],16)
  txt(d,(x+13,y+295),f"{rec['triangles']} tris   •   {rec['bounds_m'][0]:.1f} × {rec['bounds_m'][1]:.1f} × {rec['bounds_m'][2]:.1f} m",12,MUTED)
 im.save(D/f"PRANCHA_{group}.png")

texsets=[
 (['01_SOLOS/'+n+'.png' for n in [
 'grama_viva','grama_prado','grama_seca','solo_florestal','terra_castanha','terra_umida','trilha_batida','rocha_cinza','laje_rochosa','pedra_musgosa','areia_bege','cascalho',
 ]]+['01_SOLOS/'+n+'.png' for n in ['grama_montanha','terra_raizes','sedimento_rio','pedra_xisto','pedra_calcaria','terra_pedregosa','musgo_ruina','folhagem_prado','lama_margem','areia_pedregosa','grama_inverno','terra_cinza']],
 'TERRENO E SUPERFICIES','24 solos selecionados da Colecao 01 e os 12 novos, gerados sem dependencia de terceiros.'),
 (['02_PAREDES_RUINAS/'+n+'.png' for n in ['tijolo_pedra_cinza','tijolo_ruina_antiga','tijolo_ruina_rachado','tijolo_pedra_musgo','parede_cal_antiga','tabuas_carvalho','tijolo_templo_vermelho',
 'tijolo_ruina_silicificado','tijolo_ruina_queimado','bloco_arenito_vermelho','pedra_templo_lavrada','barro_palha','madeira_templo_escura','madeira_viga_cobre','pedra_calcaria_cortada','tijolo_limo','revestimento_oriental_ocre']],
 'PAREDES E TIJOLOS','Texturas de desgaste, ruinas, pedra lavrada, madeira e reboco.'),
 (['03_PISOS/'+n+'.png' for n in ['lajes_ruina_cinza','lajes_ruina_musgo','lajes_templo_claro','paralelepipedo','pavimento_antigo','madeira_deck','piso_tatame','piso_basaltico',
 'laje_rachada','piso_escada_desgastado','piso_madeira_mercado','piso_madeira_altar','piso_telhas_escuras','piso_telha_carmesim','laje_pedra_musgo','piso_ruina_areia']],
 'PISOS E REVESTIMENTOS','Lajes de templo, madeira, pavimentacao, escadas e desgaste.')]
for j,(files,t,s) in enumerate(texsets):texpage(files,t,s,cols=6).save(D/f'PRANCHA_TEXTURAS_{j+1}.png')

# Corner-coded transitions, true mask alpha blended with base. Produces contiguous geometric seams in the example.
def tilemap(top,bot,w=10,h=7):
 n=128;rr=random.Random(14)
 def path(tex):
  a=R/'01_SOLOS'/f'{tex}.png'
  return a if a.exists() else R/'03_PISOS'/f'{tex}.png'
 upper=np.array(Image.open(path(top)).convert('RGB'),np.float32)
 lower=np.array(Image.open(path(bot)).convert('RGB'),np.float32)
 flags=np.zeros((h+1,w+1),np.uint8)
 for y in range(h+1):
  for x in range(w+1):
   center=w*.48+math.sin(y*.7)*1.35
   flags[y,x]=1 if x<center else 0
 before=Image.new('RGB',(w*n,h*n));after=Image.new('RGB',(w*n,h*n));sets=[]
 for j in range(h):
  for i in range(w):
   mask=flags[j,i]+2*flags[j,i+1]+4*flags[j+1,i+1]+8*flags[j+1,i]
   alpha=np.array(Image.open(R/'04_TRANSICOES'/f'{bot}__para__{top}'/f'msc4_{mask:02}.png').convert('RGBA'))[:,:,3:].astype(np.float32)/255.
   result=(lower*(1-alpha)+upper*alpha).astype('uint8')
   after.paste(Image.fromarray(result,'RGB'),(i*n,j*n))
   before.paste(Image.fromarray((upper if mask>=8 else lower).astype('uint8'),'RGB'),(i*n,j*n))
 return before,after,flags

comparison=Image.new('RGB',(2300,1000),BG);dr=ImageDraw.Draw(comparison)
txt(dr,(52,26),'TRANSICOES CONECTADAS — ANTES E DEPOIS',38,GOLD,True)
txt(dr,(53,84),'Os mesmos 70 tiles. A mistura utiliza mascara de quatro cantos; nao redesenha o terreno.',20,MUTED)
a,b,flags=tilemap('grama_montanha','pedra_xisto',9,5)
a.thumbnail((1060,695));b.thumbnail((1060,695))
comparison.paste(a,(55,175));comparison.paste(b,(1190,175))
txt(dr,(55,905),'ANTES  •  BLOCOS INDEPENDENTES',26,TEXT,True)
txt(dr,(1190,905),'DEPOIS  •  MSC4 COM TRANSICAO',26,TEXT,True)
comparison.save(D/'PRANCHA_TRANSICOES_COMPARACAO.png')

# Real, textured world-unit planar demonstrations: glTF scene is made from the same files shown in the catalog.
PLANS={
 'vale_trilhas': {'top':'grama_viva','base':'terra_castanha','size':10,'objects':[
 ('06_OBJETOS_GLB/vegetacao/arvore_folhosa.glb',-11,6,0),('06_OBJETOS_GLB/vegetacao/arvore_grande.glb',-12,-7,0),
 ('12_NATUREZA_GLB/arvore_baixa_prado.glb',8,9,0),('06_OBJETOS_GLB/vegetacao/bambu_grupo.glb',11,-7,0),
 ('06_OBJETOS_GLB/rochas/rochas_medias.glb',-4,-11,0),('09_TOPOGRAFIA_GLB/rocha_pilha_baixa.glb',10,2,0),
 ('06_OBJETOS_GLB/objetos/cerca_segmento.glb',-7,1,0),('06_OBJETOS_GLB/objetos/poste_lanterna.glb',-2,3,0)]},
 'montanha_travessia': {'top':'grama_montanha','base':'pedra_xisto','size':10,'objects':[
 ('09_TOPOGRAFIA_GLB/penhasco_alto_reto.glb',-9,4,0),('09_TOPOGRAFIA_GLB/penhasco_baixo_reto.glb',-4,4,0),
 ('09_TOPOGRAFIA_GLB/penhasco_canto_interno.glb',2,4,0),('09_TOPOGRAFIA_GLB/entrada_caverna_rochosa.glb',10,5,0),
 ('09_TOPOGRAFIA_GLB/rampa_escadaria_pedra.glb',-1,-6,0),('09_TOPOGRAFIA_GLB/plataforma_rochosa.glb',-3,0,0),
 ('12_NATUREZA_GLB/pinheiro_escarpado.glb',-13,-10,0),('12_NATUREZA_GLB/rochedo_rio_musgoso.glb',10,-11,0)]},
 'patio_murim': {'top':'grama_prado','base':'trilha_batida','size':10,'objects':[
 ('06_OBJETOS_GLB/construcoes/casa_modular.glb',-10,7,0),('06_OBJETOS_GLB/construcoes/casa_modular.glb',8,7,0),
 ('10_ARQUITETURA_GLB/parede_reboco_claro.glb',-2,7,0),('10_ARQUITETURA_GLB/painel_janela_lattice.glb',2,7,0),
 ('10_ARQUITETURA_GLB/pilar_madeira_dourado.glb',-4,5,0),('10_ARQUITETURA_GLB/pilar_madeira_dourado.glb',4,5,0),
 ('10_ARQUITETURA_GLB/telhado_teal_4m.glb',0,7,2.1),('10_ARQUITETURA_GLB/escada_madeira_templo.glb',0,3,0),
 ('06_OBJETOS_GLB/objetos/barraca_feira.glb',-9,-5,0),('06_OBJETOS_GLB/objetos/poco.glb',9,-4,0),
 ('06_OBJETOS_GLB/vegetacao/cerejeira.glb',11,-11,0),('06_OBJETOS_GLB/objetos/poste_lanterna.glb',-1,-7,0)]},
 'ruinas_antigas': {'top':'musgo_ruina','base':'laje_rachada','size':10,'objects':[
 ('11_RUINAS_GLB/muro_ruina_cinza.glb',-8,8,0),('11_RUINAS_GLB/parede_ruina_destruido.glb',-3,8,0),
 ('11_RUINAS_GLB/arco_portal_antigo.glb',3,8,0),('11_RUINAS_GLB/muro_ruina_arenito.glb',9,8,0),
 ('11_RUINAS_GLB/coluna_ruina_inteiro.glb',-9,-3,0),('11_RUINAS_GLB/coluna_ruina_musgo.glb',8,-3,0),
 ('11_RUINAS_GLB/altar_ruina_antigo.glb',0,0,0),('11_RUINAS_GLB/escada_ruina_quebrada.glb',-6,-9,0),
 ('11_RUINAS_GLB/entulho_ruina_grande.glb',8,-9,0),('09_TOPOGRAFIA_GLB/rocha_pilha_baixa.glb',12,0,0)]}}

# Add missing legacy transition family if requested pair already in 01. Save a textured top mesh as GLB in each scene.
for name,plan in PLANS.items():
 sc=trimesh.Scene();sz=plan['size']*4
 w=plan['size'];h=w
 dr=R/'04_TRANSICOES'/f"{plan['base']}__para__{plan['top']}"
 if not dr.exists():
  # These are existing transitions in the reverse direction? fallback exact pure material is visible in README.
  keys=[(plan['top'],plan['base']),('grama_montanha','pedra_xisto')]
  for t,b in keys:
   if (R/'04_TRANSICOES'/f'{b}__para__{t}').exists():plan['top']=t;plan['base']=b;break
 _,ground,flags=tilemap(plan['top'],plan['base'],w,h)
 ground.save(demo/f'{name}_SOLO_PNG.png')
 half=sz/2
 # Ground plane positive Y normal, UV top mapping.
 vs=np.array([[-half,.018,-half],[half,.018,-half],[half,.018,half],[-half,.018,half]],dtype=float)
 fs=np.array([[0,2,1],[0,3,2]],dtype=int)
 mesh=trimesh.Trimesh(vertices=vs,faces=fs,process=False)
 mesh.visual=trimesh.visual.texture.TextureVisuals(uv=np.array([[0,0],[1,0],[1,1],[0,1]]), image=ground)
 sc.add_geometry(mesh,node_name='terrain_texture')
 base=trimesh.creation.box(extents=(sz,.35,sz));base.apply_translation((0,-.20,0));base.visual.vertex_colors=np.tile([61,70,64,255],(len(base.vertices),1));sc.add_geometry(base,node_name='terrain_base')
 instances=[]
 for i,(path,x,z,y) in enumerate(plan['objects']):
  obj=trimesh.load(R/path,force='scene')
  mat=trimesh.transformations.translation_matrix((x,y,z))
  for j,m in enumerate(obj.dump(concatenate=False)):
   sc.add_geometry(m.copy(),node_name=f'part_{i}_{j}',transform=mat)
  instances.append({'glb':path,'x':x,'y':y,'z':z})
 outfile=demo/f'{name}.glb';outfile.write_bytes(sc.export(file_type='glb'))
 (demo/f'{name}.json').write_text(json.dumps({'scene':name,'ground':f'{name}_SOLO_PNG.png','instances':instances},ensure_ascii=False,indent=2))
 # render actual assembled meshes + ground tile with textured top face
 W,H=1600,1000;img=Image.new('RGB',(W,H),(23,32,36));d=ImageDraw.Draw(img)
 cx=W/2;cy=H*.50;scale=17.0;xaxis=np.array([.76,0,-.65]);yaxis=np.array([-.37,.86,-.42]);depth=np.cross(xaxis,yaxis)
 xaxis/=np.linalg.norm(xaxis);yaxis/=np.linalg.norm(yaxis);depth/=np.linalg.norm(depth)
 def project(pt):
  pt=np.asarray(pt,float)
  return np.array([cx+float(pt@xaxis)*scale,cy-float(pt@yaxis)*scale])
 # perspective warp textured 2d terrain (rectangle projected into quad), scaled camera plane.
 # geo texture top left =(-half,-half); image aligns to above 3d face
 tcoords=np.array([project([-half,.02,-half]),project([half,.02,-half]),project([half,.02,half]),project([-half,.02,half])],np.float32)
 src=np.array([[0,0],[ground.width-1,0],[ground.width-1,ground.height-1],[0,ground.height-1]],np.float32)
 trans=cv2.getPerspectiveTransform(src,tcoords)
 cvimg=cv2.warpPerspective(np.array(ground),trans,(W,H),flags=cv2.INTER_NEAREST,borderMode=cv2.BORDER_CONSTANT)
 mask=cv2.warpPerspective(np.ones((ground.height,ground.width),np.uint8)*255,trans,(W,H))
 img.paste(Image.fromarray(cvimg,'RGB'),(0,0),Image.fromarray(mask,'L'))
 # model meshes including textures? render only colored GLB instances, with global painter order.
 polys=[]
 for i,(path,x,z,y) in enumerate(plan['objects']):
  obj=trimesh.load(R/path,force='scene')
  for m in obj.dump(concatenate=False):
   fc=m.faces;V=np.asarray(m.vertices)+np.array([x,y,z]);col=np.asarray(m.visual.vertex_colors)
   if len(col)!=len(V):col=np.full((len(V),4),200,np.uint8)
   for idx in fc:
    tri=V[idx];nn=np.cross(tri[1]-tri[0],tri[2]-tri[0]);nn=nn/(np.linalg.norm(nn)+1e-7)
    bright=float(np.clip(.67+.28*max(0,nn@np.array([-.45,.82,.28])),.54,1))
    cc=np.clip(col[idx,:3].mean(axis=0)*bright,0,255).astype('uint8')
    coords=list(map(lambda vv:tuple(project(vv)),tri))
    polys.append((float(tri.mean(axis=0)@depth),coords,tuple(cc)))
 for _,points,color in sorted(polys,key=lambda a:a[0]):d.polygon(points,fill=color)
 txt(d,(65,38),'EXO-MURIM  •  CENA DE MONTAGEM',28,GOLD,True)
 txt(d,(65,80),name.replace('_',' ').title(),35,TEXT,True)
 txt(d,(65,H-52),f'{len(instances)} modelos instanciados  |  Terreno MSC4 texturizado  |  Exportado em GLB',18,MUTED)
 img.save(D/f'DIORAMA_{name.upper()}.png')
 print('diorama',name,len(polys),flush=True)

# Put four real scene renders on a single board.
intro,d=board('QUATRO CENARIOS MONTADOS','Pre-visualizacoes reais de arquivos GLB + texturas MSC4, ainda sem teste de gameplay.',2400,1580)
for i,key in enumerate(PLANS):
 x=65+(i%2)*1175;y=235+(i//2)*646
 prev=Image.open(D/f'DIORAMA_{key.upper()}.png').convert('RGB');prev.thumbnail((1100,580))
 intro.paste(prev,(x,y))
 txt(d,(x+13,y+574),key.replace('_',' ').upper(),20,GOLD,True)
intro.save(D/'PRANCHA_CENARIOS_MONTADOS.png')

# Index contact board for approval (all meaningful previews), with caption
idx,d=board('COLECAO 02 — FUNDACAO DO MUNDO REGIONAL',
 '495 recursos: texturas, mascaras MSC4, decalques e modelos 3D • NOVOS: 71 GLB + 30 texturas + 128 transicoes + 8 decalques',2400,1580)
assets=[('TEXTURAS','PRANCHA_TEXTURAS_1.png'),('MODULOS MURIM','PRANCHA_10_ARQUITETURA_GLB.png'),('TOPOGRAFIA','PRANCHA_09_TOPOGRAFIA_GLB.png'),('RUINAS','PRANCHA_11_RUINAS_GLB.png'),('TRANSICOES','PRANCHA_TRANSICOES_COMPARACAO.png'),('EXEMPLOS','PRANCHA_CENARIOS_MONTADOS.png')]
for i,(label,imname) in enumerate(assets):
 x=70+(i%3)*770;y=235+(i//3)*625
 pic=Image.open(D/imname).convert('RGB');pic.thumbnail((720,555))
 idx.paste(pic,(x,y));txt(d,(x,y+562),label,21,GOLD,True)
idx.save(D/'PREVIA_GERAL.png')

# PDF assembled from actual raster catalog sheets.
pages=['PREVIA_GERAL.png','PRANCHA_TEXTURAS_1.png','PRANCHA_TEXTURAS_2.png','PRANCHA_TEXTURAS_3.png',
 'PRANCHA_TRANSICOES_COMPARACAO.png','PRANCHA_09_TOPOGRAFIA_GLB.png','PRANCHA_10_ARQUITETURA_GLB.png',
 'PRANCHA_11_RUINAS_GLB.png','PRANCHA_12_NATUREZA_GLB.png','PRANCHA_CENARIOS_MONTADOS.png']
for x in PLANS:pages.append(f'DIORAMA_{x.upper()}.png')
PDF=D/'CATALOGO_VISUAL_COLECAO_02.pdf';c=canvas.Canvas(str(PDF),pagesize=(1100,730))
for ix,page in enumerate(pages):
 with Image.open(D/page) as pic:
  w,h=pic.size;sc=min(1080/w,702/h);nw=w*sc;nh=h*sc
  c.drawImage(ImageReader(pic), (1100-nw)/2,(730-nh)/2,nw,nh)
 c.setFillColorRGB(.78,.73,.63);c.setFont('Helvetica',9);c.drawRightString(1080,14,f'EXO-MURIM | COLECAO 02 | {ix+1}/{len(pages)}')
 c.showPage()
c.save()
print('PDF',PDF,len(pages),'pages',flush=True)
