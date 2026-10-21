from __future__ import annotations
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageFilter
import numpy as np, random, math, hashlib, json, zipfile, textwrap, shutil, itertools
import trimesh

ROOT = Path(__file__).resolve().parent.parent
for name in ['00_CATALOGO','01_SOLOS','02_PAREDES_RUINAS','03_PISOS','04_TRANSICOES','05_DECALQUES','06_OBJETOS_GLB','07_DOCUMENTACAO','08_FONTES']:
 (ROOT/name).mkdir(parents=True,exist_ok=True)
N=128
FONT='/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf'
FB='/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf'
def font(s=15,b=False):return ImageFont.truetype(FB if b else FONT,s)
def C(h):return tuple(int(h[i:i+2],16) for i in (1,3,5))
def mix(a,b,t):return tuple(int(min(255,max(0,a[k]*(1-t)+b[k]*t))) for k in range(3))
def stable(s):return int.from_bytes(hashlib.sha256(s.encode()).digest()[:4],'little')
def nwrap(s,scale,seed):
 r=np.random.default_rng(seed).random((scale,scale)).astype('float32')
 t=np.arange(s,dtype='float32')*scale/s; inds=t.astype(int);a=t-inds;f=a*a*(3-2*a)
 y0=inds[:,None]%scale;y1=(inds[:,None]+1)%scale;x0=inds[None,:]%scale;x1=(inds[None,:]+1)%scale
 return r[y0,x0]*(1-f[:,None])*(1-f[None,:])+r[y0,x1]*(1-f[:,None])*f[None,:]+r[y1,x0]*f[:,None]*(1-f[None,:])+r[y1,x1]*f[:,None]*f[None,:]
def tiled_rect(draw,x,y,x2,y2,fill):
 for dx in [-N,0,N]:
  for dy in [-N,0,N]:draw.rectangle((x+dx,y+dy,x2+dx,y2+dy),fill=fill)
def tiled_line(draw,p,fill,width=1):
 for dx in [-N,0,N]:
  for dy in [-N,0,N]:draw.line([(x+dx,y+dy) for x,y in p],fill=fill,width=width)
def tile_noise(name,palette):
 cols=np.array([C(v) for v in palette],dtype='float32')
 ns=(nwrap(N,4,stable(name)+1)*.51+nwrap(N,16,stable(name)+2)*.34+nwrap(N,64,stable(name)+3)*.15)
 idx=np.clip((ns*(len(cols)-.15)).astype('int32'),0,len(cols)-1)
 return Image.fromarray(cols[idx].astype('uint8'),'RGB')
def details(img,name,kind,palette):
 d=ImageDraw.Draw(img);rng=random.Random(stable(name+'details'));P=list(map(C,palette))
 if kind in ['grass','marsh','moss']:
  count=360 if kind=='grass' else 220
  for k in range(count):
   x=rng.randrange(N);y=rng.randrange(N);length=rng.randint(2,7)
   tiled_line(d,[(x,y),(x+rng.choice([-2,-1,0,1]),y-length)],P[rng.choice([0,1,3,4])],1)
   if k%10==0 and kind!='marsh':tiled_rect(d,x+1,y-4,x+2,y-3,P[-1])
 elif kind in ['earth','sand','clay','mud']:
  for k in range(250):
   x=rng.randrange(N);y=rng.randrange(N);w=rng.randint(1,4);hh=rng.randint(1,3)
   tiled_rect(d,x,y,x+w,y+hh,P[rng.choice([0,1,2,3,4])])
  for k in range(18):
   x=rng.randrange(N);y=rng.randrange(N)
   tiled_line(d,[(x,y),(x+rng.randint(4,10),y+rng.randint(-2,2))],P[0],1)
 elif kind in ['stone','gravel','slate']:
  for k in range(100 if kind!='gravel' else 300):
   x=rng.randrange(N);y=rng.randrange(N)
   if kind=='gravel':
    r=rng.randint(1,3);tiled_rect(d,x-r,y-r,x+r,y+r,P[rng.randrange(len(P))])
   else:
    tiled_line(d,[(x,y),(x+rng.randint(2,10),y+rng.randint(-3,3)),(x+rng.randint(8,14),y+rng.randint(0,7))],P[0],1)
 elif kind=='forest':
  for k in range(260):
   x=rng.randrange(N);y=rng.randrange(N)
   tiled_line(d,[(x,y),(x+rng.randint(-6,6),y+rng.randint(2,8))],P[rng.choice([0,1,2,4])],rng.choice([1,2]))
 return img

SOILS = [
 ('grama_viva','grass',['#244632','#335e3e','#43734b','#528452','#659761','#93a76d']),
 ('grama_prado','grass',['#385339','#4d7544','#649052','#729f63','#8baf72','#abc58b']),
 ('grama_seca','grass',['#555c36','#747344','#8b8550','#a69a5f','#bbad74','#d2c08c']),
 ('grama_outono','grass',['#4b4433','#6b6140','#907947','#a99155','#c6a368','#d5b87b']),
 ('grama_sombra','grass',['#1f3a32','#2d4d39','#385d42','#477050','#597963','#81967d']),
 ('relva_bambu','grass',['#314b30','#435e34','#536f38','#718744','#90a15c','#afae74']),
 ('solo_florestal','forest',['#2b332a','#384233','#4e5240','#64634b','#80765a','#998669']),
 ('solo_floresta_umida','forest',['#202e2d','#2c3b32','#3b4939','#536047','#6e7159','#94957a']),
 ('terra_castanha','earth',['#49362e','#614734','#79553c','#946c4a','#ad815b','#c09a75']),
 ('terra_clara','earth',['#624733','#7c5d42','#987249','#ae885c','#c49d72','#dac29b']),
 ('terra_vermelha','clay',['#542f2b','#793f32','#99533c','#ba6846','#cd8454','#dba16a']),
 ('terra_umida','mud',['#2c2926','#42362d','#584735','#6d5640','#826c50','#9b8161']),
 ('argila','clay',['#65433d','#7e554a','#966b5b','#ad7c68','#bc9479','#d3af91']),
 ('trilha_batida','earth',['#504134','#6b543f','#82684e','#9b7e5c','#b2976f','#c4aa84']),
 ('areia_bege','sand',['#7b7358','#a0956c','#b5a77b','#c9b98a','#dbca99','#ece0b6']),
 ('areia_rio','sand',['#6f6452','#847961','#aa9675','#c5ae8b','#dbcaab','#e9dabc']),
 ('seixos','gravel',['#4d5551','#626e64','#79827a','#919689','#b0ae94','#cec2a8']),
 ('cascalho','gravel',['#474b49','#60625e','#757871','#929183','#b2a991','#c8bc9e']),
 ('rocha_cinza','stone',['#3e474c','#546166','#687476','#818e8a','#a2a79b','#b9b9aa']),
 ('rocha_azulada','stone',['#323f4e','#435465','#556779','#718499','#919cac','#b1b7bb']),
 ('laje_rochosa','slate',['#3a4044','#4b5355','#626b6d','#7d8587','#999e9e','#babbbb']),
 ('pedra_musgosa','moss',['#35433a','#485848','#607460','#788c74','#99a08b','#b3b49d']),
 ('lama_pantanosa','mud',['#252c26','#363f2e','#48523a','#596447','#757451','#8d8769']),
 ('cinzas_vulcanicas','slate',['#22272c','#32363a','#45484c','#575d5f','#757778','#989595']),
]
WALLS=[
 ('tijolo_pedra_cinza','brick',['#343b41','#526066','#64747a','#839293','#a3aaa0']),
 ('tijolo_pedra_clara','brick',['#66665e','#85867c','#a2a297','#c1bba6','#ded5b9']),
 ('tijolo_pedra_escura','brick',['#272c36','#39434a','#4f5a64','#667179','#83898d']),
 ('tijolo_pedra_musgo','mossbrick',['#334239','#48594a','#67755c','#87917c','#b0ab94']),
 ('tijolo_ruina_rachado','ruinbrick',['#393f42','#5b6262','#78817e','#a2a399','#beb7a5']),
 ('tijolo_ruina_antiga','ruinbrick',['#49433b','#676054','#857b66','#a79b80','#c6b399']),
 ('tijolo_ruina_arenito','ruinbrick',['#79644b','#9b7e5b','#b39469','#d0b083','#e2c99c']),
 ('tijolo_arenito','brick',['#7a5e45','#a47a56','#c09767','#d7b68b','#e2cfaa']),
 ('tijolo_vermelho','brick',['#4e2c29','#853f38','#aa5143','#c16a52','#e09a6d']),
 ('tijolo_templo_vermelho','brick',['#3d272c','#702f36','#95404a','#b35d55','#cf8370']),
 ('tijolo_basaltico','brick',['#1e2429','#30383e','#454e52','#626969','#878787']),
 ('tijolo_pedra_pintada','brick',['#34434b','#486072','#648095','#90a9a7','#b4b6a2']),
 ('muro_pedra_bruta','rough',['#383e3a','#555c54','#6f796c','#919587','#b0ae9b']),
 ('muro_rocha_cortada','rough',['#47433e','#655f55','#847968','#ab9880','#c1ad92']),
 ('parede_bambu_trancado','bamboo',['#453e29','#756a39','#a69b59','#b9b06c','#d9c784']),
 ('tabuas_carvalho','wood',['#312824','#493429','#634735','#866444','#a88961']),
 ('tabuas_escurecidas','wood',['#201f22','#352b2b','#53403a','#73584d','#978074']),
 ('parede_barro','plaster',['#56473a','#826a54','#a48b70','#c4aa87','#dcc7aa']),
 ('parede_cal_antiga','plaster',['#66625a','#989285','#b4ad99','#d0c7b1','#e9e2d0']),
 ('parede_cal_desgastada','plaster',['#585d58','#8b9183','#adb4a4','#c6c8b9','#e0ded0']),
 ('revestimento_templo_azul','plaster',['#2d464f','#3c616c','#57808b','#7ba0a1','#adc5b7']),
 ('revestimento_templo_ocre','plaster',['#5c4635','#8a6947','#b48b58','#d3af79','#e4cba0']),
]
FLOORS=[
 ('lajes_ruina_cinza','slab',['#414849','#66716e','#86918b','#a5aca1','#c7c3af']),
 ('lajes_ruina_musgo','slab',['#3d4c42','#65725a','#7e9074','#a7ae94','#c2bc9f']),
 ('lajes_templo_claro','slab',['#756d61','#a79c84','#cec0a4','#ded1b3','#eee1ca']),
 ('paralelepipedo','cobble',['#3e4947','#62716b','#818f83','#a9afa0','#c9c4b0']),
 ('pavimento_antigo','cobble',['#595449','#776d59','#9e8c6e','#bba983','#d0c1a0']),
 ('caminho_ladrilho_azul','slab',['#334851','#456774','#65858c','#85a3a5','#bbc9be']),
 ('piso_madeira_clara','floorwood',['#55412d','#89633c','#a77b4d','#cca273','#e1c28f']),
 ('piso_madeira_escura','floorwood',['#241d20','#3a2d2c','#634838','#86654c','#b18b60']),
 ('piso_tatame','tatami',['#544f31','#827851','#a9a16c','#d0bd83','#e7d69f']),
 ('piso_ceramica_vermelha','slab',['#523637','#854740','#b05c4a','#ca7b5a','#dfaa76']),
 ('piso_basaltico','slab',['#25282e','#343f43','#4b5556','#697576','#90928b']),
 ('seixos_rio','cobble',['#48504e','#66746e','#8b9489','#a9aea1','#d2c7b1']),
 ('piso_mosaico','mosaic',['#3b4545','#647873','#ac9f7b','#b28e65','#d6c39d']),
 ('madeira_deck','floorwood',['#37312b','#554333','#7e6046','#a57c58','#c49d70']),
]

def masonry(name,kind,palette):
 dark,base,light,top,hi=[C(z) for z in palette]
 if kind=='plaster':
  img=tile_noise(name,palette)
  d=ImageDraw.Draw(img);rr=random.Random(stable(name))
  for k in range(85):
   x=rr.randrange(N);y=rr.randrange(N);w=rr.randrange(2,12)
   tiled_line(d,[(x,y),(x+w,y+rr.randrange(-4,5))],dark if k%5==0 else base,1)
  return img
 if kind=='mosaic':
  img=Image.new('RGB',(N,N),dark);d=ImageDraw.Draw(img)
  for y in range(0,N,16):
   for x in range(0,N,16):
    color=[base,light,top,hi][((x//16+y//16*3)%4)]
    d.rectangle((x+2,y+2,x+14,y+14),fill=color)
    d.line([(x+2,y+2),(x+14,y+2)],fill=hi)
    d.line([(x+14,y+2),(x+14,y+14)],fill=base)
  return img
 if kind in ('wood','floorwood','bamboo','tatami'):
  img=Image.new('RGB',(N,N),dark);d=ImageDraw.Draw(img)
  width=16 if kind in ('wood','bamboo') else 22 if kind=='floorwood' else 32
  bands=N//width if N%width==0 else 8;pitch=N//bands
  rr=random.Random(stable(name))
  for j in range(bands):
   x=j*pitch;c=[base,light,top,base,light][j%5]
   d.rectangle((x+2,0,x+pitch-2,127),fill=c)
   d.line([(x+2,0),(x+2,127)],fill=hi,width=2)
   d.line([(x+pitch-3,0),(x+pitch-3,127)],fill=dark,width=2)
   for k in range(8):
    y=rr.randrange(N);sx=x+rr.randrange(5,max(6,pitch-4));leng=rr.randrange(8,30)
    tiled_line(d,[(sx,y),(sx,y+leng)],light if k%3 else base)
  if kind in ('floorwood','tatami'):
   for y in range(0,N,64):d.line([(0,y),(N,y)],fill=dark,width=2)
  if kind=='tatami':
   for x in range(0,N,8):d.line([(x,0),(x,N)],fill=hi,width=1)
  return img
 if kind=='rough':
  img=tile_noise(name,palette); d=ImageDraw.Draw(img);r=random.Random(stable(name))
  for iy in range(8):
   y=iy*16;off=(iy%2)*16
   tiled_line(d,[(0,y),(128,y)],dark,2)
   for ix in range(-1,6):
    x=off+ix*32
    tiled_line(d,[(x,y),(x+r.randrange(-2,4),y+16)],dark,2)
  return img
 if kind=='cobble':
  img=Image.new('RGB',(N,N),dark);d=ImageDraw.Draw(img);r=random.Random(stable(name))
  rows=8; cols=7;hh=16;ww=N/cols
  for yy in range(rows):
   for xx in range(cols+1):
    x=int((xx+(yy%2)*.5)*ww)%N;y=yy*hh; w=int(ww)-3
    col=[base,light,top,hi][(xx+yy*3)%4]
    pts=[(x+2,y+5),(x+4,y+2),(x+w-3,y+2),(x+w,y+5),(x+w-2,y+12),(x+3,y+14)]
    for sx in [-N,0,N]:
     d.polygon([(a+sx,b) for a,b in pts],fill=col)
     d.line([(a+sx,b) for a,b in pts[:3]],fill=hi,width=1)
  return img
 # brick / ruinbrick / mossbrick / slab
 img=Image.new('RGB',(N,N),dark);d=ImageDraw.Draw(img);r=random.Random(stable(name))
 h=16 if kind in ('brick','mossbrick','ruinbrick') else 32
 w=32 if kind in ('brick','mossbrick','ruinbrick') else 32
 for iy in range(N//h):
  off=(iy%2)*(w//2);y=iy*h
  for ix in range(-1,N//w+2):
   x=off+ix*w
   seed=(stable(name)+iy*17+ix*51)%333;colors=[base,light,top,base,light,top]
   col=colors[seed%len(colors)]
   if kind=='ruinbrick' and (seed%11==0):col=mix(col,dark,.32)
   tiled_rect(d,x+2,y+2,x+w-3,y+h-3,col)
   tiled_line(d,[(x+3,y+2),(x+w-3,y+2)],hi,1)
   tiled_line(d,[(x+w-3,y+3),(x+w-3,y+h-3)],base,2)
   if kind=='ruinbrick' and seed%5==0:
    xx=x+w//2; yy=y+3;tiled_line(d,[(xx,yy),(xx-3,yy+4),(xx+3,yy+6),(xx,yy+h-5)],dark,1)
   if kind=='mossbrick' and seed%3==0:
    moss='#385643';tiled_rect(d,x+3,y+h-6,x+8,y+h-3,moss)
    tiled_rect(d,x+w-11,y+h-5,x+w-8,y+h-3,'#627b52')
   if kind=='slab' and seed%4==0:
    tiled_line(d,[(x+6,y+4),(x+13,y+4),(x+16,y+9)],dark,1)
 return img

ALL_TEX={}
for cat,dest,entries in [('solo','01_SOLOS',SOILS),('parede','02_PAREDES_RUINAS',WALLS),('piso','03_PISOS',FLOORS)]:
 for name,kind,pal in entries:
  img=details(tile_noise(name,pal),name,kind,pal) if cat=='solo' else masonry(name,kind,pal)
  path=ROOT/dest/(name+'.png');img.save(path)
  ALL_TEX[name]={'category':cat,'kind':kind,'file':str(path.relative_to(ROOT)),'palette':pal}
print('Textures:',len(ALL_TEX),flush=True)

# Alpha-overlay tiles, corner codes 1 NW, 2 NE, 4 SE, 8 SW.
# Edge samples derived solely from adjacent matching corner values => geometric continuity.
PAIRS=[('grama_viva','terra_castanha'),('grama_prado','trilha_batida'),('grama_seca','terra_clara'),('relva_bambu','solo_florestal'),('solo_florestal','rocha_cinza'),('terra_castanha','rocha_cinza'),('areia_bege','grama_seca'),('pedra_musgosa','lajes_ruina_cinza')]
# Secondary material is bottom/background. First material is top overlay (transparent where below).
Y,X=np.mgrid[0:N,0:N].astype('float32');u=X/(N-1);v=Y/(N-1)
all_trans=[]
for a,b in PAIRS:
 folder=ROOT/'04_TRANSICOES'/f'{b}__para__{a}';folder.mkdir(exist_ok=True)
 src=np.asarray(Image.open(ROOT/ALL_TEX[a]['file']).convert('RGB'))
 noise=nwrap(N,9,stable(a+b))*0.56+nwrap(N,33,stable(a+b)+9)*.29+nwrap(N,64,stable(a+b)+12)*.15
 # zero at all edges ensures adjacent masks always agree more precisely
 edge_dist=np.minimum.reduce((u,1-u,v,1-v))
 wav=(noise-.5)*.26*np.minimum(edge_dist*16,1)
 for code in range(16):
  tl=1 if code&1 else 0;tr=1 if code&2 else 0;br=1 if code&4 else 0;bl=1 if code&8 else 0
  t=(tl*(1-u)*(1-v)+tr*u*(1-v)+bl*(1-u)*v+br*u*v)
  if code==0:alpha=np.zeros((N,N),dtype='uint8')
  elif code==15:alpha=np.full((N,N),255,dtype='uint8')
  else:
   f=(t-0.5+wav)*15
   alpha=(np.clip(f+.5,0,1)*255).astype('uint8')
  tile=np.dstack([src,alpha]);Image.fromarray(tile,'RGBA').save(folder/f'msc4_{code:02d}.png')
 all_trans.append({'over':a,'under':b,'folder':str(folder.relative_to(ROOT)),'tiles':16})
 # Preview of all 16 masks, as base combined with over image
 base=np.asarray(Image.open(ROOT/ALL_TEX[b]['file']).convert('RGB'),dtype='float32')
 atlas=Image.new('RGB',(4*N,4*N))
 for code in range(16):
  over=np.asarray(Image.open(folder/f'msc4_{code:02d}.png').convert('RGBA'),dtype='float32')
  al=over[:,:,3:]/255
  res=(base*(1-al)+over[:,:,:3]*al).astype('uint8')
  atlas.paste(Image.fromarray(res,'RGB'),((code%4)*N,(code//4)*N))
 atlas.save(folder/'ATLAS_PREVIEW_FUNDO_COMPOSTO.png')
 print('Transitions',a,b,flush=True)
print('Transitions done:', len(PAIRS)*16,flush=True)

# Small alpha decals with deterministic shapes, separate from core textures
DECALS=[('rachadura_fina','crack'),('rachadura_grande','crack'),('musgo_manchas','moss'),('musgo_cantos','moss'),('folhas_secas','leaves'),('folhas_bambu','leaves'),('pedrinhas','stones'),('pegadas','footprints'),('terra_gasta','dirt'),('vegetacao_fenda','moss'),('manchas_umidas','dirt'),('cascalho_solto','stones'),('raizes','roots'),('areia_soprada','dirt'),('flores_pequenas','flowers'),('musgo_cinza','moss')]
for name,kind in DECALS:
 rng=random.Random(stable(name));im=Image.new('RGBA',(N,N));d=ImageDraw.Draw(im)
 def xy():return rng.randrange(8,N-8),rng.randrange(8,N-8)
 if kind in ['crack','roots']:
  for k in range(4 if 'grande' in name else 2):
   x,y=xy();p=[(x,y)]
   for j in range(7 if kind=='crack' else 9):
    x+=rng.randrange(-12,13);y+=rng.randrange(-11,12);p.append((x,y))
   d.line(p,fill=(27,28,28,210) if kind=='crack' else (64,47,34,230),width=3 if 'grande' in name else 2)
 elif kind in ['moss','leaves','flowers','stones','dirt']:
  number={'moss':170,'leaves':60,'flowers':45,'stones':52,'dirt':140}[kind]
  for k in range(number):
   x,y=xy();w=rng.randrange(2,8);h=rng.randrange(2,6)
   co= {'moss':(53+rng.randrange(30),87+rng.randrange(40),49+rng.randrange(24),rng.randrange(120,221)), 'leaves':(96+rng.randrange(80),97+rng.randrange(65),39+rng.randrange(35),220),'flowers':(184+rng.randrange(45),126+rng.randrange(60),130+rng.randrange(80),230),'stones':(117+rng.randrange(55),117+rng.randrange(45),108+rng.randrange(34),205),'dirt':(65+rng.randrange(40),54+rng.randrange(30),39+rng.randrange(25),rng.randrange(50,170))}[kind]
   if kind=='leaves':d.polygon([(x,y-h),(x+w,y),(x,y+h),(x-w,y)],fill=co)
   else:d.ellipse((x-w,y-h,x+w,y+h),fill=co)
 elif kind=='footprints':
  for k in range(6):
   x=43+(k%2)*35+(k//2)*4;y=18+k*16
   d.ellipse((x,y,x+7,y+13),fill=(48,41,33,145))
 im.save(ROOT/'05_DECALQUES'/(name+'.png'))
print('Decals:',len(DECALS),flush=True)
# Standalone low-poly environment meshes, glTF 2.0 binary with vertex colors.
# Models are visual prototypes for scene composition; collision bodies belong in game prefabs.
class Geo:
 def __init__(self,name):self.name=name;self.parts=[]
 def add(self,m,c):
  c=C(c) if isinstance(c,str) else c
  m.visual.vertex_colors=np.tile([*c,255],(len(m.vertices),1)).astype('uint8');self.parts.append((m,c))
 def cube(self,xyz,scale,col):
  m=trimesh.creation.box(extents=scale);m.apply_translation(xyz);self.add(m,col)
 def cyl(self,xyz,r,h,col,sections=8):
  m=trimesh.creation.cylinder(radius=r,height=h,sections=sections)
  m.apply_transform(trimesh.transformations.rotation_matrix(-math.pi/2,[1,0,0]));m.apply_translation(xyz);self.add(m,col)
 def roof(self,xyz,width,length,height,col):
  x,y,z=xyz;w=width/2;l=length/2;h=height
  vs=np.array([[-w,0,-l],[w,0,-l],[0,h,-l],[-w,0,l],[w,0,l],[0,h,l]],dtype='float64')
  fs=np.array([[0,1,2],[5,4,3],[0,2,5],[0,5,3],[2,1,4],[2,4,5],[1,0,3],[1,3,4]])
  m=trimesh.Trimesh(vertices=vs,faces=fs,process=False);m.apply_translation((x,y,z));self.add(m,col)
 def beam(self,a,b,thick,color):
  a=np.array(a,float);b=np.array(b,float);vec=b-a;leng=np.linalg.norm(vec)
  m=trimesh.creation.box(extents=[thick,leng,thick]);
  T=trimesh.geometry.align_vectors([0,1,0],vec/leng);m.apply_transform(T);m.apply_translation((a+b)/2);self.add(m,color)
 def save(self,folder):
  s=trimesh.Scene()
  for i,(m,c) in enumerate(self.parts):s.add_geometry(m,geom_name=f'part_{i:03d}')
  data=s.export(file_type='glb');p=folder/(self.name+'.glb');p.write_bytes(data)
  return p

DARK='#29313A';STONE='#7a847e';STONE2='#a3a59a';MOSS='#50674c';WOOD='#694934';WOOD2='#98714c';ROOF='#853d37';LEAF='#487c4c';LEAF2='#619c60';GOLD='#d5b36e';BAM='#758b4a'

def make_asset(name,kind,variation=0):
 a=Geo(name);rng=random.Random(stable(name))
 if kind=='bamboo':
  howmany=1 if variation==0 else 4 if variation==1 else 9
  for j in range(howmany):
   x=0 if howmany==1 else rng.uniform(-.55,.55);z=0 if howmany==1 else rng.uniform(-.5,.5);h=rng.uniform(2.8,4.4)
   a.cyl((x,h/2,z),.09 if howmany<9 else .06,h,BAM,7)
   for k in range(4):
    y=(k+1)*h/5;a.cyl((x,y,z),.13 if howmany<9 else .09,.07,'#455f34',8)
    if k%2==0:
     a.beam((x,y,z),(x+(1 if k%4 else -1)*.6,y+.4,z),.08,'#456b3d')
     a.cube((x+(.65 if k%4 else -.65),y+.43,z),(.75,.11,.20),LEAF)
 elif kind=='pine':
  h=3 if variation==0 else 4.7;a.cyl((0,h*.35,0),.2,h*.7,WOOD,7)
  for k in range(3):
   r=(.94-k*.19)*(1 if variation==0 else 1.2);base=.8+k*.8
   a.cyl((0,base+.46,0),r,.98,LEAF if k%2 else '#355c46',8)
   a.cube((0,base+.7,0),(r*1.65,.38,r*1.65),LEAF)
 elif kind=='broadtree':
  h=3.5 if variation==0 else 5;a.cyl((0,h*.43,0),.25,h*.86,WOOD,7)
  for xx,yy,zz,rr in [(-.6,h*.86,0,.78),(.6,h*.83,.2,.82),(0,h*1.05,0,.95),(0,h*.8,-.6,.67)]:
   a.cube((xx,yy,zz),(rr*2,rr*1.45,rr*2),LEAF2 if variation==0 else '#8f9d62')
 elif kind=='cherry':
  a.cyl((0,1.65,0),.22,3.3,WOOD,7)
  for xx,yy,zz in [(-.7,3.2,0),(.5,3.4,.25),(0,3.7,-.6),(0,4.05,.3)]:a.cube((xx,yy,zz),(1.45,.95,1.34),'#c78399' if variation==0 else '#b45c58')
 elif kind=='bush':
  for j in range(7 if variation==0 else 11):
   x=rng.uniform(-.55,.55);z=rng.uniform(-.5,.5);y=.3+rng.uniform(0,.4)
   a.cube((x,y,z),(.65,.55,.66),LEAF if j%3 else LEAF2)
 elif kind=='rock':
  howmany=4 if variation==0 else 9 if variation==1 else 14
  for j in range(howmany):
   x=rng.uniform(-.65,.65)*(variation+1)*.75;z=rng.uniform(-.65,.65)*(variation+1)*.75
   h=rng.uniform(.35,.8)*(variation+1)*.53;r=rng.uniform(.28,.6)*(variation+1)*.38
   a.cube((x,h/2,z),(r*2,h,r*2),STONE if j%3 else STONE2)
  if variation==3:
   for j in range(3):a.cube((rng.uniform(-.4,.4),2+j*.68,rng.uniform(-.3,.3)),(.65,.75,.65),'#69777a')
 elif kind=='cliff':
  h=3.8 if variation==0 else 6.6
  for j in range(8):
   x=(j%4-1.5)*.6;z=(j//4-.5)*.8;y=h*(.27+.2*abs(j-4)/8)
   a.cube((x,y/2,z),(.65,y,.85),['#495760','#586a72','#82918e'][j%3])
 elif kind=='crystal':
  for j in range(6):
   x=rng.uniform(-.65,.65);z=rng.uniform(-.65,.65);h=rng.uniform(.7,2)
   a.cube((x,h/2,z),(.32,h,.30),'#7865ab' if variation==0 else '#68a4af')
   a.roof((x,h,z),.32,.32,.35,'#c1acdc' if variation==0 else '#a7e7df')
 elif kind in ('wall','wall_ruin','wall_corner','dungeonwall'):
  col='#697875' if kind!='dungeonwall' else '#484f58'
  if kind=='wall_corner':
   a.cube((0,1,0),(2.8,2,.45),col);a.cube((-1.15,1,1.1),(.45,2,2.2),col)
  else:
   a.cube((0,1,0),(3 if kind=='wall_ruin' else 3.3,2,.42),col)
  for y in [.35,.85,1.35,1.85]:
   for x in [-1.15,-.37,.41,1.18]:
    if kind=='wall_ruin' and x>.3 and y>1.25:continue
    a.cube((x+(0.2 if int(y*10)%2 else 0),y,.235),(.67,.08,.045),'#394845')
  if kind=='wall_ruin':
   a.cube((1.25,.37,.35),(.47,.66,.40),STONE2);a.cube((-1.15,1.99,-.24),(.6,.25,.47),STONE2)
  if kind=='dungeonwall':a.cube((0,1.68,.24),(2.7,.2,.09),'#777d7c')
 elif kind=='arch':
  a.cube((-1.05,1.4,0),(.58,2.8,.75),STONE)
  a.cube((1.05,1.4,0),(.58,2.8,.75),STONE)
  a.cube((0,2.74,0),(2.75,.62,.92),STONE2)
  if variation:
   a.cube((-.85,3.15,0),(.8,.2,.85),MOSS);a.cube((1,3.1,0),(.45,.4,.8),'#596b60')
 elif kind=='pillar':
  h=3.3 if variation==0 else 2.2
  a.cube((0,.15,0),(1.15,.3,1.15),STONE)
  a.cube((0,h/2+.15,0),(.68,h,.68),STONE2)
  a.cube((0,h+.28,0),(1,.32,1),STONE)
  if variation==1:a.cube((.3,h+.35,0),(.5,.48,.73),MOSS)
 elif kind=='steps':
  for j in range(6):a.cube((0,.12+j*.24,1.2-j*.40),(2.7,.24,.4),STONE if j%2 else STONE2)
 elif kind=='floorblock':a.cube((0,.18,0),(3,.36,3),STONE2)
 elif kind=='altar':
  a.cube((0,.25,0),(2.5,.5,2.2),STONE)
  a.cube((0,.72,0),(1.8,.44,1.45),STONE2)
  a.cube((0,1.1,0),(1.0,.4,1.0),STONE)
  a.cube((0,1.4,0),(.5,.2,.5),GOLD)
 elif kind=='obelisk':
  a.cube((0,.22,0),(1.7,.45,1.7),STONE)
  a.cube((0,2.1,0),(.85,3.3,.75),'#5b616d')
  a.roof((0,3.7,0),.90,.84,.6,STONE2)
  a.cube((0,2.1,.41),(.15,.9,.08),'#93c0ad')
 elif kind=='gate':
  a.cube((-1.3,1.55,0),(.33,3.1,.32),ROOF)
  a.cube((1.3,1.55,0),(.33,3.1,.32),ROOF)
  a.cube((0,3.2,0),(3.5,.3,.45),WOOD)
  a.roof((0,3.33,0),4.3,1.3,.65,ROOF if not variation else '#395963')
  a.cube((0,3.03,.67),(.86,.15,.14),GOLD)
 elif kind=='roofmodule':
  a.roof((0,1.4,0),3.7,3.4,1.05,'#9a4e45' if variation==0 else '#39545a')
  a.cube((0,1.25,0),(3.5,.25,3.3),WOOD)
  for x in [-1.84,1.84]:a.cube((x,1.35,0),(.15,.21,3.6),WOOD)
 elif kind=='house':
  a.cube((0,1.3,0),(3.1,2.6,2.8),'#b1a38b')
  for x in [-1.38,1.38]:a.cube((x,1.35,0),(.26,2.7,2.9),WOOD)
  a.cube((0,.84,1.43),(.73,1.7,.12),WOOD)
  a.roof((0,2.65,0),3.6,3.4,1.02,ROOF)
  a.cube((0,2.57,0),(3.65,.13,3.43),WOOD)
 elif kind=='bridge':
  for j in range(9):a.cube((0,.5,-2+j*.5),(2.3,.20,.46),WOOD2 if j%2 else WOOD)
  for x in [-1,1]:
   for z in [-1.8,-.4,1,2]:a.cube((x,1.1,z),(.15,1.1,.17),WOOD)
   a.cube((x,1.45,0),(.11,.13,4.4),WOOD2)
 elif kind=='fence':
  for x in [-1.1,1.1]:a.cube((x,.75,0),(.23,1.5,.24),WOOD)
  for y in [.6,1.15]:a.cube((0,y,0),(2.5,.14,.14),WOOD2)
 elif kind=='lamp':
  a.cube((0,1.5,0),(.19,3,.19),WOOD)
  a.cube((0,3.07,0),(.9,.23,.9),WOOD2)
  a.cube((0,2.7,0),(.48,.68,.48),'#e2b36b')
  a.roof((0,3.15,0),.85,.85,.45,ROOF)
 elif kind=='crate':
  a.cube((0,.55,0),(1,1.1,1),WOOD2)
  for yy in [.10,.50,1.0]:a.cube((0,yy,.54),(1.12,.12,.09),WOOD)
  for xx in [-.48,.48]:a.cube((xx,.56,.54),(.1,1.13,.12),WOOD)
 elif kind=='barrel':
  a.cyl((0,.7,0),.51,1.4,WOOD,10)
  for y in [.25,1.18]:a.cyl((0,y,0),.53,.1,'#44545a',10)
 elif kind=='sack':
  a.cube((0,.42,0),(.75,.86,.59),'#b3a181');a.cube((0,.87,0),(.4,.12,.4),WOOD)
 elif kind=='bench':
  a.cube((0,.8,0),(2.15,.22,.7),WOOD2)
  for x in [-.82,.82]:a.cube((x,.35,0),(.2,.70,.38),WOOD)
 elif kind=='table':
  a.cube((0,.95,0),(2.1,.23,1.4),WOOD2)
  for x in [-.8,.8]:
   for z in [-.47,.47]:a.cube((x,.43,z),(.18,.86,.17),WOOD)
 elif kind=='stall':
  a.cube((0,.8,0),(2.5,.18,1.5),WOOD2)
  for x in [-1.08,1.08]:
   for z in [-.63,.63]:a.cube((x,1.5,z),(.18,3,.18),WOOD)
  a.roof((0,3.04,0),3.2,2.35,.58,ROOF)
 elif kind=='well':
  a.cyl((0,.6,0),.8,1.2,STONE,10)
  a.cyl((0,1.0,0),.82,.28,STONE2,10)
  for x in [-1,1]:a.cube((x,1.95,0),(.16,2.3,.17),WOOD)
  a.roof((0,3.0,0),2.7,1.85,.6,ROOF)
 elif kind=='cart':
  a.cube((0,.95,0),(2.35,.38,1.5),WOOD2)
  for x in [-1,1]:
   for z in [-.7,.7]:a.cube((x,1.25,z),(.18,.5,.18),WOOD)
  for x in [-.8,.8]:a.cyl((x,.50,.92),.42,.15,'#49423a',10)
  a.beam((0,.95,-.7),(0,.95,-2.3),.17,WOOD)
 elif kind=='torch':
  a.cube((0,1,0),(.15,2,.15),WOOD)
  a.cube((0,2.1,0),(.37,.45,.32),'#c77d3e')
  a.roof((0,2.36,0),.35,.35,.35,'#efd184')
 elif kind=='chest':
  a.cube((0,.62,0),(1.75,1.0,1.05),WOOD)
  a.cube((0,1.14,0),(1.92,.30,1.18),WOOD2)
  a.cube((0,.78,.56),(.2,.25,.15),GOLD)
  for x in [-.7,.7]:a.cube((x,.6,.56),(.09,.95,.10),'#3c4f55')
 elif kind=='dungeon_gate':
  for x in [-1.4,1.4]:a.cube((x,1.4,0),(.5,2.8,.65),STONE)
  a.cube((0,2.85,0),(3.3,.52,.75),STONE2)
  for x in [-1.0,-.5,0,.5,1.0]:a.cube((x,1.4,0),(.13,2.52,.15),'#373d43')
 elif kind=='stalagmite':
  for j in range(5):
   x=rng.uniform(-.8,.8);z=rng.uniform(-.8,.8)
   h=rng.uniform(.7,2.6);a.cube((x,h*.36,z),(.52,h*.72,.45),'#5a6566')
   a.roof((x,h*.72,z),.52,.45,h*.28,STONE2)
 elif kind=='stairs_wood':
  for j in range(6):a.cube((0,.14+j*.29,1.35-j*.5),(2.5,.28,.52),WOOD2)
 elif kind=='flowerbed':
  a.cube((0,.15,0),(2.5,.3,1.6),WOOD)
  a.cube((0,.32,0),(2.3,.09,1.4),'#67513b')
  for j in range(11):
   x=rng.uniform(-.93,.93);z=rng.uniform(-.5,.5);hh=rng.uniform(.35,.68)
   a.cube((x,.38+hh/2,z),(.10,hh,.10),LEAF)
   a.cube((x,.4+hh,z),(.26,.22,.26),['#bb7385','#c5ab65','#c6b2ad'][j%3])
 elif kind=='rubble':
  for j in range(14):
   x=rng.uniform(-1.5,1.5);z=rng.uniform(-.8,.8);hh=rng.uniform(.17,.7)
   a.cube((x,hh/2,z),(rng.uniform(.25,.8),hh,rng.uniform(.25,.7)),STONE if j%2 else STONE2)
 else:raise ValueError(kind)
 return a

OBJECT_SPECS = [
 ('bambu_alto','bamboo',0,'vegetacao'),('bambu_grupo','bamboo',1,'vegetacao'),('bambu_bosque','bamboo',2,'vegetacao'),
 ('pinheiro_pequeno','pine',0,'vegetacao'),('pinheiro_grande','pine',1,'vegetacao'),
 ('arvore_folhosa','broadtree',0,'vegetacao'),('arvore_grande','broadtree',1,'vegetacao'),
 ('cerejeira','cherry',0,'vegetacao'),('arvore_folhas_vermelhas','cherry',1,'vegetacao'),
 ('arbusto','bush',0,'vegetacao'),('moita_densa','bush',1,'vegetacao'),
 ('rocha_pequena','rock',0,'rochas'),('rochas_medias','rock',1,'rochas'),('rocha_grande','rock',2,'rochas'),('formacao_rochosa','rock',3,'rochas'),('penhasco_baixo','cliff',0,'rochas'),('penhasco_alto','cliff',1,'rochas'),
 ('cristal_purpura','crystal',0,'rochas'),('cristal_ciano','crystal',1,'rochas'),
 ('parede_ruina_reta','wall',0,'ruinas'),('parede_ruina_danificada','wall_ruin',0,'ruinas'),('parede_ruina_canto','wall_corner',0,'ruinas'),('parede_masmorra','dungeonwall',0,'masmorras'),
 ('arco_ruina','arch',0,'ruinas'),('arco_ruina_musgoso','arch',1,'ruinas'),('pilar_ruina','pillar',0,'ruinas'),('coluna_quebrada','pillar',1,'ruinas'),('escadaria_pedra','steps',0,'ruinas'),('laje_ruina','floorblock',0,'ruinas'),('altar_pedra','altar',0,'ruinas'),('obelisco','obelisk',0,'ruinas'),('entulho_pedra','rubble',0,'ruinas'),
 ('portao_torii','gate',0,'construcoes'),('portao_templete','gate',1,'construcoes'),('telhado_rufo_vermelho','roofmodule',0,'construcoes'),('telhado_rufo_azul','roofmodule',1,'construcoes'),('casa_modular','house',0,'construcoes'),('ponte_madeira','bridge',0,'construcoes'),
 ('cerca_segmento','fence',0,'objetos'),('poste_lanterna','lamp',0,'objetos'),('caixote','crate',0,'objetos'),('barril','barrel',0,'objetos'),('saco_mercadorias','sack',0,'objetos'),('banco_madeira','bench',0,'objetos'),('mesa_madeira','table',0,'objetos'),('barraca_feira','stall',0,'objetos'),('poco','well',0,'objetos'),('carroca','cart',0,'objetos'),('canteiro_flores','flowerbed',0,'objetos'),
 ('tocha_coluna','torch',0,'masmorras'),('bau_madeira','chest',0,'masmorras'),('portao_masmorra','dungeon_gate',0,'masmorras'),('estalagmites','stalagmite',0,'masmorras'),('escada_madeira','stairs_wood',0,'objetos')
]

# Flat shaded isometric preview based on actual mesh triangles, not concept art.
def preview_geo(geo,size=(400,335)):
 meshes=[m for m,_ in geo.parts];v=np.vstack([m.vertices for m in meshes])
 lo=v.min(axis=0);hi=v.max(axis=0);center=(hi+lo)/2
 xaxis=np.array([.78,0,-.63]);xaxis/=np.linalg.norm(xaxis)
 yaxis=np.array([-.35,.86,-.44]);yaxis/=np.linalg.norm(yaxis)
 depth=np.cross(xaxis,yaxis);depth/=np.linalg.norm(depth)
 projected=np.stack([(v-center)@xaxis, (v-center)@yaxis],axis=1)
 rr=projected.max(axis=0)-projected.min(axis=0)
 scale=min((size[0]-58)/max(rr[0],.01),(size[1]-60)/max(rr[1],.01))
 cx=size[0]/2;cy=size[1]*.55
 im=Image.new('RGB',size,(25,33,37));d=ImageDraw.Draw(im)
 polys=[]
 for m,c in geo.parts:
  for tri in m.triangles:
   q=tri-center
   pts=[(cx+float(p@xaxis)*scale,cy-float(p@yaxis)*scale) for p in q]
   dep=np.mean(q@depth)
   normal=np.cross(tri[1]-tri[0],tri[2]-tri[0]);normal=normal/(np.linalg.norm(normal)+1e-7)
   shade=float(np.clip(.68+.30*max(0,np.dot(normal,np.array([-.4,.8,.5]))),.50,1))
   cc=tuple(int(np.clip(i*shade,0,255)) for i in c)
   polys.append((dep,pts,cc))
 # depth may depend on orientation; checked using sample image
 polys.sort(key=lambda x:x[0])
 for _,pts,col in polys:d.polygon(pts,fill=col)
 return im

OBJ_META=[]
for name,kind,var,group in OBJECT_SPECS:
 obj=make_asset(name,kind,var); folder=ROOT/'06_OBJETOS_GLB'/group;folder.mkdir(exist_ok=True)
 p=obj.save(folder)
 preview=preview_geo(obj); pp=ROOT/'00_CATALOGO'/f'thumb_{name}.png';preview.save(pp)
 v=np.vstack([m.vertices for m,_ in obj.parts]);mins=v.min(axis=0);maxs=v.max(axis=0)
 OBJ_META.append({'name':name,'category':group,'file':str(p.relative_to(ROOT)),'preview':str(pp.relative_to(ROOT)),'bounds_m':np.round(maxs-mins,3).tolist(),'triangles':int(sum(len(m.faces) for m,_ in obj.parts))})
print('GLB objects:',len(OBJ_META),flush=True)
# A visual gallery of EXACT shipped file renders, not generated concept imagery.
BG=(17,24,28);PANEL=(30,39,44);INK=(235,233,221);SUB=(165,183,180);GOLD=(195,156,93)

def board(title, subtitle, entries, cols=4, rows=3, is_object=False):
 W=1600;cellw=365;cellh=255 if not is_object else 245; pad=70
 H=175+rows*cellh+65
 canvas=Image.new('RGB',(W,H),BG);d=ImageDraw.Draw(canvas)
 d.text((70,36),title,font=font(40,True),fill=INK)
 d.text((72,99),subtitle,font=font(19),fill=SUB)
 d.line((70,144,1530,144),fill=GOLD,width=3)
 for i,(name,path) in enumerate(entries[:cols*rows]):
  col=i%cols;row=i//cols;x=pad+col*cellw;y=165+row*cellh
  d.rounded_rectangle((x,y,x+cellw-13,y+cellh-14),radius=13,fill=PANEL,outline=(55,65,69),width=2)
  img=Image.open(path).convert('RGBA')
  if is_object:
   scale=min((cellw-37)/img.width,(cellh-63)/img.height)
   img=img.resize((int(img.width*scale),int(img.height*scale)),Image.Resampling.LANCZOS)
   canvas.paste(img,(x+(cellw-13-img.width)//2,y+8),img if img.mode=='RGBA' else None)
  else:
   sz=min(194,cellh-65);img=img.resize((sz,sz),Image.Resampling.NEAREST)
   canvas.paste(img,(x+(cellw-13-sz)//2,y+9),img)
  label=name.replace('_',' ').capitalize();d.text((x+12,y+cellh-46),label,font=font(18,True),fill=INK)
  if not is_object:d.text((x+12,y+cellh-27),'PNG 128 × 128 • repetível',font=font(13),fill=SUB)
 out=ROOT/'00_CATALOGO'/('PRANCHA_'+str(len(BOARD_FILES)+1).zfill(2)+'.png')
 canvas.save(out,optimize=True);BOARD_FILES.append(out)

BOARD_FILES=[]
for title,sub,collection,folder in [('SOLOS E BIOMAS','24 materiais de terreno • 128 × 128 • base para geração por seed',SOILS,'01_SOLOS'),('PAREDES E RUÍNAS','22 superfícies de tijolos, ruínas, madeira e templos',WALLS,'02_PAREDES_RUINAS'),('PISOS E TRILHAS','14 pisos para praças, ruínas, interiores e construções',FLOORS,'03_PISOS')]:
 rows=math.ceil(len(collection)/4)
 board(title,sub,[(name,ROOT/folder/(name+'.png')) for name,*_ in collection],4,rows)
board('DECALQUES TRANSPARENTES','16 sobreposições RGBA • rachaduras, raízes, musgo e vegetação',[(name,ROOT/'05_DECALQUES'/(name+'.png')) for name,_ in DECALS],4,4)
# Group transition example atlas from real files
board('TRANSIÇÕES CONECTADAS','8 famílias de 16 máscaras de cantos (MSC4) • 128 PNG RGBA',[(f'{a} / {b}',ROOT/'04_TRANSICOES'/f'{b}__para__{a}'/'ATLAS_PREVIEW_FUNDO_COMPOSTO.png') for a,b in PAIRS],4,2)
for cat,labels in [('vegetacao','VEGETAÇÃO'),('rochas','ROCHAS E PENHASCOS'),('ruinas','RUÍNAS E PEDRAS MODULARES'),('construcoes','ARQUITETURA ORIENTAL'),('objetos','OBJETOS DE VILA'),('masmorras','MASMORRAS')]:
 selected=[m for m in OBJ_META if m['category']==cat];
 for start in range(0,len(selected),12):
  subset=selected[start:start+12];board(labels+(' — parte 2' if start else ''),'Modelos GLB 3D reais com cores por vértice • colisão a definir na integração',[(m['name'],ROOT/m['preview']) for m in subset],4,math.ceil(len(subset)/4),is_object=True)

# Before/after visual proof for 3x3 patch mosaic using corner masks.
def demo_trans(a,b,seed,corner_pattern):
 path=ROOT/'04_TRANSICOES'/f'{b}__para__{a}'
 up=np.array(Image.open(ROOT/ALL_TEX[a]['file']).convert('RGB'),np.float32)
 down=np.array(Image.open(ROOT/ALL_TEX[b]['file']).convert('RGB'),np.float32)
 full=np.zeros((3*N,3*N,3),'uint8')
 hard=np.zeros_like(full)
 for y in range(3):
  for x in range(3):
   tl=int(corner_pattern[y][x]);tr=int(corner_pattern[y][x+1]);br=int(corner_pattern[y+1][x+1]);bl=int(corner_pattern[y+1][x])
   code=tl|tr*2|br*4|bl*8
   alpha=np.asarray(Image.open(path/f'msc4_{code:02d}.png'))[:,:,3:4]/255
   mix_tile=(down*(1-alpha)+up*alpha).astype('uint8')
   full[y*N:(y+1)*N,x*N:(x+1)*N]=mix_tile
   hard[y*N:(y+1)*N,x*N:(x+1)*N]=up if code>=8 else down
 return Image.fromarray(hard),Image.fromarray(full)

patt=[[0,0,0,0],[0,1,1,0],[0,1,1,0],[0,0,0,0]]
examples=[('grama_viva','terra_castanha'),('grama_prado','trilha_batida'),('solo_florestal','rocha_cinza')]
W=1690;H=1530;im=Image.new('RGB',(W,H),BG);d=ImageDraw.Draw(im)
d.text((55,26),'TRANSIÇÕES: ANTES E DEPOIS',font=font(41,True),fill=INK)
d.text((55,82),'Máscaras conectadas reais: grama → terra, grama → trilha e floresta → rocha.',font=font(19),fill=SUB)
for i,(a,b) in enumerate(examples):
 before,after=demo_trans(a,b,i,patt)
 yy=148+i*456
 for xx,imgx,lab in [(56,before,'SEM TRANSIÇÃO'),(860,after,'COM TRANSIÇÃO MSC4')]:
  ex=imgx.resize((635,430),Image.Resampling.NEAREST)
  # show central 384x384 at letterbox
  rx=xx+((635-430)//2);im.paste(imgx.resize((430,430),Image.Resampling.NEAREST),(rx,yy))
  d.text((xx+8,yy+440),lab+'  —  '+a+' / '+b,font=font(16,True),fill=INK)
transproof=ROOT/'00_CATALOGO'/'TRANSICOES_ANTES_DEPOIS.png';im.save(transproof);BOARD_FILES.append(transproof)

# Mini samples of 3D objects and surfaces with consistent scale are illustrated in the boards.
# Color proof strip from source package 09.4.6
original_preview=Path('/mnt/data/EXO-Murim-09.4.6-Amostra-de-Terrenos.png')
if original_preview.exists(): shutil.copy2(original_preview,ROOT/'00_CATALOGO'/'REFERENCIA_PALETA_09.4.6.png')

# Reproducible Godot shader and mask convention
shader='''shader_type spatial;
render_mode cull_back, depth_draw_opaque;

// Use a separate material per terrain pair; UV ranges 0-1 on the tile.
uniform sampler2D solo_base : source_color, filter_nearest, repeat_enable;
uniform sampler2D solo_cobertura : source_color, filter_nearest, repeat_enable;
uniform sampler2D mascara_msc4 : filter_nearest, repeat_disable;
uniform float escala_textura : hint_range(0.25,8.0) = 1.0;

void fragment() {
    vec3 base_color = texture(solo_base, UV * escala_textura).rgb;
    vec3 over_color = texture(solo_cobertura, UV * escala_textura).rgb;
    float peso = texture(mascara_msc4, UV).a;
    ALBEDO = mix(base_color, over_color, peso);
    ROUGHNESS = 0.95;
}
'''
(ROOT/'08_FONTES'/'terreno_mescla_msc4.gdshader').write_text(shader,encoding='utf-8')
# Manifest includes file references and clear limitations.
manifest={'name':'EXO-Murim — Acervo Ambiental 01 (proposta para aprovação)', 'status':'PROTÓTIPO DE ASSETS, AINDA NÃO INTEGRADO AO JOGO', 'size_px':128,'terrain_materials':len(SOILS),'wall_materials':len(WALLS),'floor_materials':len(FLOORS), 'transition_pairs':all_trans,'transition_tiles':len(PAIRS)*16,'decal_png':len(DECALS),'objects_glb':OBJ_META, 'textures':ALL_TEX,'mask_bits':'NW=1,NE=2,SE=4,SW=8','renderer_note':'GLB with vertex colors; model colliders and scenes not integrated'}
(ROOT/'07_DOCUMENTACAO'/'MANIFESTO_ASSETS.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf-8')
readme=f'''# EXO-MURIM — ACERVO AMBIENTAL 01 (PROPOSTA DE APROVAÇÃO)

Este é um ACERVO AUTÔNOMO de assets reais (PNG 128×128, PNG RGBA e modelos GLB).
NÃO é uma atualização jogável. Nenhum arquivo de jogo foi modificado.

## CONTEÚDO
- {len(SOILS)} texturas de solo: gramas, terra, trilhas, areia, pedras, floresta e argila.
- {len(WALLS)} texturas de paredes: tijolos de ruínas, pedras, templos, madeira, barro e cal.
- {len(FLOORS)} texturas de pisos: ruínas, templos, madeira, tatame e pedra.
- {len(PAIRS)*16} máscaras PNG RGBA para 8 pares de transição de terrenos (16 variantes por par).
- {len(DECALS)} decalques RGBA: rachaduras, musgos, folhas, pedras etc.
- {len(OBJ_META)} modelos 3D GLB para vegetação, rochas, ruínas, vilas e masmorras.
- 00_CATALOGO: pranchas PNG, prévias GLB e PDF de aprovação.

## TRANSIÇÕES ENTRE SOLOS
Use um solo-base completo, a textura de cobertura completa e a máscara selecionada.
Máscara MSC4 (4 cantos): NW=1, NE=2, SE=4, SW=8.
Por exemplo: NW=1, NE=1, SE=0, SW=0 -> índice 03 (msc4_03.png).
As bordas compartilham os valores dos cantos dos ladrilhos vizinhos.
Isto permite compor o encontro de dois solos sem uma aresta seca, desde que
seja respeitada a mesma malha de cantos e o UV do tile.
ATLAS_PREVIEW_FUNDO_COMPOSTO.png é apenas demonstração, NÃO é máscara.
Veja 08_FONTES/terreno_mescla_msc4.gdshader para um exemplo de composição Godot 4.

## MODELOS 3D
- Exportados em glTF 2.0 BINÁRIO (*.glb), eixo Y para cima, cores por vértice.
- São malhas low-poly originais PARA APROVAÇÃO, não modelos finais de estúdio.
- NÃO possuem colisores Godot configurados nem lógica de NPC/interação.
- Acrescentar colisões, LOD, pivôs e scripts após aprovar a direção visual.
- Prévia de cada objeto foi renderizada a partir da malha incluída no arquivo.

## ASSETS NÃO INCLUÍDOS / PENDÊNCIAS
- Não há água animada, fauna, interiores montados, montanhas grandes finalizadas,
  vegetação sazonal avançada, edifícios completos de cidade grande, efeitos de VFX.
- Colisões e integração com terreno procedural precisam ser feitas após aprovação.
- Texturas são artes estilizadas, não normal/roughness/PBR completos.

## DIREITOS DE USO
Todas as texturas, máscaras, decalques e geometrias incluídos foram gerados
originalmente para este pacote por código, sem copiar arquivos de terceiros.
Você pode usar, modificar e distribuir como parte do EXO-Murim, inclusive comercialmente.
A amostra de referência de 09.4.6 é oriunda do seu projeto preexistente, apenas
incluída no catálogo para comparação de paleta; ela não é utilizada como nova textura.

## FEEDBACK
Avalie: 1) estilo de terreno; 2) tijolos e ruínas; 3) transições;
4) silhueta dos objetos; 5) paleta; 6) densidade de detalhes.
Após sua aprovação, integrar ao jogo em LOTES, começando pelo terreno e as colisões.
'''
(ROOT/'LEIA_PRIMEIRO.md').write_text(readme,encoding='utf-8')

# Build PDF from actual catalog pages; each picture is inspectable on its own in ZIP.
from reportlab.pdfgen import canvas
from reportlab.lib.utils import ImageReader
pdf=ROOT/'00_CATALOGO'/'CATALOGO_VISUAL_EXO_MURIM.pdf'
c=canvas.Canvas(str(pdf),pagesize=(1200,850));c.setTitle('EXO-Murim — Catálogo visual de assets ambientais 01')
for page in BOARD_FILES:
 img=Image.open(page).convert('RGB');iw,ih=img.size
 pagew,pageh=1200,850;scale=min(pagew/iw,pageh/ih)
 c.setFillColorRGB(*[i/255 for i in BG]);c.rect(0,0,pagew,pageh,fill=1,stroke=0)
 c.drawImage(ImageReader(img), (pagew-iw*scale)/2,(pageh-ih*scale)/2,iw*scale,ih*scale)
 c.showPage()
c.save()
print('PDF sheets:',len(BOARD_FILES),'Pages',flush=True)

# Verify all PNG, GLB, mask alpha, PDF, then ZIP.
for p in ROOT.rglob('*.png'):
 with Image.open(p) as imx: imx.verify()
for m in OBJ_META:
 p=ROOT/m['file'];scene=trimesh.load(str(p),force='scene');assert len(scene.geometry)>=1
for pair in all_trans:
 f=ROOT/pair['folder'];assert len(list(f.glob('msc4_*.png')))==16
 for i in [0,15]:
  with Image.open(f/f'msc4_{i:02d}.png') as t:
   al=np.array(t.getchannel('A'));assert bool(np.all(al==0)) if i==0 else bool(np.all(al==255))
assert pdf.is_file() and pdf.stat().st_size>30000
archive=ROOT.parent/'EXO-MURIM-COLECAO-ASSETS-AMBIENTAIS-01.zip'
with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED,compresslevel=6) as z:
 for p in sorted(ROOT.rglob('*')):
  if p.is_file():z.write(p,p.relative_to(ROOT.parent))
with zipfile.ZipFile(archive) as z:
 assert z.testzip() is None
 n=len(z.namelist())
print('DONE',archive,round(archive.stat().st_size/1024/1024,2),'MB',n,'files',flush=True)
print('PDF',pdf.stat().st_size, 'size',flush=True)
