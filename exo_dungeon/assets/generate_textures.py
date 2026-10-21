#!/usr/bin/env python3
"""100% procedural pixel textures authored for EXO-Murim; no source assets."""
from PIL import Image,ImageDraw
from pathlib import Path
import random
DEST=Path(__file__).resolve().parent/'materials';DEST.mkdir(exist_ok=True)
variants={'stone_tile':(160,164,155),'timber_grain':(151,114,78),'temple_paving':(178,157,122),'cave_rock':(104,118,105),'tomb_relief':(136,129,139),'roof_tile':(163,85,60)}
for index,(name,base) in enumerate(variants.items()):
 rng=random.Random(0xE20A+index*1103)
 im=Image.new('RGB',(64,64));p=im.load()
 for y in range(64):
  for x in range(64):
   n=rng.randrange(-12,13)
   if name=='timber_grain':n+=(3 if y%11<=1 else -1)+(6 if (x+4*y)%27<2 else 0)
   elif name in ('stone_tile','temple_paving','tomb_relief'):
    tile=(x+(8 if y//16%2 else 0))%20
    n+=(-23 if y%16==0 or tile==0 else (5 if tile%9==1 else 0))
   elif name=='cave_rock':n+=(-9 if (x*3+y*2)%17<4 else 2)
   elif name=='roof_tile':n+=(-17 if y%9==0 or (x+y//9*6)%16==0 else 7)
   p[x,y]=tuple(max(0,min(255,a+n)) for a in base)
 im.save(DEST/(name+'.png'),optimize=True)
 print(name, (DEST/(name+'.png')).stat().st_size)
