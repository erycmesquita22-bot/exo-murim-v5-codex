shader_type spatial;
render_mode blend_mix, cull_disabled, depth_draw_opaque, diffuse_burley;

uniform vec4 water_color : source_color = vec4(0.72, 0.86, 0.94, 0.78);
uniform vec4 foam_color : source_color = vec4(0.95, 0.98, 1.0, 0.84);
uniform float flow_speed : hint_range(0.1, 3.0) = 1.2;
uniform float turbulence : hint_range(0.0, 1.0) = 0.55;
uniform float alpha_strength : hint_range(0.0, 1.0) = 0.78;

varying vec2 uv_pass;

void vertex() {
    uv_pass = UV;
    float wiggle = sin((UV.y * 8.0 + TIME * flow_speed * 2.0) + VERTEX.x * 1.3) * 0.06 * turbulence;
    VERTEX.x += wiggle * (1.0 - UV.y * 0.4);
}

void fragment() {
    vec2 uv = uv_pass;
    float streak = sin((uv.y * 16.0 + TIME * flow_speed * 5.0) + uv.x * 9.0) * 0.5 + 0.5;
    float fine = sin((uv.y * 32.0 + TIME * flow_speed * 8.0) - uv.x * 14.0) * 0.5 + 0.5;
    float foam = smoothstep(0.72, 1.0, streak * 0.6 + fine * 0.4 + (1.0 - uv.y) * 0.35);
    ALBEDO = mix(water_color.rgb, foam_color.rgb, foam);
    ROUGHNESS = 0.15;
    SPECULAR = 0.78;
    ALPHA = alpha_strength * clamp(0.4 + streak * 0.5 + foam * 0.2, 0.0, 1.0);
}
