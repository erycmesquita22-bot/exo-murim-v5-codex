shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never;
uniform vec4 tint : source_color = vec4(0.25, 0.65, 1.0, 0.75);
uniform float opacity : hint_range(0.0, 1.0) = 1.0;
uniform float progress : hint_range(0.0, 1.0) = 1.0;
uniform float glow_strength : hint_range(0.0, 3.0) = 1.0;
void fragment() {
    if (UV.x > progress + 0.02) { discard; }
    float soft = 1.0 - abs(UV.y * 2.0 - 1.0);
    float falloff = smoothstep(0.01, 0.55, soft);
    ALBEDO = tint.rgb;
    EMISSION = tint.rgb * glow_strength;
    ALPHA = tint.a * opacity * falloff;
}
