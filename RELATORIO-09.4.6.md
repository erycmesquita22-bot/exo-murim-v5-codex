# EXO-Murim 09.4.6 — Biblioteca de terrenos e materiais

**Base:** 09.4.5, sem modificar `rig.gd`, `wardrobe.gd`, `arsenal.gd`, `martial_motion.gd`, regras de missão, layout de vilas, inventário ou saves.

## Assets produzidos (originais, sem terceiros)

Oito PNGs tileáveis 128×128 em `assets/terrain/`: `grass_lush`, `grass_dry`, `earth`, `forest_soil`, `stone`, `gravel`, `moss_stone`, `trail`.

Incluídos: arte-fonte gerada deterministicamente com `tools/generate_terrain_textures.py` (Pillow + NumPy), uma prancha de materiais `AMOSTRA-GRAMAS-SOLOS.png` e carregador/catálogo de materiais compartilhados `world/terrain_assets.gd`. Os PNGs são nossos, podendo ser usados comercialmente no EXO.

## Aplicação na jogabilidade

- `world/landscape.gd`: usa oito superfícies de terreno sobre a mesma malha de elevação e a mesma colisão anterior. Cada quadra recebe grama/terra/pedra de acordo com posição, bioma, relevo e noise da seed do mundo. UVs mundiais repetidas, sem grandes áreas com uma cor lisa. Fluxos de geração de equipamentos não mudaram.
- Trilhas externas: terra/cascalho texturizados, geometria e colisão anteriores preservadas.
- `world/level_design.gd`: base de estradas, praça, lotes, hortas e jardins passam a usar materiais texturizados.
- `world/village_composition.gd`: apron decorativo do mapa legado recebe material de grama em vez de vertex colour sólido.
- `world/static_batch.gd`: o batcher antigo agora **não destrói** UVs/texturas ao converter blocos coloridos em uma malha de cores de vértice.
- `world/terrain_props.gd`: vegetação rasteira via MultiMesh e algumas rochas maiores com colisão fora de passagens e da área de nascimento. Usam uma seed dedicada, separada do loot e das entidades.
- Troncos de bambus e pinheiros gerados por `landscape.gd`, `region.gd` e `village_composition.gd` receberam colisão física; folhagem pequena permanece atravessável.

## Proteção contra regressões

Não foram movidos serviços, NPCs, marcadores, terreno físico principal nem spawn. Os desenhos substituídos são apenas materiais/objetos ambientais. Os rochedos foram colocados longe da vila, corredores e arena.

## Verificações executadas neste ambiente

- Validação de oito PNGs e formatos, de dependências/caminhos e arquivo ZIP.
- Comparação hash de fontes de personagem, criação de personagem, combate, save e geração de vila com 09.4.5.
- Conferência de que a malha procedural usa UV e múltiplas superfícies de material, com colisão preservada.

**Não realizado:** Godot não está instalada no ambiente. O `qa0946.gd` exige Godot 4.6.x e deve ser executado com `godot --headless --path . --script res://qa0946.gd`. A aparência e o desempenho reais permanecem pendentes de validação. Não declarar que a qualidade foi aprovada em engine.

## Limites de escopo

Esta atualização **não** traz ainda assets completos para 88 regiões, transições regionais, cidade grande, dunas, rios, interiores ou uma biblioteca completa de templos/masmorras. Trata-se de uma primeira base de **superfícies reais reutilizáveis**, essencial para parar de gerar chão liso. O catálogo arquitetônico ainda precisa ser expandido.
