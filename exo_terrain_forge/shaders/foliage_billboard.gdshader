shader_type spatial;
render_mode skip_vertex_transform, unshaded, cull_disabled, depth_draw_opaque;
uniform sampler2D atlas : source_color, filter_linear_mipmap, repeat_disable;
uniform float wind_strength = 0.019;
varying vec2 tile_uv;
void vertex(){
 float frame=clamp(floor(INSTANCE_CUSTOM.r*16.0),0.0,15.0);
 // 4x4 sprite atlas: 256px content + 8px true transparent gutters
 vec2 cell=vec2(mod(frame,4.0),floor(frame/4.0));
 tile_uv=(cell*272.0+vec2(8.5)+UV*255.0)/vec2(1088.0,1088.0);
 vec3 origin=MODEL_MATRIX[3].xyz;
 vec3 cam_right=normalize(vec3(INV_VIEW_MATRIX[0].x,0.0,INV_VIEW_MATRIX[0].z));
 float width=length(MODEL_MATRIX[0].xyz);
 float height=length(MODEL_MATRIX[1].xyz);
 float up=VERTEX.y+0.5;
 float sway=sin(TIME*1.21+origin.x*0.31+origin.z*0.17)*wind_strength*up*up;
 vec3 world_p=origin+cam_right*(VERTEX.x*width+sway)+vec3(0.0,up*height,0.0);
 VERTEX=(VIEW_MATRIX*vec4(world_p,1.0)).xyz;
}
void fragment(){
 vec4 texel=texture(atlas,tile_uv);
 ALBEDO=texel.rgb*COLOR.rgb;
 ALPHA=texel.a;
 ALPHA_SCISSOR_THRESHOLD=0.42;
 ROUGHNESS=1.0;
}
