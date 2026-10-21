# Mundo Vivo 02 R2 — validação funcional e correções

Data: 19/10/2026. Base: EXO-Murim-Mundo-Vivo-02-R2-POLIMENTO-CANDIDATO.zip. Continuação incremental; nenhum sistema novo de gameplay. Godot 4.6.2 Standard oficial, Compatibility.

## Resultado

PASS nos sete processos funcionais principais: **126 verificações**, todos com saída 0. Combate regional com IA e HP normais, persistência entre processos, um dia inteiro de rotinas e persistência do equipamento foram executados na Godot. O projeto recebeu duas correções locais. A rodada automatizada foi concluída; isto não substitui uma sessão humana nem certifica desempenho em hardware não testado.

| Área | Resultado | Evidência |
|---|---|---|
| Dano recebido, derrota e saque | PASS | lifecycle_A: dano real de 9, inimigo com 60 HP, 16 XP, coleta por proximidade |
| Grupo parcialmente derrotado após fechar/reabrir | FAIL inicial → PASS | lifecycle_B-before.json; lifecycle_B.json; identificação numérica corrigida |
| Grupo completamente derrotado, saída e retorno regional | PASS | lifecycle_B: 12 verificações |
| Reabertura e renovação após seis horas do jogo | PASS | lifecycle_C: 8 verificações; espera física do relógio até 540 segundos; UID da nova geração g0001 |
| Combates repetidos e redutor | PASS | repeat_combat: 12 derrotas, 74 verificações; XP 16×8 e 13×4 |
| Equipamento gerado, coleta e uso | PASS | item_4 recolhido e equipado; inventory_reopen: instância, atributos e UID preservados em outro processo |
| Dia completo de NPCs | PASS | npc_day: 2.160 segundos simulados, 65 moradores, 13 verificações |
| Persistência dos moradores | PASS | npc_reopen: identidades, moradia, profissão, conversas, ciclos e visitas; 65 IDs únicos |
| Rotinas históricas atualizadas | PASS | 27/27; aldeia 86 e cidade 78; deslocamento, praça, abrigo, obstáculo temporário e retorno |
| Atlas e geração | PASS | 2.048 planejamentos nativos, 180.224 regiões lógicas, 32 repetições; não são 180.224 cenas físicas |
| Planejamento ecológico | PASS | 193.914 verificações nativas com MockData; complementam os testes físicos |
| Integração física | PASS | 91 verificações em 13 regiões/combinações de seeds; sete pilotos com caminhada real |
| Regressões renderizadas | PASS | assets: 30/30; playable: 14/14, movimento, corrida, salto, esquiva, ataque, técnicas, missão, inventário e menus |
| Capturas reais | PASS | seis PNGs, processo com saída 0; nenhum conceito ou imagem gerada |
| Desempenho no Work | MEDIDO | comparação abaixo, processos sequenciais e FPS livre |
| Jogabilidade humana, áudio perceptivo, Android e PC do proprietário | NOT_RUN | nenhum resultado presumido |

## Defeitos encontrados e correções

1. **Persistência de grupo parcial — bug real.** O JSON restaura números como floats. A busca de um inteiro em members_dead não reconhecia o membro já morto, permitindo seu reaparecimento. regional_ecology/director.gd agora normaliza IDs para inteiros e remove repetições antes de verificar spawn e recibo de derrota. Reproduzido em outro processo antes da correção; revalidado em B e C. Nenhum schema de save ou UID foi substituído.
2. **Pontos de trabalho sobrepostos — bug real.** Três posições calculadas por hash atendiam mais de três trabalhadores. A distância mínima entre destinos era 0 m. convergence/region.gd agora reutiliza a estação individual já reservada na fachada. A distância mínima entre destinos de trabalho da cidade testada passou a aproximadamente 1,50 m. O teste do dia inteiro confirmou chegadas, movimento e ausência de penetração de edifícios nas amostras de cápsula. Esse valor mede destinos, não uma distância mínima garantida entre todos os pedestres durante cruzamentos.
3. **Teste de rotinas obsoleto.** convergence/routine_qa.gd ainda usava 3.600 segundos por hora e esperava work_slot, enquanto o contrato atual usa 90 segundos e @activity. A execução original terminou com saída 1 e seis falhas. O teste agora fixa cada horário apenas durante sua fixture de deslocamento e mantém as verificações de chegada, colisão, praça, abrigo e recuperação. O teste separado npc_day avança livremente o relógio padrão por 24 horas, sem pular horários.
4. **Fixtures corrigidas.** A primeira tentativa B não retomava o menu após carregar; o sobrevivente não aparecia porque a simulação estava pausada. O roteiro passou a retomar o jogo. Uma tentativa de saquear antes de eliminar o grupo terminou em morte real do personagem: não foi classificada como bug de loot. O roteiro final elimina o grupo antes da coleta. Os FAIL anteriores permanecem nos resultados e logs.

O gate histórico inicial executou 38 grupos: 37 PASS e um FAIL em routines012. Após atualizar a fixture, routine_qa e routine_reopen foram executados novamente e saíram com código 0. O FAIL inicial permanece registrado; o comando inicial completo não foi reclassificado como saída 0. Não houve outra falha remanescente nos grupos executados.

## Limites dos roteiros

O combate usa entradas automatizadas, dano, colisão, armas e IA originais. A vida do jogador é restaurada entre duelos no teste de repetição e há proteção por cura no helper quando necessário; não se trata de uma maratona humana sem cura. Os inimigos regionais não recebem redução artificial de HP. O teste legado renderizado tem seu próprio alvo estacionário e fixture de missão, identificados no log.

O XP regional permanece no banco ecológico existente; não se afirmou aumento do nível normal do personagem. Os limiares de 55% e 35% foram verificados por fixtures de contagem na Godot; somente a transição de 100% para 80% foi alcançada pelas 12 derrotas físicas desta rodada. A distribuição natural de acampamentos e o dia de 36 minutos limitam quantas derrotas da mesma categoria são possíveis por região/dia; os níveis superiores de redução podem não ser alcançáveis naturalmente em alguns territórios.

Sete profissões observadas: comerciante, curandeiro, agente da guilda, morador, mensageiro, discípulo e mestre. Discípulos/mestres alternaram treino e meditação; demais trabalhadores fizeram ciclos de trabalho; mensageiros registraram viagem/espera. Todos os 65 chegaram ao trabalho, deslocaram-se, entraram no proxy de descanso e retomaram a rotina. Houve diálogo com incremento persistente e retomada de ciclos após interrupção. Abrigos são proxies nas entradas; não há navegação interna. A ausência de penetração foi amostrada a cada meia hora do jogo, não provada para cada instante.

## Desempenho antes/depois

Ordem em cada célula: **R2 original / R2 corrigida** (tag interna R3). Seed 101, 1.152×720, perfil Equilibrado, Godot 4.6.2 Compatibility, Mesa llvmpipe LLVM 20.1.2 por software, VSync solicitado desligado, sem --fixed-fps. Mesmos scripts e roteiro. Uma execução de cada versão, sequencial e sem outros testes da rodada concorrentes; 40 quadros de aquecimento e 180 amostras por cena. O driver avisou que não suporta alterar VSync; o estado efetivo de VSync não foi confirmado. Uma amostra curta por cena não demonstra ganho sustentado de desempenho. Os valores são do Work, sem estimativas para outro computador.

| Cena | FPS médio | P95 quadro ms | Memória estática MiB | Entrada/troca ms | Nós | Moradores | Edifícios |
|---|---:|---:|---:|---:|---:|---:|---:|
| city | 11.9 / 13.6 | 106.2 / 80.1 | 262.1 / 262.1 | 5089 / 5143 | 26157 / 26157 | 65 / 65 | 43 / 43 |
| enemies | 21.9 / 23.2 | 54.6 / 50.7 | 133.8 / 133.8 | 1316 / 1265 | 4453 / 4453 | 0 / 0 | 1 / 1 |
| village | 19.1 / 18.1 | 59.6 / 65.5 | 145.8 / 145.8 | 1539 / 1523 | 6064 / 6064 | 6 / 6 | 4 / 4 |
| legacy_combat_training_fixture | 17.5 / 17.3 | 64.2 / 64.5 | 99.4 / 99.4 | 61 / 77 | 2489 / 2489 | 0 / 0 | 0 / 0 |

Pico RSS total do processo ao longo das quatro cenas: R2: 784.3 MiB, R3: 785.9 MiB. Memória estática da Godot e RSS são medidas diferentes. Os JSONs incluem tempos médios de quadro, física/processamento, chamadas de desenho, inimigos ativos e todas as amostras brutas. A troca ao recinto inclui liberação da região anterior; tempos de geração dos assentamentos constam também nos resultados de integração. Custos GPU separados não foram medidos: NOT_RUN. O cenário de combate legado mede ataques e técnica contra alvo de treino com colisão/dano reais, com IA dos inimigos legados desativada; o teste funcional de combate regional mantém IA ativa.

## Preservação e entrega

main.gd, rig.gd, arsenal.gd, inventory.gd, journey_save.gd, controladores marciais, convergence/game.gd e convergence/resident.gd permanecem idênticos à base; hashes em preservation.json. Os únicos scripts de produção alterados são convergence/region.gd e regional_ecology/director.gd. O grafo de 88 regiões, texturas, modelos, HUD e sistemas de progressão permanecem os existentes.

As capturas de aldeia, vila, escola marcial, território, encontro e montanhas vêm do viewport da Godot. Câmeras de jogador e panorâmicas são identificadas no script; o observador é reposicionado para inspecionar os locais. Não são evidência de exploração humana contínua. As seis capturas R2 anteriores são incluídas separadamente para comparação, sem montagem sobreposta.

## Reprodução

Importe o projeto uma vez na Godot 4.6.2 Standard. A entrada normal é convergence/game.tscn. Na raiz do projeto:

```text
python validation_r3/run_functional.py /caminho/para/Godot4.6.2
python tools/run_convergence012_checks.py /caminho/para/Godot4.6.2
godot --headless --fixed-fps 60 --path . --script res://regional_ecology/qa_massive.gd
godot --path . --fixed-fps 60 --script res://validation_r3/capture.gd
godot --path . --script res://validation_r3/benchmark.gd -- R3
godot --path . --script res://assets_qa.gd
godot --path . --fixed-fps 60 --script res://convergence/legacy_playable.gd
```

O helper funcional abre processos separados para A, B, C, repetição de combate e recargas. Os caminhos de saves são exclusivos de QA. O teste de dia inteiro percorre 129.600 passos físicos a 60 Hz; --fixed-fps é usado somente nos testes funcionais, nunca nas medições de FPS. Não executar benchmark junto com outras suítes.

Logs atuais em validation_r3/logs e convergence/validation012/final; resultados estruturados em validation_r3/results. Os logs/relatórios mais antigos do projeto são históricos. O stdout de lifecycle_A ficou parcial no arquivo desta rodada; seu JSON completo contém 9 verificações e o processo foi observado terminando com saída 0. Não foram inventadas linhas ausentes de log.

Próxima validação recomendada: sessão humana no PC do proprietário para leitura visual, sensação de combate e visibilidade; campanha de desempenho com repetições mais longas e metas de FPS definidas. Sem necessidade de acrescentar sistemas nesta rodada.

Validação de extração limpa: {"status": "PASS", "import_exit": 0, "rendered_boot_exit": 0, "rendered_boot_frames": 45, "cache_in_zip": false, "engine": "4.6.2 Standard Compatibility", "scope": "Fresh extraction of candidate ZIP; import and main-scene boot. Final repack adds only results/report."}.
