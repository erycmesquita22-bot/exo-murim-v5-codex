shader_type spatial;
render_mode cull_disabled, depth_draw_opaque, diffuse_burley, specular_schlick_ggx;
uniform vec4 deep_color : source_color = vec4(0.11,0.29,0.34,1.0);
uniform vec2 flow_direction = vec2(0.0,1.0);
uniform float motion_strength : hint_range(0.0,1.0) = 0.55;
uniform float foam_strength : hint_range(0.0,1.0) = 0.35;
uniform float glint_strength : hint_range(0.0,1.0) = 0.2;
uniform float opacity : hint_range(0.0,1.0) = 0.94;
void fragment() {
 vec2 dir = normalize(flow_direction + vec2(0.0001,0.0));
 float t = TIME * motion_strength;
 float stripe = sin(dot(UV,dir)*8.0-t*2.5+sin(dot(UV,vec2(-dir.y,dir.x))*4.0))*0.5+0.5;
 float ripple = sin(dot(UV,vec2(-dir.y,dir.x))*15.0 + t*1.5)*0.5+0.5;
 float foam = smoothstep(0.79,0.98,stripe*ripple)*foam_strength;
 vec3 water = deep_color.rgb*(0.88+0.16*stripe)+vec3(0.12,0.18,0.16)*foam;
 ALBEDO = water;
 ROUGHNESS = mix(0.82,0.2,glint_strength);
 METALLIC = 0.02;
 SPECULAR = 0.1+glint_strength*0.45;
 ALPHA = opacity;
}
