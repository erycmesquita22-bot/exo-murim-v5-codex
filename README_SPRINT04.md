# EXO-MURIM — SPRINT 04: MONTAGEM E POLIMENTO DO MAPA

## Entrega real
Terrain mesh GLB e textura customizada implementados na cena jogável E cena de inspeção. Alteração de normais (sombreamento) sem editar posições de vértices nem colisões. Entradas de 15 casas ligadas visualmente às vias. Materiais naturais em paleta de manhwa.

## QA verificado
- Godot 4.7.2 Stable OpenGL Compatibility, Linux Mesa llvmpipe; conferir `qa/sprint04/logs/`.
- Script `qa/sprint04/validate_sprint04.gd` executa caso Wong e caso Wudong, com teste real da física e movimento; resultados em `qa/sprint04/validation.json`.
- `qa/sprint04/capture_sprint04.gd` tira imagens da renderização real nas cenas de inspeção; as PNGs estão em `previews_sprint04/`.
- Verificações geométricas do GLB são feitas em Python e seus dados estão em `terrain_sprint04/manifest_sprint04.json`.

## Não homologado
Testes de exploração humana de cada porta/trilha e colisões em toda a região, carregamento de interiores, aprovação estética final e dispositivos reais. As 15 aproximações visuais podem exigir ajustes estéticos após a inspeção manual.
