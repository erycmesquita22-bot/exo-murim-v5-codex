extends RefCounted
## EXO Visual 01 — independent, non-gameplay graphic settings schema.
const VERSION := 1
const PRESET_NAMES := ["Mínimo", "Baixo", "Médio", "Alto", "Ultra", "Personalizado"]
const DISPLAY_RESOLUTIONS := [Vector2i(1152,720),Vector2i(1280,720),Vector2i(1600,900),Vector2i(1920,1080)]
const OPTIONS := {
 "window_mode": {"label":"Modo de tela", "section":"Tela", "choices":["Janela", "Tela cheia", "Janela maximizada"],"default":0},
 "resolution": {"label":"Resolução", "section":"Tela", "choices":["1152×720", "1280×720", "1600×900", "1920×1080"],"default":0},
 "vsync": {"label":"Sincronização vertical", "section":"Tela", "choices":["Desativada", "Ativada"],"default":1},
 "fps_limit": {"label":"Limite de FPS", "section":"Tela", "choices":["Sem limite", "30", "60", "90", "120", "144"],"default":2},
 "render_scale": {"label":"Escala 3D", "section":"Tela", "choices":["70%", "85%", "100%", "125%"],"default":2,"forward_only":true},
 "upscaler": {"label":"Dimensionamento", "section":"Tela", "choices":["Bilinear", "FSR 1.0"],"default":0,"forward_only":true},
 "msaa": {"label":"MSAA 3D", "section":"Tela", "choices":["Desativado", "2×", "4×", "8×"],"default":1},
 "fxaa": {"label":"FXAA", "section":"Tela", "choices":["Desativado", "Ativado"],"default":0},
 "shadow_quality": {"label":"Sombras dinâmicas", "section":"Iluminação", "choices":["Desativadas", "Baixas", "Médias", "Altas"],"default":0},
 "shadow_distance": {"label":"Alcance de sombras", "section":"Iluminação", "choices":["Curto", "Médio", "Longo"],"default":1},
 "character_shadows": {"label":"Sombras dos personagens", "section":"Iluminação", "choices":["Pintadas", "Pintadas + dinâmicas"],"default":0},
 "ambient_light": {"label":"Luz ambiente", "section":"Iluminação", "choices":["Suave", "Equilibrada", "Viva"],"default":1},
 "ssao": {"label":"Oclusão ambiental (SSAO)", "section":"Iluminação", "choices":["Desligada", "Suave", "Média"],"default":0},
 "ssr": {"label":"Reflexos em tela (SSR)", "section":"Ambiente", "choices":["Desligados", "Ligados"],"default":0,"forward_only":true},
 "ssil": {"label":"Iluminação indireta (SSIL)", "section":"Iluminação", "choices":["Desligada", "Ligada"],"default":0,"forward_only":true},
 "fog": {"label":"Névoa", "section":"Ambiente", "choices":["Desligada", "Sutil", "Atmosférica"],"default":1},
 "water_quality": {"label":"Qualidade da água", "section":"Ambiente", "choices":["Estática", "Leve", "Animada", "Detalhada"],"default":2},
 "grass_density": {"label":"Capim decorativo", "section":"Ambiente", "choices":["Desligado", "25%", "50%", "75%", "100%"],"default":4},
 "wind": {"label":"Vento na vegetação", "section":"Ambiente", "choices":["Desligado", "Suave", "Visível"],"default":1},
 "detail_distance": {"label":"Distância de detalhes", "section":"Ambiente", "choices":["Próxima", "Média", "Distante"],"default":1},
 "particles": {"label":"Partículas opcionais", "section":"Efeitos", "choices":["Desligadas", "Poucas", "Normais", "Muitas"],"default":2},
 "weapon_trails": {"label":"Rastros de armas", "section":"Efeitos", "choices":["Desligados", "Reduzidos", "Completos"],"default":1},
 "afterimages": {"label":"Pós-imagens", "section":"Efeitos", "choices":["Desligadas", "Discretas", "Completas"],"default":1},
 "glow": {"label":"Bloom / Glow", "section":"Efeitos", "choices":["Desligado", "Sutil", "Intenso"],"default":0},
 "impact_details": {"label":"Detalhes de impactos", "section":"Efeitos", "choices":["Essenciais", "Padrão", "Detalhados"],"default":1},
 "material_detail": {"label":"Variação do solo", "section":"Texturas", "choices":["Sem variação", "Discreta", "Detalhada"],"default":1},
 "texture_filter": {"label":"Filtragem de texturas 3D", "section":"Texturas", "choices":["Pixelada", "Pixelada com mipmaps", "Suavizada"],"default":1},
 "terrain_forge_enabled": {"label":"Terrain Forge", "section":"Texturas", "choices":["Desativado", "Ativado"],"default":1},
 "terrain_forge_mix": {"label":"Mistura do terreno", "section":"Texturas", "choices":["Suave", "Equilibrada", "Forte"],"default":2},
 "terrain_forge_vegetation": {"label":"Detalhes naturais", "section":"Ambiente", "choices":["Desativados", "Discretos", "Normais", "Densos"],"default":2},
}
const PRESETS := [
 {"msaa":0,"shadow_quality":0,"ssao":0,"ssil":0,"ssr":0,"fog":0,"water_quality":0,"grass_density":0,"wind":0,"detail_distance":0,"particles":0,"weapon_trails":0,"afterimages":0,"glow":0,"impact_details":0,"material_detail":0,"terrain_forge_vegetation":0,"terrain_forge_mix":0},
 {"msaa":0,"shadow_quality":0,"ssao":0,"ssil":0,"ssr":0,"fog":0,"water_quality":1,"grass_density":1,"wind":0,"detail_distance":0,"particles":1,"weapon_trails":1,"afterimages":0,"glow":0,"impact_details":0,"material_detail":1,"terrain_forge_vegetation":1,"terrain_forge_mix":1},
 {"msaa":1,"shadow_quality":0,"ssao":0,"ssil":0,"ssr":0,"fog":1,"water_quality":2,"grass_density":3,"wind":1,"detail_distance":1,"particles":2,"weapon_trails":1,"afterimages":1,"glow":0,"impact_details":1,"material_detail":1,"terrain_forge_vegetation":2,"terrain_forge_mix":1},
 {"msaa":2,"shadow_quality":2,"character_shadows":1,"ssao":1,"ssil":0,"ssr":0,"fog":1,"water_quality":2,"grass_density":4,"wind":1,"detail_distance":2,"particles":2,"weapon_trails":2,"afterimages":1,"glow":1,"impact_details":2,"material_detail":2,"terrain_forge_vegetation":3,"terrain_forge_mix":2},
 {"msaa":3,"shadow_quality":3,"character_shadows":1,"shadow_distance":2,"ssao":2,"ssil":1,"ssr":1,"fog":2,"water_quality":3,"grass_density":4,"wind":2,"detail_distance":2,"particles":3,"weapon_trails":2,"afterimages":2,"glow":2,"impact_details":2,"material_detail":2,"terrain_forge_vegetation":3,"terrain_forge_mix":2}
]
static func defaults() -> Dictionary:
 var d: Dictionary={}
 for key in OPTIONS:d[key]=int(OPTIONS[key].default)
 return d
static func normalize(key: String, value: Variant) -> int:
 if not OPTIONS.has(key):return -1
 if not (value is int or value is float):return int(OPTIONS[key].default)
 var n: int=int(value)
 if n!=value or n<0 or n>=OPTIONS[key].choices.size():return int(OPTIONS[key].default)
 return n
static func renderer_is_forward() -> bool:
 return RenderingServer.get_current_rendering_method() != "gl_compatibility"
static func available(key: String) -> bool:
 if not OPTIONS.has(key):return false
 return not OPTIONS[key].get("forward_only",false) or renderer_is_forward()
