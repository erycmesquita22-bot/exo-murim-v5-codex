# Terrain Texture Forge 01 — Integração R11

**A integração em código está implementada; shaders e scene runtime não foram executados.**

## Autoridades e limites
- `genesis/region_data.gd` e `genesis/world_planner.gd`: nenhuma alteração, continuam autoridade de geometria, seed e bioma.
- `genesis/region_scene.gd`: dois hooks visuais adicionados; terreno de colisão inalterado.
- `exo_visual`: mesmo menu, driver e perfis; três novas opções persistidas por ConfigFile, NÃO JourneySave.
- `exo_terrain_forge/worldgen/terrain_texture_adapter.gd`: orçamento de MultiMesh 170, determinismo por region_seed, checagem de estrada, rio, pad, relevo e lote/monumento via `pad_distance`.

## Plano de recursos
- Gramas, terra, pedra, transições e detalhes catalogados; atlas 1088×544/816×816/816×544 com gutter 8 e conteúdo de 256px.
- `forge_region_offset` + `forge_world_seed` no shader; perfil `texture_filter` aplica nearest, nearest_mipmap, linear_aniso sem perder samplers.
- `ProjectSettings exo_murim/terrain_forge/enabled` é kill switch da geração da camada, `terrain_forge_enabled` é controle gráfico ao vivo.
- `terrain_forge_vegetation` altera instâncias visíveis do MultiMesh, sem modificar mundo nem saves. Mudar detalhe para zero mantém nós render-only com zero instâncias visíveis até novo ajuste.

## Riscos e decisões
- Maior custo de fragment shader e filtragem de atlas pode reduzir FPS: **não medido**.
- Somente atlas de chão recebe o shader novo; pavimentação de edifícios e interiores fica intacta. Identidade dos pisos de praças autorais no WorldGen continua independente.
- Proximidade geométrica de rios, ruas e lotes foi testada somente pela presença dos filtros no código, não com colisões nativas.
- Trechos de transição entre biomas continuam herdando os pesos oficiais dos portais; não há prova de aparência homogênea entre regiões sem imagens reais.
