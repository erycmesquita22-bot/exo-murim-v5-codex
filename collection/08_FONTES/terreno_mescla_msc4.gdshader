shader_type spatial;
render_mode cull_back, depth_draw_opaque;

// Use a separate material per terrain pair; UV ranges 0-1 on the tile.
uniform sampler2D solo_base : source_color, filter_nearest, repeat_enable;
uniform sampler2D solo_cobertura : source_color, filter_nearest, repeat_enable;
uniform sampler2D mascara_msc4 : filter_nearest, repeat_disable;
uniform float escala_textura : hint_range(0.25,8.0) = 1.0;

void fragment() {
    vec3 base_color = texture(solo_base, UV * escala_textura).rgb;
    vec3 over_color = texture(solo_cobertura, UV * escala_textura).rgb;
    float peso = texture(mascara_msc4, UV).a;
    ALBEDO = mix(base_color, over_color, peso);
    ROUGHNESS = 0.95;
}
