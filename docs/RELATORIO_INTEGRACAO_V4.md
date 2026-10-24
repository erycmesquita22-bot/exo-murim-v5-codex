# EXO-Murim — Haneul V0.4 + Character Core V3 Motion

## Resultado real (23/10/2026)

**Godot utilizada:** 4.7.2-stable (oficial), Linux. Testes de física em headless; capturas gráficas em Xvfb + Mesa llvmpipe, renderer Compatibility. Teste Android NÃO EXECUTADO.

**Fonte de verdade:** `EXO_CHARACTER_CORE_01_V3_MOTION (1).zip` fornecido pelo usuário. O GLB de V3 permanece byte-a-byte idêntico. Somente o controlador V3 teve caminhos `res://` adaptados ao projeto, sem alteração de lógica de combate ou rig.

**Substituição limpa:** pasta `character/` e a cena/controlador V2 antigos removidos da árvore ativa. O controlador atual está em `modules/character_core_v3/`. Sem mesclar arquivos da V2. `source/EXO_Character_Core_V3_Blender_Source.zip` contém o `.blend` fora do sistema de importação da Godot; a cena usa somente GLB. A outra pasta `qa/reference/` é referência visual opcional de QA, nunca instanciada durante o jogo.

## Bug crítico descoberto e corrigido

A malha `Terrain` do modelo GLB HWA-02 possui faces com orientação para baixo. O collider concavo antigo, sem `backface_collision`, não bloqueava corretamente o player por cima. No primeiro teste real o player atravessou o terreno, as normais de colisão ficavam horizontais e caminhada/corrida travavam. Foi corrigido no controlador de integração, configurando a forma `ConcavePolygonShape3D.backface_collision = true` em colisões estáticas de mapa. Não foi preciso alterar o modelo visual das casas ou a textura. Spawn colocado no ponto de nascimento no sul da vila, com câmera atrás do personagem, não na extremidade norte. O conserto de orientação da malha deve entrar futuramente na origem do modelo, para evitar superfícies inversas noutros sistemas.

## QA executado

| Validação | Resultado | Evidência |
|---|---|---|
| Importação de GLB/cenas no Godot 4.7.2 | PASS | `qa/reports/01_import_472.log` |
| Boot cena integrada em headless | PASS | `qa/reports/02_boot_472.log` |
| V3 / 25 ossos / 15 clipes / AnimationTree | PASS | `qa/reports/03_smoke_v04.json` |
| Collider da vila, piso, caminhar/correr | PASS após conserto | `qa/reports/03_smoke_v04.log` |
| Wong / Wudong, brasões | PASS | smoke + screenshots |
| Sacar, golpe 1, combo golpe 2, esquiva, reação, guardar | PASS em smoke automatizado | JSON e log de teste |
| Renderização pela Godot Compatibility | PASS em Mesa llvmpipe | `qa/reports/04_graphical_capture.log`, imagens PNG |
| Teste humano de combate e câmera | NÃO EXECUTADO | — |
| Performance PC com GPU / Android | NÃO EXECUTADO | — |
| Distribuição física de objetos na vila inteira | NÃO EXECUTADO | — |

### Distâncias no teste automatizado (não são benchmark de desempenho)

- Wong: caminhada horizontal 2.49m; corrida 2.75m; combo 1.
- Wudong: caminhada horizontal 2.49m; corrida 2.75m; combo 1.

Ambos os testes terminaram com `errors: []` na Godot 4.7.2.

## Limites

Há apenas o cabo/guarda de arma providos pelo V3, sem uma lâmina completa. O alvo de treino é provisório. Os resultados não comprovam a ausência de bugs em todos os caminhos do mapa, colisões de telhado, interações de NPC ou dispositivo móvel. As capturas de Mesa llvmpipe não são benchmarks de GPU. Persistência de saves e carregamento dinâmico de módulos também não são implementados nessa amostra.
