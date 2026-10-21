extends RefCounted
## Prefab autoral sob demanda. O WorldGenesis deve reservar uma footprint válida ANTES de colocá-lo.
const Kit=preload("res://exo_dungeon/runtime/architecture_kit.gd")
const Footprint=preload("res://exo_dungeon/integration/entrance_footprint.gd")
static func construct(descriptor: Dictionary,position: Vector3) -> Node3D:
 var family: String=str(descriptor.get("family",""))
 if family not in ["ruins","cavern","temple","sect_hideout","mine","tomb"]:return null
 var root:=Node3D.new()
 root.name="EXO_DungeonEntrance"
 root.add_to_group("exo_dungeon_entrances")
 root.position=position
 root.set_meta("exo_dungeon_return_offset",Vector3(0,1.5,4.0))
 root.set_meta("authoritative_footprint_required",true)
 root.set_meta("exo_footprint_contract",Footprint.request(descriptor,position))
 root.set_meta("exo_dungeon_descriptor",descriptor.duplicate(true))
 root.set_meta("required_clear_radius",10.0 if family in ["temple","ruins","sect_hideout"] else 7.0)
 var stone:=StandardMaterial3D.new();stone.albedo_color=Color("#69717a")
 var wood:=StandardMaterial3D.new();wood.albedo_color=Color("#774e37")
 var accent:=StandardMaterial3D.new();accent.albedo_color=Color("#a9985b")
 # Composição voltada a +Z, deixando abertura caminhável de 3.4 m.
 Kit.prism(root,"EntranceFoundation",Vector3(0,-0.2,0),Vector3(12.0,0.4,7.0),stone)
 if family=="cavern":
  for x in [-4.4,4.4]:
   Kit.prism(root,"CaveMouth",Vector3(x,2.3,0),Vector3(3.6,4.6,3.2),stone)
  Kit.prism(root,"CaveLintel",Vector3(0,4.7,0),Vector3(12.0,1.4,3.2),stone)
 elif family=="mine":
  for x in [-4.0,4.0]:Kit.prism(root,"MineSupport",Vector3(x,2.1,0),Vector3(0.8,4.2,1.2),wood)
  Kit.prism(root,"MineHeader",Vector3(0,4.3,0),Vector3(10.0,0.9,1.2),wood)
 elif family=="tomb":
  for x in [-4.0,4.0]:Kit.prism(root,"TombMonolith",Vector3(x,2.3,0),Vector3(2.0,4.6,2.0),stone)
  Kit.prism(root,"TombArchitrave",Vector3(0,4.75,0),Vector3(10.0,0.9,2.0),accent)
 else:
  for x in [-4.2,4.2]:
   Kit.prism(root,"MurimGatePillar",Vector3(x,2.5,0),Vector3(1.3,5.0,1.3),wood if family=="sect_hideout" else stone)
   Kit.prism(root,"GateRoofEnd",Vector3(x,5.2,0),Vector3(2.8,0.55,2.4),accent)
  Kit.prism(root,"MurimGateRoof",Vector3(0,5.35,0),Vector3(10.6,0.6,3.1),wood)
 if family in ["temple","sect_hideout"]:
  for x in [-6.0,6.0]:Kit.prism(root,"SideShrine",Vector3(x,1.0,3.0),Vector3(2.2,2.0,2.2),stone)
 return root

## Produção: não implanta fachada sem validação autoritativa de WorldGenesis.
static func construct_authorized(descriptor: Dictionary,position: Vector3,worldgen_validator: Callable) -> Dictionary:
 var footprint: Dictionary=Footprint.request(descriptor,position)
 var approved: Dictionary=Footprint.evaluate(footprint,worldgen_validator)
 if not bool(approved.get("ok",false)):return approved
 var facade: Node3D=construct(descriptor,position)
 if facade==null:return {"ok":false,"error":"facade_construction_failed"}
 facade.set_meta("authoritative_footprint_required",false)
 facade.set_meta("return_anchor_verified",approved.placement.return_position)
 return {"ok":true,"node":facade,"reservation":approved.placement}
