from PIL import Image, ImageDraw
import numpy as np, random, math
from pathlib import Path
out=Path(__file__).resolve().parent.parent/'assets'/'terrain';out.mkdir(parents=True,exist_ok=True)
S=128
SETS={
 'grass_lush': {'colors':['#31543c','#396345','#43744b','#4d8054','#588858','#76946a'],'freq':1.0,'kind':'grass'},
 'grass_dry': {'colors':['#626b42','#777b49','#858952','#99945a','#ac9d64','#bcc080'],'freq':0.95,'kind':'grass'},
 'earth': {'colors':['#49372c','#604732','#73543b','#8b6547','#9a7051','#a6805e'],'freq':1.,'kind':'soil'},
 'forest_soil': {'colors':['#283d32','#354839','#495540','#5a6046','#747153','#8b7958'],'freq':0.9,'kind':'forest'},
 'stone': {'colors':['#424a4c','#535d5d','#66716d','#788078','#92968a','#a9ada1'],'freq':1.0,'kind':'stone'},
 'gravel': {'colors':['#535451','#67665c','#7d7969','#96917c','#a9a08a','#b9af94'],'freq':1.1,'kind':'gravel'},
 'moss_stone': {'colors':['#364742','#47564b','#617060','#748071','#949b86','#abb1a0'],'freq':0.9,'kind':'stone'},
 'trail': {'colors':['#554a3b','#6c5b47','#857056','#998268','#b39a78','#c1a989'],'freq':1.,'kind':'soil'},
}

def rgb(h):return np.array([int(h[i:i+2],16) for i in (1,3,5)],dtype=np.float32)
def smooth_noise(seed,grid):
 rng=np.random.default_rng(seed); arr=rng.random((grid,grid));
 coords=np.arange(S)*grid/S; i=np.floor(coords).astype(int);f=coords-i;f=f*f*(3-2*f)
 a=arr[i[:,None]%grid,i[None,:]%grid]
 b=arr[(i[:,None]+1)%grid,i[None,:]%grid]
 c=arr[i[:,None]%grid,(i[None,:]+1)%grid]
 d=arr[(i[:,None]+1)%grid,(i[None,:]+1)%grid]
 return (a*(1-f[:,None])+b*f[:,None])*(1-f[None,:])+(c*(1-f[:,None])+d*f[:,None])*f[None,:]

def dot_wrap(draw,x,y,r,fill):
 for dx in [-S,0,S]:
  for dy in [-S,0,S]:draw.ellipse((x+dx-r,y+dy-r,x+dx+r,y+dy+r),fill=fill)

def line_wrap(draw,pts,fill,width=1):
 for dx in [-S,0,S]:
  for dy in [-S,0,S]:draw.line([(x+dx,y+dy) for x,y in pts],fill=fill,width=width,joint='curve')

for idx,(name,desc) in enumerate(SETS.items()):
 colors=np.array([rgb(x) for x in desc['colors']]);
 large=smooth_noise(4321+idx*78,5); middle=smooth_noise(991+idx*37,17); fine=smooth_noise(517+idx*177,64)
 rng=np.random.default_rng(1000+idx*17)
 mix=np.clip(.18+ .42*large+.30*middle+.12*fine,0,1)
 level=np.clip(np.floor(mix*(len(colors)-1)+.20).astype(int),0,len(colors)-1)
 pix=colors[level].astype(np.uint8)
 img=Image.fromarray(pix,'RGB'); draw=ImageDraw.Draw(img); py_rng=random.Random(800+idx*317)
 kind=desc['kind'];
 if kind=='grass':
  for i in range(350):
   x=py_rng.randrange(S);y=py_rng.randrange(S);l=py_rng.randrange(3,10)
   light=py_rng.random()>.32
   color=desc['colors'][4 if light else 0]
   # short grass blades in isometric screen space; 2-3 pixel clusters
   line_wrap(draw,[(x,y),(x+py_rng.choice([-2,-1,1,2]),y-l)],color,1)
   if i%3==0:line_wrap(draw,[(x+1,y),(x+2,y-l//2)],desc['colors'][2],1)
 elif kind=='soil':
  for i in range(300):
   x=py_rng.randrange(S);y=py_rng.randrange(S)
   color=desc['colors'][py_rng.choice([0,1,3,4,5])]
   draw.rectangle((x,y,x+py_rng.randrange(1,4),y+py_rng.randrange(1,3)),fill=color)
  for i in range(18):
   x=py_rng.randrange(S); y=py_rng.randrange(S)
   line_wrap(draw,[(x,y),(x+py_rng.randrange(2,8),y+py_rng.randrange(-2,3))],desc['colors'][0],1)
 elif kind=='forest':
  for i in range(220):
   x=py_rng.randrange(S);y=py_rng.randrange(S)
   line_wrap(draw,[(x,y),(x+py_rng.randrange(-4,5),y+py_rng.randrange(1,6))],desc['colors'][py_rng.choice([1,3,4])],2)
  for i in range(55):
   x=py_rng.randrange(S);y=py_rng.randrange(S); dot_wrap(draw,x,y,1,desc['colors'][0])
 elif kind=='stone':
  for i in range(35):
   x=py_rng.randrange(S);y=py_rng.randrange(S)
   pts=[(x,y),(x+py_rng.randrange(4,14),y+py_rng.randrange(-2,5)),(x+py_rng.randrange(9,20),y+py_rng.randrange(-6,9))]
   line_wrap(draw,pts,desc['colors'][0],1)
   if i%3==0:line_wrap(draw,[(p[0]+1,p[1]+2) for p in pts[:2]],desc['colors'][5],1)
 elif kind=='gravel':
  for i in range(260):
   x=py_rng.randrange(S);y=py_rng.randrange(S);r=py_rng.randrange(1,4)
   dot_wrap(draw,x,y,r,desc['colors'][py_rng.choice([0,1,2,4,5])])
   if i%3==0:line_wrap(draw,[(x-r,y),(x+r,y)],desc['colors'][0],1)
 path=out/(name+'.png');img.save(path,optimize=True)
 print(name,path.stat().st_size)
# quick comparison contact sheet, not required by the game
prev=Image.new('RGB',(4*258,2*290),(29,33,33))
from PIL import ImageFont
pdraw=ImageDraw.Draw(prev)
for i,name in enumerate(SETS):
 x=(i%4)*258;y=(i//4)*290
 prev.paste(Image.open(out/(name+'.png')).resize((240,240),resample=Image.Resampling.NEAREST),(x+9,y+8))
 pdraw.text((x+12,y+256),name,fill=(230,230,220))
prev.save(str(out/'AMOSTRA-GRAMAS-SOLOS.png'))
