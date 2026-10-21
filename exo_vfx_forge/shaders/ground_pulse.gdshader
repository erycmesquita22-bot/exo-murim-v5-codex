shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never;
uniform vec4 pulse_color : source_color = vec4(0.95,0.6,0.2,0.8);
uniform float opacity : hint_range(0.0,1.0) = 1.0;
void fragment() {
    vec2 uv = UV * 2.0 - vec2(1.0);
    float radius = length(uv);
    float ring = smoothstep(0.66,0.73,radius) * (1.0-smoothstep(0.83,0.90,radius));
    ALBEDO = pulse_color.rgb;
    EMISSION = pulse_color.rgb * 0.65;
    ALPHA = ring * pulse_color.a * opacity;
}
