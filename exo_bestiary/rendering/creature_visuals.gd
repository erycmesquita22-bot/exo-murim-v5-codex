extends Node3D
# Malhas voxel inéditas geradas neste módulo; nenhum asset externo usado.
var leg_pivots: Array[Node3D] = []
var tail_pivot: Node3D
var family: String = ""
var style: int = 0
var body_color: Color
const PALETTES: Dictionary = {"cervid":["93633f","c19668","5a6b49","9e8054"],"small_quadruped":["bf9c77","ded7c4","8f715e","7d5d42"],"caprine":["b8a18a","ded1b1","a78b65","c6ba9d"],"bovine":["72513d","8b6b4c","5e5340","987a59"],"boar":["5d3e2d","755139","8d6742","514b3b"],"ursine":["694736","8b694e","4d4136","665b42"],"canid":["7f887c","86664d","5b6662","a08b60"],"feline":["b57d41","d6a05b","bd9054","b1784c"],"serpent":["498d62","5d936f","557e99","a7a15b"]}
func build(profile: Dictionary, palette_index: int = 0) -> void:
    for child in get_children(): remove_child(child);child.queue_free()
    leg_pivots.clear()
    tail_pivot=null
    family = str(profile.get("visual_family","canid"))
    var palette: Array = PALETTES.get(family,PALETTES["canid"])
    style = posmod(palette_index,palette.size())
    body_color=Color(str(palette[style]))
    var dim := 1.0
    var stats: Dictionary = profile.get("stats",{})
    dim = clampf(float(stats.get("size",1.0)),.45,1.7)
    scale = Vector3.ONE * dim
    var broad := 1.12 if family in ["bovine","ursine","boar"] else .73 if family in ["small_quadruped","serpent"] else 1.0
    if family=="serpent":
        for i in range(6):
            _cube("coil%d"%i,Vector3(0,0.31+float(i%2)*.05,-.42+float(i)*.28),Vector3(.53-float(i)*.05,.28,.37),body_color.darkened(.07*float(i)))
        _cube("head",Vector3(0,.48,-.80),Vector3(.53,.36,.47),body_color.lightened(.12))
        _cube("eye_left",Vector3(-.25,.55,-.94),Vector3(.06,.08,.08),Color("eee6b2"))
        _cube("eye_right",Vector3(.25,.55,-.94),Vector3(.06,.08,.08),Color("eee6b2"))
        return
    _cube("torso",Vector3(0,.91,0),Vector3(1.1*broad,.87,1.65),body_color)
    _cube("back",Vector3(0,1.37,.12),Vector3(.84*broad,.24,1.05),body_color.lightened(.10))
    _cube("neck",Vector3(0,1.19,-.71),Vector3(.71,.87,.63),body_color)
    _cube("head",Vector3(0,1.50,-1.02),Vector3(.78,.65,.72),body_color.lightened(.06))
    _cube("muzzle",Vector3(0,1.27,-1.44),Vector3(.51,.33,.42),body_color.darkened(.1))
    for side in [-1,1]:
        _cube("ear",Vector3(float(side)*.38,1.89,-1.04),Vector3(.21,.28,.25),body_color)
        _cube("eye",Vector3(float(side)*.40,1.56,-1.24),Vector3(.055,.08,.13),Color("242524"))
        if family in ["boar","caprine","bovine","cervid"]:
            _cube("horn",Vector3(float(side)*.32,2.02,-1.08),Vector3(.13,.32,.16),Color("e8d7b2"))
    for side in [-1,1]:
        for front in [-1,1]:
            var pivot:=Node3D.new();pivot.name="leg_pivot";pivot.position=Vector3(float(side)*.37*broad,.68,float(front)*.57)
            add_child(pivot)
            _cube_at(pivot,"leg",Vector3(0,-.30,0),Vector3(.27,.67,.30),body_color.darkened(.13))
            _cube_at(pivot,"hoof",Vector3(0,-.61,-.04),Vector3(.32,.15,.37),Color("48423b"))
            leg_pivots.append(pivot)
    tail_pivot=Node3D.new();tail_pivot.position=Vector3(0,1.18,.82);add_child(tail_pivot)
    _cube_at(tail_pivot,"tail",Vector3(0,-.04,.26),Vector3(.25,.30,.65),body_color.darkened(.18))
    if family in ["feline","canid"]:
        _cube("chest_marking",Vector3(0,.93,-.84),Vector3(.46,.52,.07),body_color.lightened(.2))
func _cube(n: String,p: Vector3,size: Vector3,color: Color) -> void:
    _cube_at(self,n,p,size,color)
func _cube_at(parent: Node3D,n: String,p: Vector3,size: Vector3,color: Color) -> void:
    var node:=MeshInstance3D.new();node.name=n;node.position=p
    var mesh:=BoxMesh.new();mesh.size=size;node.mesh=mesh
    var mat:=StandardMaterial3D.new();mat.albedo_color=color;mat.roughness=1.0;mat.texture_filter=BaseMaterial3D.TEXTURE_FILTER_NEAREST
    node.material_override=mat
    parent.add_child(node)
