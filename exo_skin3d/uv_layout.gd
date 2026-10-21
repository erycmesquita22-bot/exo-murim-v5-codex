extends RefCounted
# Minecraft Java 64x64 atlas units. A 256x256 EXO atlas uses the SAME normalized UVs.
const PARTS = {
    "head": {"base": Vector2i(0,0), "outer": Vector2i(32,0), "w":8, "h":8, "d":8},
    "torso": {"base": Vector2i(16,16), "outer": Vector2i(16,32), "w":8, "h":12, "d":4},
    "right_arm": {"base": Vector2i(40,16), "outer": Vector2i(40,32), "w":4, "h":12, "d":4},
    "left_arm": {"base": Vector2i(32,48), "outer": Vector2i(48,48), "w":4, "h":12, "d":4},
    "right_leg": {"base": Vector2i(0,16), "outer": Vector2i(0,32), "w":4, "h":12, "d":4},
    "left_leg": {"base": Vector2i(16,48), "outer": Vector2i(0,48), "w":4, "h":12, "d":4}
}
const FACES = [Vector3.FORWARD,Vector3.BACK,Vector3.RIGHT,Vector3.LEFT,Vector3.UP,Vector3.DOWN]

static func dimensions(part: String, slim: bool=false) -> Vector3i:
    var p: Dictionary=PARTS[part]
    return Vector3i(3 if slim and part.ends_with("_arm") else int(p.w),int(p.h),int(p.d))

static func face_rects(part: String, outer: bool, slim: bool=false, segment: int=-1) -> Array[Rect2]:
    # face order: front, back, right, left, top, bottom. segment 0=upper, 1=lower, -1=entire.
    var d: Vector3i=dimensions(part,slim)
    var o: Vector2=Vector2(PARTS[part]["outer"] if outer else PARTS[part]["base"])
    var y0: float=0.0 if segment!=1 else float(d.y)/2.0
    var side_h: float=float(d.y) if segment==-1 else float(d.y)/2.0
    var rects: Array[Rect2]=[
        Rect2(o+Vector2(d.z,d.z+y0),Vector2(d.x,side_h)),
        Rect2(o+Vector2(d.z+d.x+d.z,d.z+y0),Vector2(d.x,side_h)),
        Rect2(o+Vector2(d.z+d.x,d.z+y0),Vector2(d.z,side_h)),
        Rect2(o+Vector2(0,d.z+y0),Vector2(d.z,side_h)),
        Rect2(o+Vector2(d.z,0),Vector2(d.x,d.z)),
        Rect2(o+Vector2(d.z+d.x,0),Vector2(d.x,d.z))
    ]
    return rects

static func build_box(size: Vector3, part: String, outer: bool=false, slim: bool=false, segment: int=-1) -> ArrayMesh:
    var h: Vector3=size*.5
    # Keep the EXO rig's face orientation unchanged to avoid rotating existing painted faces.
    var faces: Array=[
        [Vector3(-h.x,h.y,-h.z),Vector3(h.x,h.y,-h.z),Vector3(h.x,-h.y,-h.z),Vector3(-h.x,-h.y,-h.z)],
        [Vector3(h.x,h.y,h.z),Vector3(-h.x,h.y,h.z),Vector3(-h.x,-h.y,h.z),Vector3(h.x,-h.y,h.z)],
        [Vector3(h.x,h.y,-h.z),Vector3(h.x,h.y,h.z),Vector3(h.x,-h.y,h.z),Vector3(h.x,-h.y,-h.z)],
        [Vector3(-h.x,h.y,h.z),Vector3(-h.x,h.y,-h.z),Vector3(-h.x,-h.y,-h.z),Vector3(-h.x,-h.y,h.z)],
        [Vector3(-h.x,h.y,h.z),Vector3(h.x,h.y,h.z),Vector3(h.x,h.y,-h.z),Vector3(-h.x,h.y,-h.z)],
        [Vector3(-h.x,-h.y,-h.z),Vector3(h.x,-h.y,-h.z),Vector3(h.x,-h.y,h.z),Vector3(-h.x,-h.y,h.z)]
    ]
    var rects: Array[Rect2]=face_rects(part,outer,slim,segment)
    var st:=SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for f in range(6):
        var r: Rect2=rects[f]
        var uv: Array=[r.position,r.position+Vector2(r.size.x,0),r.end,r.position+Vector2(0,r.size.y)]
        for i in [0,1,2,0,2,3]:
            st.set_normal(FACES[f])
            st.set_uv(uv[i]/64.0)
            st.add_vertex(faces[f][i])
    return st.commit()

static func has_alpha_content(image: Image, part: String, slim: bool=false) -> bool:
    if image==null or image.get_width() not in [64,256] or image.get_height()!=image.get_width():return false
    var factor: int=image.get_width()/64
    for rect in face_rects(part,true,slim):
        var r:=Rect2i(Vector2i(rect.position)*factor,Vector2i(rect.size)*factor)
        for y in range(r.position.y,r.end.y):
            for x in range(r.position.x,r.end.x):
                if image.get_pixel(x,y).a>0.5:return true
    return false
