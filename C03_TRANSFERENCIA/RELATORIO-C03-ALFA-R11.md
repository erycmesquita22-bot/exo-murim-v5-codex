# EXO-MURIM — CONVERGÊNCIA 03 ALFA R11 — RELATÓRIO TÉCNICO

**Estado:** CANDIDATO DE CÓDIGO, NÃO HOMOLOGADO. Godot 4.6.2 não encontrado, GitHub DNS indisponível. Não há F5, parser nativo, shader compilado, FPS, gameplay nem capturas reais.

## Fonte e preservação
- **ÚNICA base integral** `EXO-MURIM-CONVERGENCIA-03-ALFA-R10.zip`, SHA-256 `b72301454d0ccc7a1d7634371ff4e4a01a26f28f11648f9a4ba0e535c5c357d0`, CRC PASS, 4.568 membros.
- **Fonte secundária aditiva:** `EXO-MURIM-TERRAIN-TEXTURE-FORGE-01-PATCH-R6.zip`, SHA-256 `98cd167de10aaba71494c5023750420ea36e588bc7c8201ea03010ecaaaee841`, CRC PASS, 122 membros.
- Seis colisões de caminho resolvidas por alteração **seletiva**, não substituição dos scripts. 116 recursos exclusivos do patch incorporados e um QA nativo novo. `project.godot` recebeu namespace de QA R11 e opção de feature global; não substituiu R10.
- **WorldGenesis, region_data.gd, receitas de monumentos R7, Dungeon/Itens R6, marcial R9, aparência R10, personagens, gameplay, schemas e grafo das 88 regiões não foram alterados.** Os saves reais não foram carregados, editados ou apagados.

## Integração funcional de código
1. `genesis/region_scene.gd`: aplica atlases ao material de terreno antes de criar chunks e adiciona um `MultiMesh` visual opcional após a vegetação R1. **NÃO** modifica o terreno físico, rios, estradas, seed, altura ou reservas.
2. `exo_terrain_forge/worldgen/terrain_texture_adapter.gd`: reutiliza catálogo original, usa a seed regional para vegetação estável, a seed do mundo e o centro global para materiais, lê `road_distance`, `river_distance` e `pad_distance` (abrange lotes e reservas monumentais) e limita a **170 sprites por região**. `MultiMesh` sem StaticBody/colisão; cache do manifesto, sem parse JSON repetido por instância.
3. `genesis/terrain.gdshader` e três variantes `exo_visual/shaders/*terrain*`: funções de atlas adicionadas, com `forge_enabled` para alternar material antigo/nova mistura. A matemática da renderização **com Forge desligado** foi comparada literalmente à R10. O mapeamento usa `forge_region_offset` + coordenadas locais, mantendo fase de padrões contínua em coordenadas de mundo; a continuidade VISUAL entre biomas e as bordas ainda não foi observada na Godot.
4. `exo_visual/driver.gd`: ao mudar filtragem, preserva todos os samplers e parâmetros do Forge, em vez de perder as texturas. Controles atuam em `forge_enabled`, `forge_mix_strength`, visibilidade, `visible_instance_count` e distância de desenho.
5. `exo_visual/spec.gd`: três opções **reais** no menu original e configuração oficial: `terrain_forge_enabled` (0/1), `terrain_forge_mix` (3 níveis) e `terrain_forge_vegetation` (4 níveis); perfis de qualidade ajustam mistura/vegetação. Usado `graphics.gd` existente, com salvamento independente das campanhas.

## Conteúdo novo
- 36 materiais catalogados (incluindo transições, detalhes e sprites), atlas de grama/terra/pedra/detalhes/vegetação, amostras originais offline, shaders/arquivos de recurso e adaptador.
- 116 arquivos da ramificação de texturas integrados sem sobrescrever nenhum arquivo do Core/WorldGen; os exemplos JPG são documentação do pacote, NÃO capturas de execução do EXO-Murim.
- As 480 skins em quarentena permanecem exatamente como na R10.

## QA e limites
- **4.909 verificações offline PASS, 0 FAIL**, compostas majoritariamente pela confirmação individual de arquivos R10, recursos existentes, SHA/CRC, recortes e gutters de atlas e conferências estáticas de código. **NÃO equivalem a 4.909 testes de jogabilidade.**
- Atlas: 5 resoluções corretas, blocos de 256px idênticos aos PNGs 256, gutters periódicos verificados offline.
- **14 grupos nativos NOT_RUN**, conforme `QA-C03-ALFA-R11-MATRIZ.json`.
- Não verificáveis: compilação de shaders Compatibility, aparência da vegetação/UV em viewport, alternância ao vivo de menu, física/circulação reais, 88 regiões, transições fluviais 14/26, cidade 78, 4 seeds alvo, imagens, frametime, draw calls e FPS no Ryzen 3200GE/Vega 8.
- O caminho legado permanece disponível em tempo de execução ao desativar o Forge, mas a equivalência de pixels em GPU requer teste.
- Não existem arquivos de licenciamento independentes na fonte PATCH confirmando titularidade. Recursos foram recebidos como originais do projeto; **a aprovação jurídica/comercial é pendente**, sem autorizar assets de terceiros.

## Gates de R12/Work
1. Obter Godot 4.6.2 Standard, importar e capturar stderr real com `--rendering-method gl_compatibility` e executar `res://convergence/tests/qa_c03_r11_native.gd` e suítes R3–R10.
2. Com shader e cenas compiladas, inspecionar as seeds 101, 816204, 707, 18026; cidade 78 e regiões fluviais 14 e 26. Verificar shader on/off nos três filtros, vegetação, reservas monumentais, gameplay e saves.
3. Comparar material Forge ligado/desligado no mesmo lugar/câmera, inspecionar costura das regiões e gutters/mips.
4. Perfilar Vega 8 (FPS/p50/p95/p99/memória/draw calls) e corrigir qualquer regressão antes de aprovar o Forge como padrão final.
5. Segregar e preservar rollback em PAR código/saves. Não iniciar Convergência 04.
