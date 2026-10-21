# EXO-MURIM — CONVERGÊNCIA 03 ALFA R8 — relatório técnico

**Origem EXCLUSIVA:** `EXO-MURIM-CONVERGENCIA-03-ALFA-R7.zip`, SHA-256 `b1c8e0dc59688c7d360daafa85abd47bb37bef205e5d3b20065e9e0b3dfc0163` (conferido em bytes locais). R7 e saves originais não foram editados. **Status:** candidato de código, **Godot 4.6.2 NÃO EXECUTADA**.

## Alterações implementadas de verdade no código

1. `exo_core/modules.json`: adiciona **um** registro de `exo_martial` R2 1.2.0 com dependências oficiais Narrative, Living World e Persistência. Preserva catálogo já oferecido por `martial.catalog`; não acrescenta autoridades de skill, NPC ou inventário.
2. `exo_core/core.gd`: `confirm_martial_enrollment_atomic` exige candidatura pendente no domínio Marcial, jogador canônico, mestre NPC real e prova contextual do host. O **owner Narrativo** faz `authorized_master_disciple.stage` e a máquina oficial `Engine.confirm` stageia matrícula no MESMO `JourneySave.data`. Validam-se ambas as estruturas, chama-se `world.save_progress()` **uma única vez** e retorna-se ao snapshot em qualquer erro. A antiga API de vínculo isolado rejeita `establish` se o Marcial estiver ativo, evitando relações órfãs.
3. `exo_martial/module.gd`: o método antigo `confirm_enrollment` de save separado agora falha fechado, exigindo o coordenador do EXO Core; o resto do módulo R2 continua proprietário de candidatura, status e estado educacional.
4. `convergence/martial_host_r8.gd`: adaptador do host com **mestre real** do `living_world.npcs` e instância `Resident`, role master ativa, presença física, estação `master_station` do Builder R7, sítio `martial_medium`/`martial_grand` realmente planejado, escola consistente e linha de visão. Não cria mestres/locais falsos nem teleporta NPCs. Exige disponibilidade do `NPC System 02` para confirmar vínculo; oferece E contextual com escola, requisitos e consulta de técnicas.
5. `convergence/game.gd`: liga o adaptador após o boot do Core e à interação original E, sem substituir as conversas/contratos de moradores comuns.
6. `project.godot`: opt-out `exo_murim/r8/martial_enabled`; os arquivos de WorldGenesis/Forja/Interiores/Dungeons/Itens/Fauna ficam byte a byte iguais à R7.

## Limite da integração de gameplay — sem triunfalismo

- Ciclo de **descobrir mestre, consultar escola, pedir candidatura e confirmação coordenada** é agora um fluxo de código concreto, sujeito a NPC/estação/requirements reais. NÃO há comprovação de que ao menos um mestre e uma escola coincidam e sejam alcançáveis nas seeds 101, 816204, 707 e 18026: isso exige carregar a cena na Godot. Não confundir "conectado" com "jogável aprovado".
- A R8 **não** forja provas de ingresso: `admission_attestation` devolve 0 provas/sem trial, de modo que escolas cujo catálogo exige avaliação ainda recusam matrícula. Escolas sem prova obrigatória ainda exigem nível, confiança, reputação e demais condições reais. Falhar é comportamento intencional.
- A API `configure_host_integrations` foi ligada ao host, mas `trusted_lesson_proof` **recusa** provas de prática/observação/duelo até existirem eventos e consumo real verificáveis. Portanto, aulas completas, exames, recompensas, `cultivation.learn()` e desbloqueio de técnicas **não foram ativados**. Nenhuma skill é entregue pelo menu.
- A condição da R7 de rota de NPC real até a estação permanece: sem nav física comprovada não atribuí um mestre artificial a cada escola. Esse bloqueio é necessário à primeira experiência totalmente funcional.
- Duas referências históricas de `preload` em laboratórios (`godot/demo.gd`, `exo_core/module_template/test.gd`) preexistem na R7 e devem ser verificadas durante o import nativo caso seus laboratórios sejam carregados.

## QA realmente realizado

- ZIP R7 SHA e CRC: PASS.
- Auditoria R8 de arquivos preservados, conectores, contratos, JSON e preloads: **4572 verificações estáticas PASS, 0 FAIL**, das quais a maioria compara um arquivo R7 por hash; NÃO são 4572 cenários funcionais independentes.
- **453 GDScripts** inspecionados somente em preloads literais, **384 JSON** parseados; ambas são análises Python de fonte, não compilação GDScript.
- Mestres R2: referência Python 152/152 PASS; Dungeon geométrica e Itens R3 referências Python PASS. Nenhuma delas executa o EXO-Murim.
- **Godot 4.6.2:** comando ausente, tentativa de GitHub sem acesso; importação, parser, execução, captura, save/reopen, matrículas reais, rotas NPC, dungeons, FPS e Vega 8: **NOT_RUN**. Nenhuma screenshot real criada.

## Terrain Forge

Candidato separado `EXO-MURIM-CONVERGENCIA-03-ALFA-R6-TERRAIN-FORGE-01-CANDIDATO.zip` foi localizado na Biblioteca. **Não foi aplicado nem convertido na base**. Especialmente `genesis/region_data.gd`, `genesis/region_scene.gd` e `project.godot` da ramificação não foram extraídos por cima da R7/R8. Futuro merge seletivo exige auditoria de hunk e testes de WorldGenesis/Forja.

## Pendências para R9 (ordem recomendada)

1. Import nativo e correção de qualquer erro de GDScript/GLB; 23 suítes Cidade Viva e R3–R8. Executar um teste real de matrícula em escola, seed, NPC, hora, status/reabertura e auditoria de persistência.
2. **Rotas reais de NPC mestre para estações R7**. Medir regiões 78, 14, 26 com seeds 101, 816204, 707, 18026; garantir mestre acessível e coerência da escola, sem teleporte.
3. Host trusted admission trials: provar eventos de avaliação no mundo, incluindo reputação, capacidade, facção e interações de tutor. Não usar callbacks `true` de laboratório.
4. Host trusted lessons: capturar eventos reais `watch/attack/dodge/meditate/duel`, recibo único, identidade de ação, posição e gasto efetivo Qi/stamina, sem conceder progresso inexistente.
5. Integrar ticket pendente via `cultivation.reveal/eligible/learn` e slots oficiais; salvar/reabrir, inject write failure/replay, testar mestre ausente/recusa/segunda escola.
6. Regressão R7 interiores e WorldGenesis; R6 Dungeon/Itens; R5 fauna; equipamento, HUD, mapa e desempenho no hardware-alvo.
7. Somente depois auditar a ramificação Terrain Forge, sem trocar a base integral.

## Checkpoint

R7 imutável; R8 é a única continuação autorizada. R8 inclui os relatórios R7 e R3–R6 herdados, matriz R8, manifesto de hashes, diff, QA reproduzível e instruções R9/Work. Nenhum save original foi aberto por Godot.
