shader_type spatial;
render_mode cull_disabled, depth_draw_opaque, diffuse_burley, specular_schlick_ggx;
uniform vec4 deep_color : source_color = vec4(0.11,0.29,0.34,1.0);
uniform vec2 flow_direction = vec2(0.0,1.0);
uniform float flow_sign = 1.0;
uniform float motion_strength : hint_range(0.0,1.0) = 0.55;
uniform float foam_strength : hint_range(0.0,1.0) = 0.35;
uniform float glint_strength : hint_range(0.0,1.0) = 0.2;
uniform float opacity : hint_range(0.0,1.0) = 0.94;
void fragment() {
 float t = TIME * motion_strength * flow_sign;
 // UV.x is the physical channel width and UV.y follows downstream distance.
 // The bank gradient gives the channel a visible edge instead of a flat layer.
 float bank = smoothstep(0.0,0.17,UV.x)*smoothstep(0.0,0.17,1.0-UV.x);
 float stripe = sin(UV.y*7.0-t*2.4+sin(UV.x*16.0+UV.y*1.3))*0.5+0.5;
 float ripple = sin(UV.y*15.0-t*3.1+UV.x*23.0)*0.5+0.5;
 float bank_foam=(1.0-bank)*(0.55+0.45*ripple)*foam_strength;
 float mid_foam=smoothstep(0.78,0.98,stripe*ripple)*foam_strength*0.5;
 vec3 shallows=vec3(0.24,0.43,0.40);
 vec3 water=mix(shallows,deep_color.rgb,bank*0.78)*(0.91+0.12*stripe);
 water+=vec3(0.35,0.42,0.35)*(bank_foam+mid_foam);
 ALBEDO = water;
 ROUGHNESS = mix(0.72,0.26,glint_strength);
 METALLIC = 0.02;
 SPECULAR = 0.1+glint_strength*0.45;
 ALPHA = opacity*(0.72+0.28*bank);
}
