shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;
void fragment() {
 vec2 p=UV*2.0-1.0;
 float edge=pow(clamp(1.0-abs(p.x),0.0,1.0),0.4)*(1.0-smoothstep(0.78,1.0,abs(p.y)));
 float wave=0.5+0.5*sin(p.y*18.0+sin(p.x*8.0-TIME*1.6)*2.0+TIME*2.3);
 ALBEDO=mix(vec3(0.08,0.35,0.42),vec3(0.30,0.85,0.76),wave);
 ALPHA=edge*(0.30+wave*0.22);
}
