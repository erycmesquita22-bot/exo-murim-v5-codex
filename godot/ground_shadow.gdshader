shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;
void fragment(){
 vec2 p=abs(UV-vec2(0.5))*2.0;
 float d=max(p.x,p.y);
 ALBEDO=vec3(0.12,0.14,0.13);
 ALPHA=(1.0-smoothstep(0.5,1.0,d))*0.19;
}
