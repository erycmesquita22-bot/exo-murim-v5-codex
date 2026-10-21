shader_type spatial;
render_mode cull_disabled, diffuse_burley;
uniform float wind_strength : hint_range(0.0,1.0) = 0.08;
uniform float wind_speed : hint_range(0.0,4.0) = 1.0;
void vertex() {
 // The roots remain fixed; only blades with positive local height move.
 float tip = smoothstep(0.015, 0.28, VERTEX.y);
 vec3 world = (MODEL_MATRIX * vec4(VERTEX,1.0)).xyz;
 float phase = world.x*0.21 + world.z*0.17 + TIME*wind_speed;
 VERTEX.x += sin(phase)*wind_strength*tip;
 VERTEX.z += cos(phase*0.71)*wind_strength*0.65*tip;
}
void fragment() {
 ALBEDO = COLOR.rgb;
 ROUGHNESS = 1.0;
}
