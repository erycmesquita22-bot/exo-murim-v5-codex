# EXO-Murim 09.4.6 — Base Ambiental: Solo Voxel

Abra `project.godot` em Godot 4.6.x. O cenário da 09.4.5 foi mantido, mas o terreno e as trilhas recebem oito texturas físicas do projeto, repetidas via coordenadas UV e escolhidas por bioma/seed.

**Teste visual:** crie uma nova jornada; observe grama e terra no entorno da vila, trilhas texturizadas, solo florestal a leste, rochas no oeste e pedra/cascalho próximo das ruínas ao norte. Caminhe na vila e volte do treino. Teste colisão com troncos de bambu e pedras médias no exterior.

**Testes automáticos (Godot):** `godot --headless --path . --script res://qa0946.gd`. A execução deste teste não foi possível no ambiente de construção.

**Assets:** `assets/terrain/*.png` (8 texturas 128x128) e prancha `AMOSTRA-GRAMAS-SOLOS.png`. O gerador está em `tools/generate_terrain_textures.py`. O catálogo e carregador ficam em `world/terrain_assets.gd`; os objetos leves adicionais em `world/terrain_props.gd`.

**Limite conhecido:** esta atualização substitui a apresentação do chão, mas não implementa por si só as 88 regiões, nem corrige de forma definitiva todas as bordas, os interiores ou os assets de construções e cavernas.
