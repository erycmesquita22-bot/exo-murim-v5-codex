"""Produce original RGBA 512x512 offline previews; not native Godot screenshots."""
from PIL import Image,ImageDraw,ImageFilter
from pathlib import Path
import json,math,random
ROOT=Path(__file__).resolve().parents[2]
OUTPUT=ROOT/'PREVIEWS-VFX-03'
RECIPES=Path(__file__).resolve().parents[1]/'recipes'
S=512
FPS=24
N=16

def lerp(a,b,t):return a+(b-a)*t
def ellipse(d,cx,cy,rx,ry,color,w=3,st=0,en=360):
  rx=max(1,rx);ry=max(1,ry)
  d.arc([cx-rx,cy-ry,cx+rx,cy+ry],st,en,fill=color,width=max(1,int(w)))
def rgb(hexcolor):return tuple(int(hexcolor[i:i+2],16) for i in (1,3,5))
def run_one(rec):
  family=rec['family']; name=family
  out=OUTPUT/name;out.mkdir(parents=True,exist_ok=True)
  col=rgb(rec['shader_params']['color']); white=tuple(min(255,int(x*0.3+190)) for x in col)
  frames=[]; alpha_coverage=[]
  for frame in range(N):
    rng=random.Random(30011+frame*733+len(name)*31)
    t=(frame+0.5)/N; intensity=min(1,t*4.0)*(1-max(0,(t-.61)/.39))**1.15
    layer=Image.new('RGBA',(S,S));d=ImageDraw.Draw(layer)
    cx=256;cy=270; strength=max(0.0,intensity)
    # Render per-timestamp silhouettes. Every PNG is natively generated at 512x512.
    if family=='slash':
      start=-155;end=lerp(-152,72,min(1,t*1.7))
      for radius,weight,alpha in [(177,26,52),(177,12,160),(177,4,248),(190,5,76)]:
        ellipse(d,cx,cy, radius,radius*.66,col+(int(alpha*strength),),weight,start,end)
      for j in range(int(50*t)+1):
        angle=math.radians(rng.uniform(start,end))
        radius=rng.uniform(140,210)
        x=cx+radius*math.cos(angle);y=cy+radius*.68*math.sin(angle)
        d.line((x,y,x+rng.uniform(-14,14),y-rng.uniform(5,22)),fill=white+(int(135*strength),),width=2)
    elif family=='impact':
      r=lerp(12,201,min(1,t*1.8))
      for expand,alpha,w in [(0,140,15),(-12,220,5),(-25,70,24)]:ellipse(d,cx,cy+66,r+expand,max(4,(r+expand)*.33),col+(int(alpha*strength),),w)
      for i in range(25):
        a=(i*2.39996+rng.uniform(-.1,.1));speed=rng.uniform(45,205)*min(1,t*2.5)
        x=cx+math.cos(a)*speed;y=cy+66+math.sin(a)*speed*.56-t*80
        length=rng.uniform(7,42)*strength
        d.polygon([(x,y-length),(x-4,y+7),(x+4,y+8)],fill=col+(int(150*strength),))
    elif family=='dash':
      for ghost in range(4):
        f=(t*4-ghost*.19)%1
        x=lerp(30,440,f);y=cy+math.sin(x*.025)*15
        a=int(160*strength*(1-ghost*.19))
        d.line((x-64,y+24,x,y),fill=col+(a,),width=22-ghost*2)
        d.ellipse((x-8,y-24,x+10,y-4),fill=white+(a,))
        d.line((x,y+6,x-15,y+35),fill=white+(a,),width=6)
        for z in range(3):d.line((x-40-rng.random()*50,y+12+z*7,x-12,y+z*3),fill=col+(int(a*.75),),width=3)
    elif family=='teleport':
      for side in [-1,1]:
        x=cx+side*102
        stage=math.exp(-((t-(.22 if side<0 else .72))/.22)**2)
        rr=72*max(.05,stage)
        ellipse(d,x,cy,rr,rr*.48,col+(int(245*stage),),max(2,int(10*stage)))
        d.line((x,cy+96,x,cy-180*stage),fill=white+(int(180*stage),),width=max(1,int(7*stage)))
        for i in range(15):
          a=rng.random()*math.tau
          xx=x+math.cos(a)*rr;yy=cy+math.sin(a)*rr*.5
          d.ellipse((xx-2,yy-2,xx+2,yy+2),fill=col+(int(190*stage),))
    elif family=='ice':
      for i in range(21):
        a=i*2.4;dist=((i*.17+t*2)%1)*170
        x=cx+math.cos(a)*dist;y=cy+math.sin(a)*dist*.50+30
        h=(30+(i*17)%96)*strength
        d.polygon([(x-11,y),(x,y-h),(x+13,y),(x,y+15)],fill=col+(int(154*strength),),outline=white+(int(230*strength),))
    elif family=='thunder':
      for strand in range(3):
        points=[]
        for j in range(13):
          x=36+j*37; y=205+strand*26+math.sin(j*.85+t*23+strand)*20+rng.randint(-18,18)
          points.append((x,y))
        d.line(points,fill=col+(int(55*strength),),width=17)
        d.line(points,fill=white+(int(220*strength),),width=3)
    elif family=='meteor':
      x=lerp(52,330,min(1,t*1.4));y=lerp(15,350,min(1,t*1.4))
      for j in range(18):
        f=j/18;xx=x-140*f;yy=y-170*f
        d.ellipse((xx-28*(1-f),yy-28*(1-f),xx+28*(1-f),yy+28*(1-f)),fill=col+(int(150*strength*(1-f)),))
      d.ellipse((x-31,y-31,x+31,y+31),fill=white+(int(240*strength),))
      ellipse(d,cx,362,lerp(10,160,min(1,max(0,t-.54)*3)),25,col+(int(160*strength),),8)
    elif family=='beam':
      end=lerp(85,485,min(1,t*2.0))
      for width,a in [(46,40),(20,100),(7,220)]:d.line((45,cy,end,cy),fill=col+(int(a*strength),),width=width)
      d.line((45,cy,end,cy),fill=white+(int(215*strength),),width=3)
      ellipse(d,end,cy,22,50,col+(int(100*strength),),4)
    elif family=='snare':
      r=135*min(1,t*3)
      for rr,a,w in [(r,225,12),(r-18,110,4),(r+13,70,7)]:ellipse(d,cx,cy+15,rr,rr*.54,col+(int(a*strength),),w)
      for i in range(12):
        a=math.tau*i/12
        x=cx+r*math.cos(a);y=cy+15+r*.54*math.sin(a)
        d.line((x,y,x,y-60*strength),fill=white+(int(120*strength),),width=3)
    elif family=='crown':
      r=135+8*math.sin(t*math.pi*5);ellipse(d,cx,cy+55,r,r*.45,col+(int(140*strength),),7)
      for i in range(17):
        a=math.tau*i/17
        x=cx+r*math.cos(a);y=cy+55+r*.45*math.sin(a)
        h=(80+(i*19)%62)*strength*(.82+.18*math.sin(t*math.pi*7+i*.3))
        d.polygon([(x-8,y),(x,y-h),(x+8,y)],fill=col+(int(165*strength),),outline=white+(int(205*strength),))
    # Soft HDR-like halo is added from the same layer; no enlarged thumbnails.
    blurred=layer.filter(ImageFilter.GaussianBlur(9))
    blurred.putalpha(blurred.getchannel('A').point(lambda x:int(x*.40)))
    result=Image.alpha_composite(blurred,layer)
    alpha_coverage.append(round(sum(1 for b in result.getchannel('A').tobytes() if b>0)/(S*S),4))
    result.save(out/f'frame_{frame:03d}.png',optimize=True)
    frames.append(result)
  atlas=Image.new('RGBA',(S*8,S*2))
  for j,im in enumerate(frames):atlas.paste(im,((j%8)*S,(j//8)*S))
  atlas.save(out/f'{family}_atlas_8x2.png',optimize=True)
  black=[]
  for im in frames:
    b=Image.new('RGBA',im.size,(10,13,22,255));b.alpha_composite(im)
    black.append(b.convert('RGB').quantize(colors=128))
  black[0].save(out/f'{family}_preview.gif',save_all=True,append_images=black[1:],duration=int(1000/FPS),loop=0,optimize=True,disposal=2)
  (out/'metadata.json').write_text(json.dumps({'source':'python procedural offline 2D reference; NOT rendered in Godot','frames':N,'native_frame_px':[S,S],'duration_ms':int(1000/FPS),'atlas_columns':8,'atlas_rows':2,'alpha_coverage_fraction_per_frame':alpha_coverage,'seed':30011,'status':'QA_REFERENCE_ONLY'},indent=2))
  return {'family':family,'frames':N,'empty_frames':sum(x==0 for x in alpha_coverage)}

if __name__=='__main__':
  OUTPUT.mkdir(parents=True,exist_ok=True)
  results=[]
  for p in sorted(RECIPES.glob('*.json')):
    record=json.loads(p.read_text());results.append(run_one(record))
    print('done',record['family'],flush=True)
  (OUTPUT/'manifest.json').write_text(json.dumps(results,indent=2))
