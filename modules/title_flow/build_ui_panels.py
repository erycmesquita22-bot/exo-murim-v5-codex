"""Authored 9-slice UI surfaces; copper/ink vocabulary of the supplied menu."""
from PIL import Image,ImageDraw,ImageFilter
from pathlib import Path
import random,math
R=Path(__file__).parent/'ui';R.mkdir(exist_ok=True)
random.seed(17)

def panel():
 w,h=768,512
 im=Image.new('RGBA',(w,h));shadow=Image.new('RGBA',(w,h));d=ImageDraw.Draw(shadow)
 d.rounded_rectangle((29,28,w-16,h-12),radius=28,fill=(6,3,5,220))
 im.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(17)))
 d=ImageDraw.Draw(im)
 d.rounded_rectangle((21,18,w-22,h-24),radius=24,fill=(37,20,20,248),outline=(17,7,9,255),width=8)
 d.rounded_rectangle((28,25,w-29,h-31),radius=19,outline=(235,150,81,255),width=4)
 d.rounded_rectangle((33,30,w-34,h-36),radius=17,outline=(92,43,28,255),width=7)
 d.rounded_rectangle((41,38,w-42,h-44),radius=13,fill=(44,23,25,231),outline=(19,10,14,255),width=2)
 # Warm paper translucency, shaded toward the lower right.
 lay=Image.new('RGBA',(w,h));q=ImageDraw.Draw(lay)
 for y in range(43,h-48):
  t=(y-43)/(h-91)
  q.line((44,y,w-45,y),fill=(53-int(t*17),29-int(t*11),26-int(t*7),int(95+t*45)))
 im.alpha_composite(lay)
 d=ImageDraw.Draw(im)
 d.line((43,45,w-45,45),fill=(251,185,105,155),width=2)
 d.line((45,47,45,h-51),fill=(250,164,91,80),width=2)
 d.line((w-45,48,w-45,h-50),fill=(5,4,5,120),width=3)
 d.line((45,h-49,w-46,h-49),fill=(6,4,5,150),width=3)
 for x in [42,w-42]:
  for y in [40,h-47]:
   d.ellipse((x-8,y-8,x+8,y+8),fill=(101,54,31,255),outline=(255,194,110,255),width=2)
   d.ellipse((x-2,y-2,x+2,y+2),fill=(29,14,13,255))
 # Restrained wood scratches along the frame, stable generation.
 for _ in range(90):
  x=random.randint(48,w-58);y=random.choice([random.randint(26,35),random.randint(h-45,h-34)])
  d.line((x,y,x+random.randint(5,22),y),fill=(13,7,8,80),width=1)
 im.save(R/'wood_panel.png',optimize=True)

def plaque(name,light):
 w,h=520,84
 im=Image.new('RGBA',(w,h));d=ImageDraw.Draw(im)
 dark=(38,18,20,247) if name!='pressed' else (27,12,15,250)
 border=(209,130,69,255) if name!='disabled' else (92,82,78,255)
 if name=='hover': dark=(79,30,26,248);border=(255,198,111,255)
 if name=='disabled': dark=(30,26,27,225)
 y0=4 if name!='pressed' else 8
 d.rounded_rectangle((3,y0+4,w-4,h-3),radius=16,fill=(8,3,5,210))
 d.rounded_rectangle((4,y0,w-5,h-9),radius=15,fill=(78,39,27,255),outline=(19,8,10,255),width=3)
 d.rounded_rectangle((9,y0+4,w-10,h-15),radius=11,fill=dark,outline=border,width=3)
 d.line((24,y0+8,w-25,y0+8),fill=light,width=2)
 d.line((25,h-20,w-26,h-20),fill=(4,3,4,170),width=3)
 d.line((13,y0+14,13,h-24),fill=(255,190,112,100),width=2)
 d.line((w-14,y0+14,w-14,h-24),fill=(3,1,3,140),width=3)
 for x in [23,w-24]:
  d.ellipse((x-5,30,x+5,40),fill=(31,12,12,255),outline=border,width=2)
 for _ in range(34):
  x=random.randint(37,w-50);y=random.randint(y0+12,h-24)
  d.line((x,y,x+random.randint(3,20),y),fill=(213,106,65,19 if name!='hover' else 35),width=1)
 im.save(R/(name+'.png'),optimize=True)
panel()
plaque('normal',(255,191,115,150));plaque('hover',(255,221,143,240));plaque('pressed',(135,70,47,140));plaque('disabled',(112,88,75,90))
