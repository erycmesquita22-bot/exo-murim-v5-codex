# EXO-Murim | Terrain Sprint 01 — HWA-02

Este modulo altera APENAS a aparencia do terreno da Vila de Haneul.

- `HWA02_Terrain_Murim_Sprint01.glb`: malha do terreno fisicamente identica a do Haneul V0.4 (mesmas alturas e vertices), com UV continuo X/Z.
- `EXO_Haneul_Ground_Painted_2048.png`: pintura distribuida fisicamente na cena (gramado, estradas, terrenos de casas, pracas e margens).
- `EXO_Murim_16_Materiais_2048.png`: atlas de 16 materiais desenhados, com PNGs editaveis em `tiles/`.
- `previews/01_PALETA_16_TEXTURAS_MURIM.png`, `previews/02_TEXTURA_TERRENO_APLICADA_MAPA.png`: imagens reais dos materiais incluidos.

Godot 4.7.2 Compatibility: `project.godot` > F5. A cena V3 esconde o terreno e caminhos antigos SOMENTE visualmente. A colisao original do terreno permanece. No GLB novo nao ha colisao duplicada.

Nao ha alteracoes no controlador Character Core V3, animacoes, construcoes, NPCs ou rios. Apos o Sprint 1: a otimizacao mobile de atlas 2048, QA visual em dispositivos e ajuste da orla do rio estao pendentes. A arte foi gerada originalmente com Python/Pillow e vetores/pinceladas calculadas; isso nao substitui ilustracao manual profissional.
