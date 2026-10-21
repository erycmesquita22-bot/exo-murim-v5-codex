# EXO-MURIM — Convergência 03 ALFA R2 — relatório técnico

**Data:** 19/10/2026. **Estado:** CANDIDATO DE CÓDIGO; NÃO HOMOLOGADO; GODOT NATIVO NÃO EXECUTADO.

## Princípio da rodada
Esta entrega deriva diretamente do ZIP integral `EXO-MURIM-CONVERGENCIA-03-ALFA-R1.zip`. **NÃO foi refeito o merge** dos módulos nem trocada a base. Os módulos que exigem contratos e QA mantêm-se em estágio de fonte, não registrados no Core para gameplay. A Alfa R1 permanece intacta.

## Achados reproduzidos em leitura estática e correções em R2
1. **RIG01 — dupla escrita de cotovelos:** `rig.gd` chamava a animação local, mas na sequência sobrescrevia os cotovelos por uma segunda fórmula fixa. Removida a segunda escrita e os overrides duplicados dos ombros; `animation_library.gd` torna-se a autoridade única da caminhada com braços livres. Inclusa validação dos dois braços e antebraços, mais `res://convergence/tests/qa_rig01_eight_directions.gd` para 8 direções. A geometria e qualidade visual **AINDA PRECISAM de execução na Godot**.
2. **FLOW01 — criação ainda atravessava vila legada:** no R1 o fluxo recriava `rebuild_region()`, retomava checkpoint e movia player para `village_anchor("camp")` antes do `change_region` diferido. A R2 encaminha a criação de campanha para `_begin_new_procedural_campaign()` diretamente, sem essas chamadas no ramo moderno. O código antigo foi preservado **somente** como fallback para cenas isoladas sem host procedural. Falha de carregamento é explicitamente registrada, sem retorno silencioso ao recinto.
3. **WORLD01 — erro de evento de entrada congelava o jogo:** em `convergence/game.gd`, `region_entered` malsucedido ocorria após destruir a região anterior e deixava `simulation_enabled=false`. Agora o erro continua reportado e a simulação não permanece permanentemente desativada. O evento **não é falsamente declarado persistido**; os aspectos de recuperação/save transacional continuam pendentes de teste e revisão.
4. **QA e isolamento:** configurado namespace próprio `EXO-Murim-Convergencia-03-ALFA-R2-QA`; preservadas texturas oficiais, shaders, NPC R2 e Core 01-P. Nenhum novo asset externo introduzido.

## Verificações realizadas (e limites)
- Bateria de regressão da Alfa R1, reexecutada sobre a R2: **27 PASS, 0 FAIL; 4 NOT_RUN nativos/hardware**.
- Bateria adicional R2: **20 PASS, 0 FAIL; 5 NOT_RUN nativos/hardware**.
- Inspeção de **438 scripts GDScript** por referências literais de preload; duas referências não resolvidas em arquivos históricos de laboratório (`godot/demo.gd` e `exo_core/module_template/test.gd`). Isso não é um parser GDScript.
- **354 arquivos JSON** analisados nesta rodada, sem falha de parse.
- Comparação derivacional com a árvore Alfa R1 realizada; arquivos de gameplay modificados: `animation_library.gd`, `rig.gd`, `murim_flow.gd`, `convergence/game.gd`, `project.godot` e novo teste `convergence/tests/qa_rig01_eight_directions.gd`.
- **A instalação do Godot 4.6.2 não foi obtida neste ambiente.** Não foram executados F5, shaders GPU, screenshots reais, NPCs, campanha completa, 88 regiões, testes nativos de saves ou benchmark no PC alvo. PASS estático não equivale a bug resolvido em gameplay.

## Escopo ainda bloqueado — NÃO declarar integrado ao gameplay
- Dungeon host/recovery/loot; incompatibilidade entre recibos Dungeon e Itens R3.
- Forja Monumental reservas/estações reais/interiores; API Narrativo×Mestres para matrícula e técnicas.
- Bestiário spawn/dano/XP e visuais; skins legadas 480 PNGs sem comprovação comercial; controle de qualidade do WorldGen, HDR/Shader e rigs na Godot.
- Mapa TAB, missão de ruínas legada, poses por arma, travamento de voo, FPS e teste comercial continuam como pendências, não correções declaradas.

## Ordem da próxima rodada
1. Em Godot 4.6.2 Compatibility, importar o projeto em **cópia isolada** e corrigir eventuais erros reais de parser/shader.
2. Rodar `res://convergence/tests/qa_rig01_eight_directions.gd`, Core 01-P nativo e regressões Cidade Viva. Confirmar visualmente 8 direções, inclusive armas e roupas voxel.
3. Rodar uma campanha nova diretamente na seed/região procedural, testar 88 conexões/dungeons/NPCs/seeds/saves, sem alterar saves pessoais.
4. Resolver contratos Dungeon×Itens, Narrativo×Marcial e host de interiores antes de registrar funções staged; rodar testes de falha e rollback.
5. Executar comparação FPS e P95/P99 no Ryzen 3200GE / Vega 8; auditar proveniência antes de distribuir comercialmente.

**Este ZIP é um checkpoint completo do código Alfa R2, com fontes staged, não uma versão estável ou uma segunda integração concluída.**
