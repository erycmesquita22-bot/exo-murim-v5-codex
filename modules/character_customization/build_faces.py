"""Deterministic hand-authored overlays on V4's face UV. Player atlas stays untouched."""
from pathlib import Path
from PIL import Image, ImageDraw
SRC=Path(__file__).parents[1]/'character_core_v3/assets/EXO_Murim_Skin_64UV_x16.png'
OUT=Path(__file__).parent/'faces'
OUT.mkdir(exist_ok=True)
# x/y are the original 1024x1024 atlas pixels, no UV layout changes.
SPEC={
 'river_watch':((0.98,0.94,0.91),(74,79,85),'mole'),
 'river_worker':((0.91,0.87,0.80),(78,65,51),'stubble'),
 'jetty_keeper':((0.99,0.94,0.87),(52,82,75),'freckles'),
 'market_local':((1.03,0.91,0.85),(91,63,59),'freckles'),
 'tea_attendant':((0.98,0.96,0.91),(62,71,83),'smile'),
}
for key,(tone,iris,mark) in SPEC.items():
 im=Image.open(SRC).convert('RGBA')
 px=im.load()
 for y in range(128,256):
  for x in range(128,256):
   r,g,b,a=px[x,y]
   # Warm skin pixels only; dark ink, hair and whites remain the artist's pixels.
   if r>145 and g>105 and b>90 and r>g*1.11 and g>b*1.08:
    px[x,y]=(min(255,round(r*tone[0])),min(255,round(g*tone[1])),min(255,round(b*tone[2])),a)
   # Recolour the small iris centres without touching black outlines.
   if (147<=x<=177 or 210<=x<=240) and 191<=y<=214 and 28<r<105 and 30<g<115 and 35<b<130:
    px[x,y]=(min(255,(r+iris[0])//2),min(255,(g+iris[1])//2),min(255,(b+iris[2])//2),a)
 # Distinct painted front hairlines within the existing illustrated face UV.
 # Only dark fringe pixels are lifted; brows, eyes and skin line art are untouched.
 for x in range(154,239):
  if key=='river_worker': hairline=169+(x//12)%2
  elif key=='jetty_keeper': hairline=174+abs(x-196)//19
  elif key=='market_local': hairline=167+(x-154)//12
  elif key=='tea_attendant': hairline=173+abs(x-196)//16
  else: hairline=174+(x-154)//23
  sample=px[x,190]
  for y in range(hairline,182):
   r,g,b,a=px[x,y]
   if max(r,g,b)<95:
    px[x,y]=(sample[0]-2,sample[1]-2,sample[2]-2,a)
 d=ImageDraw.Draw(im)
 ink=(90,61,58,160)
 if mark=='mole':
  d.ellipse((225,225,227,227),fill=ink)
 elif mark=='stubble':
  for x,y in [(172,233),(179,236),(202,236),(211,233),(183,240),(199,239)]: d.point((x,y),fill=(91,74,67,105))
 elif mark=='freckles':
  for x,y in [(156,222),(161,224),(166,222),(219,222),(224,224),(229,222)]: d.point((x,y),fill=(147,99,82,170))
 elif mark=='smile':
  d.arc((182,228,202,238),0,180,fill=(91,53,58,185),width=1)
 im.save(OUT/(key+'.png'),optimize=True)
 print(key,OUT/(key+'.png'))
