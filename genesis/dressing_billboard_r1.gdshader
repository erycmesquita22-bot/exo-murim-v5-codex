shader_type spatial;
render_mode skip_vertex_transform, unshaded, cull_disabled, depth_draw_opaque;
// Billboard axial, preserva vertical do cenário isométrico. Um MultiMesh para
// as oito variantes leves do atlas EXO, sem física ou sombras dinâmicas.
uniform sampler2D foliage_atlas : source_color, filter_nearest, repeat_disable;
uniform float wind_strength = 0.022;
varying vec2 atlas_uv;
void vertex() {
 float frame=clamp(floor(INSTANCE_CUSTOM.r*8.0),0.0,7.0);
 atlas_uv=(UV+vec2(mod(frame,4.0),floor(frame/4.0)))/vec2(4.0,2.0);
 vec3 origin=MODEL_MATRIX[3].xyz;
 vec3 cam_right=normalize(vec3(INV_VIEW_MATRIX[0].x,0.0,INV_VIEW_MATRIX[0].z));
 float width=length(MODEL_MATRIX[0].xyz);
 float height=length(MODEL_MATRIX[1].xyz);
 float up=VERTEX.y+0.5;
 float sway=sin(TIME*1.5+origin.x*0.43+origin.z*0.17)*wind_strength*up*up;
 vec3 world_pos=origin+cam_right*(VERTEX.x*width+sway)+vec3(0.0,up*height,0.0);
 VERTEX=(VIEW_MATRIX*vec4(world_pos,1.0)).xyz;
}
void fragment(){
 vec4 pigment=texture(foliage_atlas,atlas_uv);
 ALBEDO=pigment.rgb*COLOR.rgb;
 ALPHA=pigment.a;
 ALPHA_SCISSOR_THRESHOLD=0.52;
 ROUGHNESS=1.0;
}
