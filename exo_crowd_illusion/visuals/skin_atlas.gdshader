shader_type spatial;
render_mode cull_disabled, shadows_disabled;
uniform sampler2D skin_atlas : source_color, filter_nearest, repeat_disable;
varying vec2 crowd_atlas_offset;

void vertex() {
    crowd_atlas_offset = INSTANCE_CUSTOM.rg;
}

void fragment() {
    // Each MultiMesh instance chooses one of the 8x8 shared skin tiles.
    vec2 tile_pixels = vec2(textureSize(skin_atlas, 0)) * 0.125;
    vec2 tile_uv = clamp(UV, vec2(0.5) / tile_pixels, vec2(1.0) - vec2(0.5) / tile_pixels);
    vec2 atlas_uv = tile_uv * 0.125 + crowd_atlas_offset;
    vec4 texel = texture(skin_atlas, atlas_uv);
    ALBEDO = texel.rgb;
    ROUGHNESS = 0.95;
    METALLIC = 0.0;
    ALPHA = texel.a;
    ALPHA_SCISSOR_THRESHOLD = 0.45;
}
