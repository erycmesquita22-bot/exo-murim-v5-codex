# QA nativo e benchmarks — plano ainda não executado

Ambiente-alvo: Godot 4.6.2 Standard, Compatibility, Windows no PC Ryzen 3200GE/Vega 8/8 GB declarado pelo proprietário. O HARDWARE.json enviado informa Vega 8 e 5,93 GiB de RAM disponível ao sistema; registrar RAM instalada/disponível separadamente em cada rodada. Não equiparar host llvmpipe ao PC alvo.

## Isolamento e critérios gerais

Antes de executar qualquer script, usar CÓPIA do projeto e user-dir exclusivo de QA (o `project.godot` original define `EXO-Murim-Convergencia-01`). Revisar scripts que acessam `user://` e impedir acesso à campanha real. Preservar cópias .json/.bak/.tmp e SHA antes/depois. Importação, teste e export não devem escrever em originais.

Estados permitidos: PASS com evidência; FAIL com asserção/erro reproduzido; NOT_RUN sem execução; BLOCKED_DEPENDENCY sem contrato/módulo. Saída 0 sozinha não basta se há SCRIPT ERROR, ERROR ou asserção FAIL. Ausência de motor não é FAIL. Contagem de asserts Python não é teste GDScript.

## Comandos reais e disponibilidade

Os caminhos abaixo foram encontrados nas entregas (base ou módulo indicado). Executar os scripts de módulos somente DEPOIS da integração daquela fase e conferência de preloads. Variáveis são locais à sessão de QA; substituir os dois caminhos.

```bash
GODOT_BIN=/CAMINHO/Godot_v4.6.2-stable_linux.x86_64
QA_PROJECT=/CAMINHO/COPIA-QA-ISOLADA
mkdir -p evidencias-qa
"$GODOT_BIN" --version
"$GODOT_BIN" --headless --editor --path "$QA_PROJECT" --import --rendering-method gl_compatibility > evidencias-qa/import.log 2>&1
"$GODOT_BIN" --headless --path "$QA_PROJECT" --script res://exo_core/tests/qa_core.gd > evidencias-qa/core.log 2>&1
"$GODOT_BIN" --headless --path "$QA_PROJECT" --script res://exo_core/tests/qa_persistence01p.gd > evidencias-qa/01p.log 2>&1
"$GODOT_BIN" --headless --path "$QA_PROJECT" --script res://exo_items/tests/qa_atomic_r3_native.gd > evidencias-qa/items-r3.log 2>&1
"$GODOT_BIN" --headless --path "$QA_PROJECT" --script res://npc_system02/tests/qa_logic.gd > evidencias-qa/npc-r1.log 2>&1
"$GODOT_BIN" --headless --path "$QA_PROJECT" --script res://npc_system02/tests/qa_r2_logic.gd > evidencias-qa/npc-r2.log 2>&1
"$GODOT_BIN" --headless --path "$QA_PROJECT" --script res://npc_system02/tests/qa_r2_world.gd > evidencias-qa/npc-world.log 2>&1
"$GODOT_BIN" --headless --path "$QA_PROJECT" --script res://exo_dungeon/tests/test_core_contract.gd > evidencias-qa/dungeon-contract.log 2>&1
"$GODOT_BIN" --headless --path "$QA_PROJECT" --script res://exo_dungeon/tests/run_mechanics_qa.gd > evidencias-qa/dungeon-mechanics.log 2>&1
"$GODOT_BIN" --headless --path "$QA_PROJECT" --script res://exo_monumental/tests/qa_native.gd > evidencias-qa/forja.log 2>&1
"$GODOT_BIN" --headless --path "$QA_PROJECT" --script res://exo_martial/tests/qa_r2_native.gd > evidencias-qa/martial.log 2>&1
"$GODOT_BIN" --headless --path "$QA_PROJECT" --script res://exo_humanoids03_r2/tests/qa_native.gd > evidencias-qa/humanoids.log 2>&1
```

Base Cidade Viva: também foi encontrado `cidade_viva/tests/run_validation.py`; executar em uma cópia isolada com o caminho do motor, preservando o escopo acelerado/fixtures descrito pelo produtor. As 23 suítes históricas estão enumeradas em `cidade_viva/validation/RESULTADOS-CIDADE-VIVA-01-R2.json`. Reexecutá-las após a fase que altera contratos, ajustando somente expectativas explicitamente versionadas.

**Pendências de automação:** a existência das suítes acima não comprova todos os cenários a seguir. Falhas de I/O, 100k instrumentados, treino trusted, trânsito de salões e benchmarking pareado exigem drivers/fixtures no trabalho futuro dos owners. Não entregar PASS preenchendo JSON manualmente. O KIT PC CORRECAO-03 atual precisa primeiro conserto de indentação e revisão da rota segura; não executar como referência aprovada.

## Matriz de cenários de aprovação

| Caso | Preparação e ação | PASS | Falha / prova a guardar |
|---|---|---|---|
| Boot e criação | Campanha nova, seeds 101/816204/707/18026, classic/slim | Menu/criação → mundo procedural direto, seed correta, personagem apoiado, sem vila legada | Vídeo/captura, log, ID região, save inicial; spawn inválido é FAIL |
| 88 regiões | Validar grafo e gerar todas; depois atravessar conexões com player real, cobrindo todas as 88 regiões | IDs estáveis, conexão bidirecional prevista, spawn/colisão/retorno, sem perder estado | Registro por seed/região/aresta, geração ms; geração de dados sozinha não aprova caminhada |
| Cidade e rios | 14/26/78 nas seeds em que o atlas dá assentamento/água; fixtures adicionais se preciso | Escola/rua/água/muro/portão sem sobreposição, piso e cápsula atravessam acesso | Screenshots com seed e coordenadas; não presumir que os mesmos IDs são cidades em toda seed |
| Forja | Média/grande, 4 yaw, margens/cantos/rios/vias/declive reais | Reserva antes do lote, acesso 5m previsto, portas/escadas transitáveis, reapply idempotente | Recibo real, AABB, raycast/cápsula, rejeições corretas; flags sintéticas não bastam |
| Salões | Escola relevante, comércio funcional e outros tipos realmente suportados | Cena interior própria, único player, estado preservado e saída na porta exterior | Log de transição, morte/save/reboot; descriptor sozinho não é PASS |
| NPC | 24h jogo com simulação normal, câmera ativa, entrar/sair, conversar/perigo | Trabalhar/conversar/dormir/patrulhar; sem filas persistentes/colisões; visibilidade não mata simulação lógica | Trajetos e horários por ID; comparação população/snapshot/reopen; fixture isolada em 5Hz tem resultado separado |
| Dungeon transição | Entrar E, explorar, sair; falhar cada checkpoint; crash em entering/inside/leaving | Snapshot nunca grava posição interna como exterior; recovery piso+cápsula; itens/contexto preservados | Save antes/depois, logs por stage, processo novo; callbacks fake não aprovam host |
| Dungeon versões | Fixtures V2/V3 já persistidas e V4 nova | ID/digest/planta mantidos para V2/V3; sem reroll em update/reopen | JSONs e digests comparados, física nativa e portas/chaves reais |
| Dungeon gameplay | Entrada autorizada, encounter real, armadilha com dano, loot, saída, reboot | Inimigo/dano/XP pelo owner, recibos e itens um commit, prêmio não reaparece | Captura nativa, snapshots/UIDs; sinais de mock/intent são insuficientes |
| Loot 23/24 | Slots 23 e 24, pilhas até99, pacote que cabe e que excede | All-or-nothing; inventário cheio mantém pending e sem receipt | Snapshot JSON; quantidade/UID sem duplicação, sem split não autorizado |
| Replays | Mesma fonte 1000x, resposta perdida, duas fontes/boss mesma geração | No máximo uma concessão e recibo coerente; mesmo ID/payload diferente rejeitado | Contagens e hashes do save; diferentes gerações só conforme regra oficial |
| Corrupção/I/O | Primário inválido; bak/tmp válidos; backup pré-migração inválido não vazio; falha de write/rename | Recovery usa fonte válida, falha fechada, snapshot de RAM reposto, pending mantido | Logs de injeção e reopen; não lotar disco do usuário ou adulterar save real |
| Efeitos de listeners | Quest/narrativa/XP/UI durante falha de stage/save | Nenhum fato externo irreversível antes do commit, sem XP/quest dupla | Snapshot de todos domínios e objetos externos; publicação não equivale a persistência |
| Fauna/IA | Cervo/lobo, javali territorial, grupos, humanoides distintos, elite/chefe | Dano e fuga reais, janelas de ataque, morte/loot/ecologia por ID/generation; reaparecimento coerente | Sequência nativa e save/reopen em combate; faltantes visuais não substituídos silenciosamente |
| Marcial | Matrícula, treino, promoção, saída/expulsão/transferência, mestre morto | Relação só Narrativo; provas e custos reais; reveal/learn oficial; tickets e taxas sem replay | Saves e IDs; mock ou escrita direta known/learned causa FAIL |
| Equipamento/poses | 64x64 classic/slim, outer layer, EXO256, armadura, desarmado, roll360/2M/lança/adaga | Corpo/UV oficiais, arma acompanha animação, bainha coerente, sem segunda arma flutuando | Capturas nativas por pose/arma e clipes; catálogo não prova clipping zero |
| Missões/mapa/input | Explorar ruínas, I/TAB/F/E/R/P, mapa em troca região/interior | Missões concluem pelo owner; mapa correto e legível; botões oficiais sem conflito com UI | Capturas e save; não assumir I implementado apenas porque é requisito aprovado |
| Estabilidade | 30min gameplay por build, cidades+viagem+combate; sessão adicional longa | Sem crash/erro, memória estabiliza, frames dentro do orçamento proposto | Logs/capturas/métricas brutas; PC e host reportados separadamente |

## Benchmark pareado

Comparar C01 base antiga e C11 integrada no MESMO hardware, engine, resolução, driver, preset gráfico e câmera. Seed 101 região78 é referência histórica; comparar geometrias equivalentes e indicar quando monumentos mudarem a carga. Rodar uma build por vez, simulação ativa, câmera/rota repetíveis, aquecimento 60s + amostragem 180s, 3 repetições por condição. Desligar vsync/limites de FPS de forma idêntica ao medir; registrar configurações, não usar `--fixed-fps` para números de desempenho. Sessão humana pode usar vsync separado.

Capturar FPS médio/1% low, frametime P95/P99 a partir dos intervalos reais, geração por região, commit wall-time P50/P95/P99 com 10k e 100k recibos, load/reopen em processo novo, bytes do JSON, RAM/RSS e memória Godot, CPU com escala informada, draw calls, objetos/nós/meshes/materiais/colliders. `world.save_progress` e validação/serialização fazem parte do custo de commit; não cronometrar só Ledger.put. Registrar EventBus.publish e suas cópias profundas sob 100k. Evitar duplicar medidas cumulativas ou usar instantâneo do Task Manager como média.

**Orçamentos propostos para decisão, não metas já aprovadas nem resultados:** gameplay ≥30FPS no alvo; regressão de mediana/P95 de frames ≤10% em cena equivalente; P95 frame ≤40ms e P99≤66,7ms como alvo inicial; save P95≤250ms com10k e ≤1000ms com100k, reportando travamentos visíveis separadamente; memória sem crescimento contínuo em viagens repetidas. Se esses limites não forem adequados ao design, registrar orçamento acordado antes da promoção; nunca mover o limite só para transformar falha em PASS. Falhar capacidade física/recibos/corrupção é bloqueio funcional independentemente de FPS.

## Rastreio dos problemas já relatados

TAB/UX: HUD+map_view; vazio e bordas: WorldGenesis+conteúdo; poses/bainhas/rolagem/2M: Arsenal+Rig+Wardrobe; clipping/adornos: Arte Humanoides; colisão/filas: Resident/NPC+World; ruínas: MurimFlow/Jornada; voo: Locomoção/Técnicas; vila inicial: Flow+Convergence. Nenhum é declarado corrigido nesta auditoria.

## Evidência mínima por execução

Commit e SHA da build, engine --version, SO/CPU/GPU/driver/RAM, resolução/preset, seed/região, comando exato e exit code, stdout/stderr completos, JSON/CSV bruto, logs de falhas preservados, capturas de viewport real identificadas, hashes de saves antes/depois e conclusão com limitações. Separar resultados antigos do checkpoint, tentativas falhas e rodada final. Render conceitual não é captura Godot.
