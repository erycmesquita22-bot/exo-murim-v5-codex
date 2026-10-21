shader_type spatial;
render_mode unshaded, blend_mul, depth_draw_never, shadows_disabled;
uniform sampler2D visibility_mask : filter_linear, repeat_disable;
uniform vec2 mask_origin;
uniform float mask_width = 25.0;
uniform float actor_height;
varying vec3 world_position;
void vertex() {
 world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
void fragment() {
 vec2 uv = (world_position.xz - mask_origin) / mask_width;
 float inside = step(0.0, uv.x) * step(uv.x, 1.0) * step(0.0, uv.y) * step(uv.y, 1.0);
 float visible = texture(visibility_mask, clamp(uv, vec2(0.0), vec2(1.0))).r * inside;
 visible *= 1.0 - step(6.0, abs(world_position.y - actor_height));
 ALBEDO = vec3(mix(0.018, 1.0, visible));
 ALPHA = 1.0;
}
