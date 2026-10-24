shader_type canvas_item;
render_mode unshaded;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;
uniform vec2 center_a = vec2(-2.0,-2.0);
uniform vec2 center_b = vec2(-2.0,-2.0);
uniform float radius_a = 0.11;
uniform float radius_b = 0.11;
uniform float power_a = 0.0;
uniform float power_b = 0.0;
uniform float phase = 0.0;
uniform float aspect = 1.6;
vec2 ripple(vec2 uv, vec2 center, float radius, float power) {
 vec2 p = (uv-center)*vec2(aspect,1.0);
 float d = length(p);
 float u = d / max(radius,0.001);
 float annulus = smoothstep(0.18,0.42,u)*(1.0-smoothstep(0.68,1.08,u));
 float wave = sin(u*28.0-phase*(5.0+power*3.0));
 return normalize(p+vec2(0.00001))*annulus*wave*power*0.0105;
}
void fragment() {
 vec2 offset = ripple(SCREEN_UV,center_a,radius_a,power_a)+ripple(SCREEN_UV,center_b,radius_b,power_b);
 vec2 uv = clamp(SCREEN_UV+offset,vec2(0.001),vec2(0.999));
 COLOR = vec4(texture(screen_texture,uv).rgb,1.0);
}
