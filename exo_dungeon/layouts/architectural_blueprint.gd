extends RefCounted
## Revisão de planta local, NÃO é um segundo gerador de dungeons.
## Máscaras sempre preservam a cruz central de 4 m e os quatro limiares cardinais.
const TILE:=2.0
const FAMILY_PROFILES:={
 "ruins":{"shape":"broken_court","ceiling":5.4,"corridor":"breached_gallery"},
 "cavern":{"shape":"eroded_chamber","ceiling":6.0,"corridor":"winding_tunnel"},
 "temple":{"shape":"axial_sanctuary","ceiling":7.5,"corridor":"covered_walkway"},
 "sect_hideout":{"shape":"barracks_wings","ceiling":5.2,"corridor":"guarded_gallery"},
 "mine":{"shape":"branching_shaft","ceiling":4.5,"corridor":"supported_tunnel"},
 "tomb":{"shape":"processional_crypt","ceiling":6.2,"corridor":"funerary_passage"}
}
static func stable_number(token: String) -> int:
 # Usa hash textual estável, sem avançar o PRNG do gerador ou depender do load order.
 var h: String=token.sha256_text()
 return int(h.substr(0,7).hex_to_int())
static func mask(room: Dictionary,family: String) -> Dictionary:
 var n: int=roundi(float(room.width)/TILE)
 var occupied: Dictionary={}
 var token: String=family+"|"+str(room.id)
 for iz in range(n):
  for ix in range(n):
   var x: float=(float(ix)+0.5)*TILE-float(room.width)*0.5
   var z: float=(float(iz)+0.5)*TILE-float(room.width)*0.5
   var ax: float=absf(x)
   var az: float=absf(z)
   var r: float=float(room.width)*0.5
   var center_path: bool=ax<=2.0 or az<=2.0
   var keep: bool=false
   match family:
    "temple":
     keep=(ax<=r*0.46 and az<=r*0.85) or (az<=r*0.40 and ax<=r*0.90)
    "cavern":
     var jitter: float=float(stable_number(token+"|"+str(ix/2)+"|"+str(iz/2))%31-15)/100.0
     keep=(x*x/(r*r)+z*z/(r*r)) <=(0.82+jitter)
    "tomb":
     keep=(ax<=r*0.42 and az<=r*0.90) or ((az>=r*0.32 and az<=r*0.78) and ax<=r*0.82)
    "sect_hideout":
     keep=(az<=r*0.43 and ax<=r*0.92) or (ax<=r*0.44 and az<=r*0.92) or (x<=-r*0.30 and z<=-r*0.30)
    "mine":
     var branch: int=stable_number(token+"|shaft")%2
     keep=ax<=r*0.37 or az<=r*0.32 or (x>0 and z>0 and branch==0 and az<=r*0.70) or (x<0 and z<0 and branch==1 and ax<=r*0.70)
    "ruins":
     keep=(ax<=r*0.76 and az<=r*0.76) and not (x>r*0.2 and z>r*0.2 and stable_number(token+"|missing")%3!=0)
    _:
     keep=true
   # Entradas e centro sempre caminháveis; bloqueios ficam SOMENTE nos links.
   keep=keep or center_path
   if keep:occupied[Vector2i(ix,iz)]=true
 return {"tiles":occupied,"n":n,"tile":TILE,"shape":str(FAMILY_PROFILES.get(family,{}).get("shape","chamber"))}
static func connected(mask_data: Dictionary) -> bool:
 var cells: Dictionary=mask_data.tiles
 if cells.is_empty():return false
 var first: Vector2i=cells.keys()[0]
 var visited: Dictionary={first:true}
 var pending: Array[Vector2i]=[first]
 var index: int=0
 while index<pending.size():
  var p: Vector2i=pending[index]
  index+=1
  for d in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
   var next: Vector2i=p+d
   if cells.has(next) and not visited.has(next):
    visited[next]=true
    pending.append(next)
 return visited.size()==cells.size()
static func contour_segments(data: Dictionary,doors: Dictionary) -> Array:
 # Bordas em trechos de 2 metros; vãos de 4 metros no eixo cardinal.
 var result: Array=[]
 var cells: Dictionary=data.tiles
 var n: int=int(data.n)
 for tile in cells.keys():
  var x: int=tile.x
  var z: int=tile.y
  for rule in [{"side":"north","dir":Vector2i.UP},{"side":"south","dir":Vector2i.DOWN},{"side":"west","dir":Vector2i.LEFT},{"side":"east","dir":Vector2i.RIGHT}]:
   var direction: Vector2i=rule.dir
   if cells.has(tile+direction):continue
   var side: String=rule.side
   var center_index: int=z if side in ["east","west"] else x
   var mouth: bool=absf((float(center_index)+0.5)-float(n)*0.5)<=1.01
   if mouth and bool(doors.get(side,false)):continue
   result.append({"x":x,"z":z,"side":side})
 return result
static func corridor_profile(family: String,edge_id: String,locked: bool) -> Dictionary:
 var regular: bool=locked
 var value: int=stable_number(family+"|"+edge_id)
 var width: float=4.0 if value%5>0 else 6.0
 return {"width":width,"bend":0 if regular or value%4==0 else (2 if value%2==0 else -2),"landmark":value%3==0,"style":FAMILY_PROFILES.get(family,{}).get("corridor","gallery")}
