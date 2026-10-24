"""Painted NPC-only variants of the approved V4 face atlas. Never changes source UV or GLB."""
from pathlib import Path
from PIL import Image, ImageDraw
ROOT=Path(__file__).resolve().parents[1]
SRC=ROOT/'character_core_v3/assets/EXO_Murim_Skin_64UV_x16.png'
OUT=Path(__file__).parent/'npc_faces';OUT.mkdir(exist_ok=True)
# Skin pigment, front hair pigment, iris pigment, illustrated age/expression detail.
SPEC={
'young_ash':((1.03,1.00,.97),'#30343b','#566f79','soft'),
'young_chestnut':((1.02,.97,.91),'#6c4734','#70584c','freckles'),
'young_black':((.98,.93,.88),'#252a33','#424e65','bright'),
'adult_auburn':((.96,.88,.82),'#70443d','#70524e','stern'),
'adult_black':((.98,.95,.91),'#343139','#455865','stern'),
'adult_brown':((.91,.86,.78),'#524034','#76604a','smile'),
'weathered':((.87,.79,.68),'#493a33','#6d5b50','weathered'),
'guard_broad':((.89,.84,.76),'#2c3032','#59606b','scar'),
'elder_silver':((1.02,.96,.89),'#b8b7a9','#696d75','elder'),
'elder_beard':((.91,.87,.80),'#c3c1b0','#5b6470','beard'),
'elder_ash':((.94,.90,.85),'#858684','#6a6e75','elder'),
'herbalist_grey':((.96,.91,.84),'#979185','#667368','smile_lines'),
'river_tan':((.84,.81,.75),'#474344','#5b6571','weathered'),
'scholar':((1.04,.99,.92),'#35373d','#6d7373','fine'),
}
for name,(tone,hair_hex,iris_hex,detail) in SPEC.items():
    im=Image.open(SRC).convert('RGBA');px=im.load()
    hair=tuple(bytes.fromhex(hair_hex[1:]));iris=tuple(bytes.fromhex(iris_hex[1:]))
    for y in range(128,256):
        for x in range(128,256):
            r,g,b,a=px[x,y]
            if r>145 and g>105 and b>90 and r>g*1.11 and g>b*1.08:
                px[x,y]=(min(255,round(r*tone[0])),min(255,round(g*tone[1])),min(255,round(b*tone[2])),a)
            elif (y<187 or x<150 or x>241) and max(r,g,b)<115 and b>=r*.75:
                luminance=max(.48,min(1.25,(r+g+b)/110))
                px[x,y]=tuple(min(255,int(c*luminance)) for c in hair)+(a,)
            if (151<=x<=178 or 210<=x<=239) and 191<=y<=214 and 28<r<105 and 30<g<115 and 35<b<130:
                px[x,y]=(int((r+iris[0])/2),int((g+iris[1])/2),int((b+iris[2])/2),a)
    # The approved hair mesh uses four other UV islands: ponytail, left/right
    # locks and the back overlay. Repaint their inked pixels to match the face.
    for x0,y0,x1,y1 in [(128,0,384,128),(0,128,128,256),(256,128,512,256),(640,128,768,256)]:
        for y in range(y0,y1):
            for x in range(x0,x1):
                r,g,b,a=px[x,y]
                if 24<r+g+b<330 and max(r,g,b)<115 and b>=r*.75:
                    luminance=max(.50,min(1.24,(r+g+b)/110))
                    px[x,y]=tuple(min(255,int(c*luminance)) for c in hair)+(a,)
    d=ImageDraw.Draw(im,'RGBA')
    wrinkle=(92,65,61,90);deep=(65,49,48,140);light=(239,201,184,95)
    if detail in ('elder','beard','weathered','smile_lines'):
        for cx,sgn in [(155,-1),(238,1)]:
            d.arc((cx-8,209,cx+8,224),15 if sgn<0 else 155,95 if sgn<0 else 245,fill=wrinkle,width=1)
            d.arc((cx-6,216,cx+10,233),25 if sgn<0 else 150,95 if sgn<0 else 235,fill=wrinkle,width=1)
        d.arc((179,181,207,189),182,355,fill=wrinkle,width=1)
        d.arc((179,184,207,192),182,355,fill=(101,73,67,62),width=1)
    if detail in ('elder','beard','smile_lines'):
        d.arc((159,220,177,232),50,155,fill=wrinkle,width=1)
        d.arc((211,220,229,232),25,130,fill=wrinkle,width=1)
    if detail=='beard':
        for y in range(236,253):
            for x in range(170,215):
                if ((x-192)/22)**2+((y-238)/20)**2<1 and (x+y)%5!=0:
                    r,g,b,a=px[x,y]
                    if r>135 and g>95 and b>80: px[x,y]=(int((r+hair[0])/2),int((g+hair[1])/2),int((b+hair[2])/2),a)
        d.arc((172,228,211,250),8,174,fill=(109,102,95,140),width=1)
    if detail=='scar':d.line([(218,180),(216,186),(212,191)],fill=(168,104,96,150),width=1)
    if detail=='freckles':
        for x,y in [(155,218),(160,220),(166,219),(220,219),(226,221),(231,218)]:d.point((x,y),fill=(127,78,61,190))
    if detail in ('stern','weathered','guard_broad'):
        d.line([(153,188),(174,186)],fill=deep,width=1);d.line([(211,186),(235,188)],fill=deep,width=1)
    if detail in ('soft','bright','fine'):d.arc((181,227,203,239),5,175,fill=light,width=1)
    if detail=='smile':d.arc((181,227,204,239),3,178,fill=(82,52,54,130),width=1)
    im.save(OUT/(name+'.png'),optimize=True)
    print(name)
