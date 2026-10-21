extends RefCounted
# EXO owner-attested FighterArt palettes; sources/history promised, see docs/v5/drive-provenance.json.
const SKIN_COLORS = ["efd5be", "dbb399", "c79670", "a77853", "7b503d", "4e352c"]
const CLOTH_COLORS = ["303744", "365987", "3b6956", "963f49", "dedbd0", "695183"]
const HAIR_COLORS = ["25242b", "4c352d", "9c5135", "c9aa63", "d8d8d3", "344a76"]
const EYE_COLORS = ["53727b", "71533b", "438d9d", "4d805c", "a67b3c", "7a6097"]
const BODY_SCALE = [
    Vector3(1,1,1), Vector3(.86,.86,.86), Vector3(.95,1.14,.95),
    Vector3(1.18,1.02,1.10), Vector3(.82,1.02,.85),
    Vector3(1.12,.90,1.08), Vector3(1.15,1.15,1.15)
]

static func rect(image: Image, x: float, y: float, w: float, h: float, color: Color) -> void:
    # Original FighterArt uses units on a 64x64 layout and paints at 4x.
    var box := Rect2i(roundi(x*4), roundi(y*4), maxi(1, roundi(w*4)), maxi(1, roundi(h*4)))
    image.fill_rect(box, color)

static func line(image: Image, a: Vector2, b: Vector2, color: Color) -> void:
    var steps: int = maxi(1, ceili(maxf(absf(b.x-a.x),absf(b.y-a.y))*4))
    for i in range(steps+1):
        var p: Vector2 = a.lerp(b,float(i)/float(steps))
        rect(image,p.x,p.y,.25,.25,color)

static func paint(profile: Dictionary) -> Image:
    var skin_index: int = clampi(int(profile.get("skin",0)),0,5)
    var robe_index: int = clampi(int(profile.get("robe",0)),0,5)
    var hair_index: int = clampi(int(profile.get("hair",0)),0,5)
    var skin := Color(SKIN_COLORS[skin_index])
    var cloth := Color(CLOTH_COLORS[robe_index])
    var hair := Color(HAIR_COLORS[hair_index])
    var palette: int = skin_index + robe_index * 6 + hair_index * 36
    var source: Texture2D = load("res://assets/exo_identity/base_%d.png" % palette)
    var image: Image = source.get_image() if source != null else tailored_base(skin, cloth, hair)
    image.convert(Image.FORMAT_RGBA8)
    var eyes := Color(EYE_COLORS[clampi(int(profile.get("eye_color",0)),0,5)])
    var cut: int = clampi(int(profile.get("haircut",0)),0,3)
    var shape: int = clampi(int(profile.get("eyes",0)),0,3)
    var mark: int = clampi(int(profile.get("mark",0)),0,2)
    var muscle: int = clampi(int(profile.get("muscles",0)),0,2)
    var outfit: int = clampi(int(profile.get("outfit",0)),0,3)
    # Dress styles are actual UV changes, not inert menu switches.
    if outfit == 1: # training shirt
        rect(image,20,20,8,2,skin)
        rect(image,20,22,8,1,cloth.darkened(.20))
        for arm in [Vector2(40,16),Vector2(32,48)]:
            rect(image,arm.x+4,arm.y+4,4,5,cloth.darkened(.20))
    elif outfit == 2: # uncovered martial upper body; muscle marks on texture
        rect(image,20,20,8,9,skin)
        rect(image,32,20,4,9,skin.darkened(.08))
        rect(image,44,20,4,9,skin)
        rect(image,36,52,4,9,skin.darkened(.06))
        rect(image,48,52,4,9,skin)
        rect(image,40,20,4,9,skin)
    elif outfit == 3: # layered tunic
        rect(image,20,20,8,9,cloth.darkened(.13))
        line(image,Vector2(21,20),Vector2(25,25),cloth.lightened(.45))
        line(image,Vector2(27,20),Vector2(23,25),cloth.lightened(.35))
    # Repaint face from the owner's palette so cut/iris/mark selections truly show.
    rect(image,8,10.25,8,5.45,skin)
    if cut == 0:
        rect(image,8,9,1.25,2.4,hair)
        rect(image,14.75,9,1.25,2.4,hair)
    elif cut == 1:
        for i in range(5):
            rect(image,8+i*1.5,9,1,1.5+float(i%2)*.6,hair)
    elif cut == 2:
        for i in range(20):
            var x: float = 8.0+float(i)*.25
            rect(image,x,9,.25,maxf(.25,3.5-float(i)*.15),hair)
        rect(image,15,9,1,3,hair)
    else:
        rect(image,8,9,8,.5,hair)
    var eye_height: float = .65 if shape == 1 else .85 if shape == 2 else 1.25 if shape == 3 else 1.0
    for x in [9.0,13.0]:
        rect(image,x,11.35,2,eye_height,Color("e7e5db"))
        rect(image,x+.65,11.35,.7,eye_height,eyes)
        rect(image,x+.85,11.50,.3,maxf(.3,eye_height-.15),Color("20262b"))
        rect(image,x+.7,11.35,.25,.25,Color("f2f2df"))
        line(image,Vector2(x,10.85),Vector2(x+1.75,11.1 if shape==2 else 10.7),hair)
    line(image,Vector2(11.8,12.6),Vector2(11.8,13.15),skin.darkened(.17))
    line(image,Vector2(11.1,14),Vector2(12.9,14),skin.darkened(.32))
    if mark == 1:
        line(image,Vector2(14,10.5),Vector2(13.5,13.3),skin.darkened(.36))
    elif mark == 2:
        for i in range(8):
            for j in range(13):
                var x: float = 9.6+float(j)*.4
                var y: float = 13.9+float(i)*.22
                if y>14.5 or x<10.5 or x>13.5:
                    rect(image,x,y,.2,.2,hair.darkened(.12))
    if muscle > 0:
        var shadow := skin.darkened(.18 if muscle==1 else .30)
        if outfit == 2:
            line(image,Vector2(21,22),Vector2(23.4,22.6),shadow)
            line(image,Vector2(24.6,22.6),Vector2(27,22),shadow)
            line(image,Vector2(24,23.8),Vector2(24,28.3),shadow)
            for i in range(3):
                var y: float=24.4+float(i)*1.25
                line(image,Vector2(21.8,y),Vector2(23.5,y+.15),shadow)
                line(image,Vector2(24.5,y+.15),Vector2(26.2,y),shadow)
        for arm in [Vector2(40,16),Vector2(32,48)]:
            var y: float=arm.y+(9 if outfit==0 else 5)
            line(image,Vector2(arm.x+4.8,y),Vector2(arm.x+5.2,y+2),shadow)
            line(image,Vector2(arm.x+7.1,y),Vector2(arm.x+6.7,y+2),shadow)
    return image

# Editable project-authored UV tailoring. No legacy mod pixels are read.
# Each cube face occupies the classic Minecraft net; outer layers stay transparent.
static func tailored_base(skin: Color, cloth: Color, hair: Color) -> Image:
    var image := Image.create(256,256,false,Image.FORMAT_RGBA8)
    image.fill(Color.TRANSPARENT)
    var parts: Array = [
        [0,0,8,8,8,skin], [16,16,8,12,4,cloth],
        [40,16,4,12,4,skin], [32,48,4,12,4,skin],
        [0,16,4,12,4,cloth.darkened(.27)], [16,48,4,12,4,cloth.darkened(.27)]]
    for part in parts:
        var u: int=part[0];var v: int=part[1];var w: int=part[2];var h: int=part[3];var d: int=part[4]
        var tint: Color=part[5]
        var faces: Array=[Rect2(u+d,v,w,d),Rect2(u+d+w,v,w,d),Rect2(u,v+d,d,h),Rect2(u+d,v+d,w,h),Rect2(u+d+w,v+d,d,h),Rect2(u+d+w+d,v+d,w,h)]
        for f: Rect2 in faces:
            rect(image,f.position.x,f.position.y,f.size.x,f.size.y,tint)
            # Seams and flat voxel shading follow each face, rather than a
            # single rectangle that spills clothes across unrelated UV parts.
            rect(image,f.position.x,f.position.y,.25,f.size.y,tint.darkened(.12))
            rect(image,f.position.x,f.end.y-.25,f.size.x,.25,tint.darkened(.18))
            rect(image,f.position.x+.25,f.position.y,f.size.x-.5,.25,tint.lightened(.09))
    # Back, sides and crown of the hairstyle.
    rect(image,8,0,8,8,hair)
    rect(image,0,8,8,6,hair.darkened(.12))
    rect(image,16,8,8,6,hair.darkened(.12))
    rect(image,24,8,8,8,hair)
    rect(image,8,8,8,2,hair)
    # Tailored sleeves, cuffs and wraps on both arms, all four vertical faces.
    for origin: Vector2 in [Vector2(40,16),Vector2(32,48)]:
        rect(image,origin.x,origin.y+4,16,5,cloth)
        rect(image,origin.x,origin.y+8.5,16,.5,cloth.lightened(.28))
        for stripe in range(3):
            rect(image,origin.x,origin.y+11+float(stripe)*.6,16,.3,Color("d2c6aa"))
    # Trousers and boots preserve left/right limb UV and knee articulation.
    for origin: Vector2 in [Vector2(0,16),Vector2(16,48)]:
        rect(image,origin.x,origin.y+13,16,3,Color("373335"))
        rect(image,origin.x,origin.y+12.5,16,.5,Color("b4a78b"))
        for x in [4.5,7.0,12.5]:
            rect(image,origin.x+x,origin.y+5,.25,6,cloth.darkened(.43))
    # Full belt front/sides/back with jade clasp and folded lapels.
    rect(image,16,28,24,2,cloth.darkened(.58))
    rect(image,23,28.25,2,1.25,Color("c8ac68"))
    rect(image,23.5,28.5,1,.75,Color("5b9a80"))
    line(image,Vector2(20,20),Vector2(25,26),Color("e1d5b7"))
    line(image,Vector2(28,20),Vector2(23,26),Color("c8ac68"))
    for x in [20.5,22.5,26.5]:
        line(image,Vector2(x,26.5),Vector2(x+.5,27.75),cloth.darkened(.22))
    return image
