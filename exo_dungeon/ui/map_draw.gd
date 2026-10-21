extends RefCounted
static func snapshot(world:Node3D)->Dictionary:
 if not world.has_method("_dungeon_inside") or not world._dungeon_inside():return {}
 return world.exo_core.services.invoke("dungeons","map_snapshot")
static func draw_map(surface:Control,state:Dictionary,center:Vector2,radius:float)->void:
 surface.draw_circle(center,radius,Color("12161c"))
 var scale:float=radius/48.0
 var player:Vector2=state.player
 for link in state.links:
  var a:Vector2=(link.a-player)*scale
  var b:Vector2=(link.b-player)*scale
  if a.length()<radius-3 and b.length()<radius-3:surface.draw_line(center+a,center+b,Color("a08a64"),2)
 for room in state.rooms:
  var at:Vector2=(Vector2(room.x,room.z)-player)*scale
  var width:float=float(room.width)*scale
  if at.length()+width*0.72>radius-2:continue
  surface.draw_rect(Rect2(center+at-Vector2.ONE*width/2,Vector2.ONE*width),Color("43544e"))
  surface.draw_rect(Rect2(center+at-Vector2.ONE*width/2,Vector2.ONE*width),Color("a08a64"),false,1)
 surface.draw_circle(center,4,Color("49d1c0"))
 surface.draw_string(ThemeDB.fallback_font,center+Vector2(-35,radius-12),"Andar %d"%int(state.floor),HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("dfd7b9"))
