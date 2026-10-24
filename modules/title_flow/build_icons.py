from PIL import Image,ImageDraw
from pathlib import Path
import math
OUT=Path(__file__).parent/'icons';OUT.mkdir(exist_ok=True)
S=4
INK=(24,10,12,255);COPPER=(249,109,56,255);GOLD=(255,187,104,255)
def make(name,draw):
 im=Image.new('RGBA',(96*S,96*S),(0,0,0,0));d=ImageDraw.Draw(im)
 draw(d)
 im=im.resize((96,96),Image.Resampling.LANCZOS)
 im.save(OUT/(name+'.png'))
def P(points):return [(int(x*S),int(y*S)) for x,y in points]
def sword(d):
 d.polygon(P([(17,70),(26,79),(37,64),(31,58)]),fill=COPPER,outline=INK,width=4*S)
 d.line(P([(25,72),(65,26)]),fill=INK,width=14*S)
 d.line(P([(25,72),(65,26)]),fill=GOLD,width=7*S)
 d.polygon(P([(57,34),(70,9),(78,9),(77,18),(63,40)]),fill=GOLD,outline=INK,width=4*S)
 d.line(P([(34,57),(17,47)]),fill=INK,width=9*S)
 d.line(P([(34,57),(17,47)]),fill=COPPER,width=4*S)
 d.ellipse((10*S,73*S,21*S,84*S),fill=COPPER,outline=INK,width=3*S)
def gear(d):
 pts=[]
 for i in range(24):
  ang=2*math.pi*i/24-math.pi/2
  rad=39 if i%3 in (0,1) else 29
  pts.append((48+rad*math.cos(ang),48+rad*math.sin(ang)))
 d.polygon(P(pts),fill=COPPER,outline=INK,width=4*S)
 d.ellipse((33*S,33*S,63*S,63*S),fill=INK)
 d.ellipse((39*S,39*S,57*S,57*S),fill=(105,53,35,255),outline=GOLD,width=2*S)
def gate(d):
 d.polygon(P([(11,25),(85,25),(78,37),(18,37)]),fill=COPPER,outline=INK,width=4*S)
 d.polygon(P([(19,17),(77,17),(83,24),(13,24)]),fill=GOLD,outline=INK,width=3*S)
 d.rectangle((23*S,36*S,32*S,82*S),fill=COPPER,outline=INK,width=3*S)
 d.rectangle((64*S,36*S,73*S,82*S),fill=COPPER,outline=INK,width=3*S)
 d.rectangle((18*S,52*S,78*S,60*S),fill=GOLD,outline=INK,width=3*S)
 d.rectangle((14*S,80*S,82*S,86*S),fill=COPPER,outline=INK,width=3*S)
for n,f in [('sword',sword),('gear',gear),('gate',gate)]:make(n,f)
