# EXO-Murim V5 — Correção focada R2 (interiores / empunhadura)
Data: 22/10/2026. Estado: **candidato para validação**, não homologado.

## Base de origem
- `EXO-MURIM-V5-RETOMADA-LOCAL-E-INTERIORES-CANDIDATO.zip` (conteúdo preservado; somente 6 arquivos de código substituídos).
- `project.godot`, menu profissional, WorldGen, ruínas e lógica original de saves preservados.
- Engine dos testes: **Godot 4.7.2 Standard, renderizador Compatibility**. Jogo-alvo: Godot 4.6.2. Não declarar homologação nessa versão sem executá-la.

## Falha reproduzida: interior restaurado sem saída
O teste anterior reabria o prédio, mas saía chamando `PortalController.interrupt()` diretamente. Não verificava `E` após salvar e reabrir.
No teste novo (antes do patch) o personagem retornou à mesma loja, `is_on_floor=false`, `gate_cooldown=1.0` e `wg5_visit.inside=true`. A chamada real `game.interact()` NÃO saía do prédio (teste falhou).
### Correção aplicada
- `convergence/game.gd`: valida a saída do interior **antes** de `is_on_floor()` e do cooldown regional. Ao sair, zera o cooldown e persiste a posição externa.
- `worldgen_v5/runtime/visit_host.gd`: mostra indicação `E • Sair do edifício` durante a visita inteira.
- `exo_settlement_forge/runtime/portal_controller.gd`: permite sair de pequenas casas/lojas instanciadas com a ação explícita `E`, sem exigir proximidade de um marcador invisível; o marcador de saída ainda é obrigatório e retorna ao endereço externo registrado.

## Falha reproduzida: mãos separadas da arma
`qa_round2/qa_grip_inspection.gd` mediu o punho de apoio **mais de 1 m distante do punho principal** em armas de duas mãos (ex.: lança e alabarda). O segundo braço era posicionado por ângulo fixo, sem alcançar a arma.
### Correção aplicada
- `arsenal.gd`: aplica IK para o braço principal e faz a segunda mão alcançar um ponto do **mesmo cabo**, para espada pesada, lança, alabarda, foice, bastão e cajado mágico. Não altera físicas, alcance ou dano.
- `pause_ui.gd` e `ui/portrait_stage.gd`: remove escrita duplicada de pose no preview, deixando o PortraitStage responsável por pose, arma e anatomia.
- O teste em Godot passou para `greatsword`, `spear`, `halberd`, `quarterstaff` e `arcane_staff`, nas fases idle, ataque inicial e recuperação; nenhum erro de distância do ponto de apoio. Captura de inspeção 3D produzida, mas **qualidade artística de cada pose ainda não homologada**.

## QA executado
- `qa_round2/qa_interior_exit_repro.gd`: falhou **antes** do patch; passou após correção.
- `qa_round2/qa_interior_exit_keyboard.gd`: passou. Simula `E` por vários quadros após reabertura; verifica saída, `worldgen_v5_visit.inside=false` gravado em disco, segundo reinício **fora** da loja, região e posição externas preservadas.
- `qa_resume_fix/qa_reopen_game.gd`: passou; regressão da retomada do save de rua e dentro da loja.
- `qa_resume_fix/qa_interior_restore.gd`: passou; regressão de interior com estabelecimento fechado e retorno externo.
- `qa_round2/qa_grip_inspection.gd`: passou com falhas=0 para empunhadura de duas mãos.
- Godot `--headless --editor --quit`: saída 0, nenhum erro de scripts no log.
- Godot `--headless --quit-after 45`: saída 0, menu inicializado sem erro.
- Godot com tela virtual OpenGL llvmpipe: cena visual de inspeção de empunhaduras foi renderizada.

## Importação do editor
A captura do usuário relata `Task 'reimport' already exists` / `Attempted to call reimport_files() recursively`. Não há chamada de `reimport_files` no código do jogo inspecionado. É um erro já relatado no editor Godot para importação GLB/texture (godotengine/godot#110645), mas sua causa exata no PC ainda não está comprovada. Este pacote **não reivindica correção desse erro**. Abrir o projeto extraído em uma pasta nova, com editor fechado durante extração e cache `.godot` não copiado de build anterior. Não apagar `user://` nem saves pessoais.

## Desempenho da cidade
A observação de que a batalha com NPCs é mais leve do que a cidade é compatível com a contagem prévia de 1951 draw calls e cerca de 174.848 triângulos para uma cena de cidade com 33 estruturas. Os números são uma **medição isolada em software/llvmpipe**, não uma comparação direta de FPS com a batalha nem com a Radeon Vega 8. Não houve otimização da cidade nesta revisão: exige benchmark A/B na mesma câmera, qualidade, seed e NPCs.

## Não mexemos
- Assets comerciais, WorldGen, geração de edifícios, save schema, menu principal, cenas de combate, dungeons, física das armas, economia e IA dos NPCs.

## Status
**Implementado e parcialmente validado no Godot 4.7.2. Pendente: homologação visual do jogador, validação Godot 4.6.2 e investigação separada da reimportação e desempenho urbano.**
