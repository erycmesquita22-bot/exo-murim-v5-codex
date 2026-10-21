shader_type spatial;
render_mode cull_disabled;
// Approved detailed ground atlas; geometry, collision and seed are unchanged.
uniform sampler2D ground_tex : source_color,filter_nearest,repeat_enable;
uniform sampler2D road_tex : source_color,filter_nearest,repeat_enable;
uniform sampler2D blend0 : source_color,filter_nearest,repeat_enable;
uniform sampler2D blend1 : source_color,filter_nearest,repeat_enable;
uniform sampler2D blend2 : source_color,filter_nearest,repeat_enable;
uniform sampler2D blend3 : source_color,filter_nearest,repeat_enable;
// Ground foliage is sampled 2.45x finer; the approved rock/road UV is UNCHANGED.
uniform float foliage_uv_scale = 2.45;
uniform float exo_microvariation : hint_range(0.0,0.15) = 0.02;
uniform float exo_edge_irregularity : hint_range(0.0,0.2) = 0.11;
// TERRAIN TEXTURE FORGE 01: shared runtime atlases, explicitly kept independent of WorldGen.
uniform bool forge_enabled = false;
uniform sampler2D forge_grass_atlas : source_color, filter_linear_mipmap, repeat_disable;
uniform sampler2D forge_dirt_atlas : source_color, filter_linear_mipmap, repeat_disable;
uniform sampler2D forge_stone_atlas : source_color, filter_linear_mipmap, repeat_disable;
uniform sampler2D forge_detail_atlas : source_color, filter_linear_mipmap, repeat_disable;
uniform vec2 forge_region_offset = vec2(0.0);
uniform float forge_biome_mode = 0.0; // 0=grass, 1=dirt, 2=rocky
uniform float forge_stone_road = 0.0;
uniform float forge_mix_strength : hint_range(0.0,1.0) = 0.88;
uniform float forge_world_seed = 0.0;

// RUNTIME atlases at 256 px per tile + 8 px periodic gutters.
// Enforcing stable world-space UV keeps chunk boundaries continuous.
vec2 forge_atlas_uv(vec2 tile_uv, float idx, float cols, float rows) {
 float cell_w=272.0;
 vec2 cell=vec2(mod(idx,cols),floor(idx/cols));
 return (cell*cell_w+vec2(8.5)+fract(tile_uv)*255.0)/vec2(cols*cell_w,rows*cell_w);
}
vec3 forge_grass(vec2 p, float idx) {
 return texture(forge_grass_atlas,forge_atlas_uv(p,idx,4.0,2.0)).rgb;
}
vec3 forge_dirt(vec2 p, float idx) {
 return texture(forge_dirt_atlas,forge_atlas_uv(p,idx,4.0,2.0)).rgb;
}
vec3 forge_stone(vec2 p, float idx) {
 return texture(forge_stone_atlas,forge_atlas_uv(p,idx,3.0,3.0)).rgb;
}
float forge_field(vec2 world_p) {
 float phase=forge_world_seed*0.000019;
 return clamp(0.5+0.24*sin(world_p.x*0.053+cos(world_p.y*0.029)+phase)+0.26*sin(world_p.y*0.043-sin(world_p.x*0.035)-phase),0.0,1.0);
}
vec3 forge_group(vec2 p, vec2 world_p, float mode, float fixed_stone) {
 float selection=forge_field(world_p);
 vec2 local_uv=world_p/4.0; // 4 world meters / periodic tile
 vec2 warp=vec2(sin(world_p.y*0.085),sin(world_p.x*0.074))*0.085;
 vec2 u=local_uv+warp;
 if (mode<0.5) {
  float k=clamp(selection*7.0,0.0,6.999);
  return mix(forge_grass(u,floor(k)),forge_grass(u,min(7.0,floor(k)+1.0)),smoothstep(0.0,1.0,fract(k)));
 }
 if (mode<1.5) {
  float k=clamp(selection*6.0,0.0,5.999);
  return mix(forge_dirt(u,floor(k)),forge_dirt(u,min(6.0,floor(k)+1.0)),smoothstep(0.0,1.0,fract(k)));
 }
 float k=clamp(selection*2.99,0.0,2.999);
 k += fixed_stone;
 return mix(forge_stone(u,floor(k)),forge_stone(u,min(8.0,floor(k)+1.0)),smoothstep(0.0,1.0,fract(k)));
}

varying vec4 border_weights;
void vertex(){border_weights=CUSTOM0;}
void fragment(){
 vec4 weights=clamp(border_weights,vec4(0.0),vec4(0.5));
 vec2 small_grass_uv=UV*foliage_uv_scale;
 vec3 ground=texture(ground_tex,small_grass_uv).rgb*(1.0-dot(weights,vec4(1.0)));
 ground+=texture(blend0,small_grass_uv).rgb*weights.x;
 ground+=texture(blend1,small_grass_uv).rgb*weights.y;
 ground+=texture(blend2,small_grass_uv).rgb*weights.z;
 ground+=texture(blend3,small_grass_uv).rgb*weights.w;
 vec3 road=texture(road_tex,UV).rgb;
 // Low-frequency irregularity restricted to mixed material edges.
 // World-derived UVs ensure adjacent chunks sample the same pattern.
 float n=sin(UV.x*14.7+sin(UV.y*4.5))*sin(UV.y*12.9);
 n+=0.42*sin(UV.x*27.1+UV.y*9.3)*sin(UV.y*22.4-UV.x*3.8);
 float edge_strength=4.0*COLOR.a*(1.0-COLOR.a);
 float road_weight=clamp(COLOR.a+edge_strength*n*exo_edge_irregularity,0.0,1.0);
 // Irregular exposed soil close to the verge, fading into distinct short vegetation.
 // Suppressed on the actual roadway so the owner's approved rocky road is intact.
 float patch=sin(UV.x*18.1+sin(UV.y*8.3))*sin(UV.y*17.3-UV.x*2.7);
 float bare_patch=smoothstep(0.45,0.78,patch)*0.16*(1.0-road_weight)*edge_strength;
 road_weight=clamp(road_weight+bare_patch,0.0,1.0);
 if (forge_enabled) {
  // World position derived from exact region offsets; no stochastic resets per chunk.
  vec2 global_p=UV*6.0+forge_region_offset;
  float f=forge_field(global_p);
  float edge=4.0*road_weight*(1.0-road_weight);
  vec3 minted=forge_group(global_p,global_p,forge_biome_mode,3.0);
  // Original biome weights remain authoritative at portals and boundaries.
  ground=mix(ground,minted,forge_mix_strength*(1.0-clamp(dot(weights,vec4(1.0)),0.0,1.0)));
  // Rural roads are ochre; settlement roads gain rustic stone without altering geometry.
  vec3 forge_road=forge_group(global_p,global_p,1.0,0.0);
  float stone_coverage=clamp(forge_stone_road+0.22*sin(global_p.x*0.028+sin(global_p.y*0.032)),0.0,0.94);
  vec3 paving=forge_group(global_p,global_p,2.0,0.0);
  forge_road=mix(forge_road,paving,stone_coverage);
  // Exact transition tiles exist as optional detail resources. Most visual edge
  // shape comes from world-coherent masks, not painted hard square boundaries.
  if (edge>0.015) {
   vec2 fringe_uv=global_p/4.0;
   float fringe=clamp(edge*0.19,0.0,0.14);
   forge_road=mix(forge_road,forge_stone(fringe_uv,6.0),fringe*0.30);
   if (forge_biome_mode<0.5) {
    forge_road=mix(forge_road,forge_stone(fringe_uv,8.0),fringe*0.28);
   } else {
    forge_road=mix(forge_road,forge_stone(fringe_uv,7.0),fringe*0.28);
   }
  }
  // Natural, world-continuous soft masks for the grass/dirt and dirt/stone transitions.
  float rough_edge=(sin(global_p.x*0.37+sin(global_p.y*0.27))*sin(global_p.y*0.29))*0.095;
  float moist=smoothstep(0.70,0.91,f)*(1.0-road_weight);
  if (forge_biome_mode < 0.5) {
   ground=mix(ground,forge_road,moist*0.16);
  } else if (forge_biome_mode<1.5) {
   ground=mix(ground,minted,0.08*moist);
  }
  road_weight=clamp(road_weight+rough_edge*edge,0.0,1.0);
  road=mix(road,forge_road,forge_mix_strength);
 }

 // Weak biome tint leaves the owner-approved colors and detail recognizable.
 vec3 tint=clamp(COLOR.rgb*1.65,vec3(0.60),vec3(1.35));
 float micro = sin(UV.x*36.5+sin(UV.y*7.3))*sin(UV.y*29.4);
 ALBEDO=mix(ground*mix(vec3(1.0),tint,0.11),road,road_weight)*(1.0+exo_microvariation*micro);
 ROUGHNESS=0.94;
}
