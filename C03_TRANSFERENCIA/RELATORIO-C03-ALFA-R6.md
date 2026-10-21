# EXO-MURIM — Convergência 03 Alfa R6 — relatório técnico

**Estado:** integração de código candidata, **NÃO HOMOLOGADA**. Base exclusiva `EXO-MURIM-CONVERGENCIA-03-ALFA-R5.zip`, SHA-256 `0b8362c083d4c42ebbf412acfb4fa9b74a5a404b963848233291ffc2efb5e7eb` conferido; 0 arquivos originais removidos; os antigos geradores V2/V3/V4 e scripts visuais R5 estão intactos.

## Alterações concretas

1. **Dungeon como conteúdo físico:** a ponte de entrada E R3 permanece, e a dungeon cria cenas reais com o gerador oficial V4, materializador batched, paredes/colisões e retorno ao exterior. R6 adiciona detecção de proximidade, progresso de descoberta por sala e checkpoint de chaves, portões e segredos. Em falha de escrita, os dados voltam ao snapshot e a geometria da interação é reconstruída do estado autorizado.
2. **Encontros integrados ao combate:** `exo_dungeon/module/entrypoint.gd` produz os atores `res://enemy.gd` dentro de `world.enemies` do host; não criou outra IA. Instâncias nascem por proximidade (25m), orçamento máximo de 8 simultâneas, UID derivado da dungeon/encounter; encerramento no `convergence/game.gd` e XP pelo proprietário `regional_ecology/rewards.gd`, com checkpoint e reversão do ator em falha. Eliminação de encontros é salva no domínio de dungeon. NPCs/atores regionais externos ficam com `enabled=false` enquanto a visita está ativa e são restaurados ao sair.
3. **Coleta física de recompensa, único commit:** os pontos `plan.rewards` recebem marcador voxel original; `Explore.nearby` o reconhece com E. O módulo Dungeon valida dungeon ativa, marcador real e distância ≤3,2m, recompensa não reclamada e encontros de sala obrigatórios derrotados. O Core só aceita um `Callable(dungeon, "verify_reward_pickup")`, **não um `true` artificial**. O Inventário é dono de `queue_dungeon_pending`; `Atomic.prepare_pending` calcula um fingerprint e `confirm_pending` grava `items`, recibo `world.claim_receipts` e `dungeon_genesis.instances[*].reward_receipts` no **mesmo `world.save_progress()`** via `domain_stage`. Em falha, o snapshot RAM volta e o marcador continua disponível. Replays são recusados pelo domínio e ledger. Ainda não há prova nativa de crash/power loss.
4. **Morte e recuperação:** `combat/player_combat.gd` informa morte ao host Dungeon, que interrompe a visita, restaura exterior e registra recuperação no Core. O `snapshot_region` da base continua protegendo posições exteriores. O auto-save regional evita rodar NPC/relógio/cidade enquanto a dungeon está aberta.
5. **Chaves de opt-out:** `exo_murim/r6/dungeon_encounters_enabled` e `exo_murim/r6/dungeon_atomic_rewards_enabled`, ambas habilitadas para teste de candidato, podendo ser desligadas em `project.godot`.

## Limites técnicos importantes

- **Godot 4.6.2 NÃO FOI EXECUTADA:** não foi localizado binário local, e download oficial não acessível por DNS (`curl: (6) Could not resolve host`). Portanto, nenhum teste de parser GDScript, import GLB, F5, física, cena real, morte real, benchmark ou persistência nativa foi realizado. O código de integração pode conter erros de compilação e gameplay a corrigir na R7; não distribuir como build estável.
- Encontros R6 usam os **inimigos oficiais blade/mage**, não uma nova IA de chefes dedicada. Os 8 atores simultâneos representam o orçamento; encontros distantes são carregados conforme aproximação. O XP segue a progressão ecológica existente, sem segunda carteira. Não alegar combate completo de chefes.
- Recompensas ativadas nesta rodada ficam limitadas a **material ferro** (2–3 unidades) validado pelo inventário. Armas procedurais com 6 raridades/17 afixos, armaduras, acessórios e loot de chefes específico **não foram habilitados**. O contrato dos itens complexos requer QA adicional.
- Marcas de armadilha do Dungeon permanecem **visuais**; dano, gatilhos e desarme não estão completos. Segredos/chaves/portões são implementados no código, mas ainda carecem de prova F5. Recuperação após interrupções e tratamento de falhas físicas exigem teste nativo.
- A coleta física faz `prepare_pending` e `confirm_pending` no mesmo frame/salvamento sem arquivo paralelo; **não é prova ACID contra perda de energia** e não substitui o QA de `.bak/.tmp`, 23/24 slots, replay entre processos e falhas injetadas.
- As 13 identidades visuais R5, três fallbacks e todos os 20 GLBs continuam preservados sem alteração nesta R6. Proveniência comercial e skins legadas seguem pendentes.

## QA realmente executado

- `C03_TRANSFERENCIA/qa_r6_static.py`: **38 PASS / 0 FAIL**, varredura de 449 `.gd` e 371 `.json`, referências `preload`, hashes e preservação R5. As duas referências sem alvo são históricas em arquivos de laboratório (`godot/demo.gd`, `exo_core/module_template/test.gd`). Não é parser Godot.
- `exo_items/tests/qa_atomic_r3_offline.py`: **PASS** (modelo Python, 1.059 asserções, 1.000 replays simulados), não teste nativo.
- `exo_items/tests/offline_qa.py`: **PASS**, catálogo referencial Python.
- `exo_dungeon/tests/qa_r2_reference.py`: **PASS**, geometria referencial Python, não GDScript.
- `exo_dungeon/tests/static_audit.py`: **PASS** (23 verificações), sem arquivo externo de Core para repetição de ABI externa.
- `exo_items/tests/qa_scenarios_offline.py`: **HISTORICAL_WARNING** / saída 2 por hipótese do antigo teto de 2.048 eventos; não é prova de falha da migração Core 01-P atual.
- `exo_dungeon/tests/qa_r2_static.py`: **BLOCKED_FIXTURE**; exige arquivo histórico externo que não está no caminho rígido do teste.
- **11 suites native/GPU/hardware NOT_RUN**: Godot indisponível. Há teste GDScript novo `exo_dungeon/tests/qa_c03_r6_native.gd` para geração determinística, materialização, recibo atômico, replay e rollback; o arquivo **não foi executado**.

## Integridade e mudanças

Arquivos R5 modificados: **11**; novos: **26**; removidos: **0**. Veja `MANIFESTO-C03-ALFA-R6.json`, `DIFF-C03-R5-R6.patch` e `QA-C03-ALFA-R6-MATRIZ.json`. O relatório não afirma qualquer FPS medido nem captura gerada em jogo.

## Checklist obrigatório R7

1. Importar um clone integral em Godot 4.6.2 Standard Compatibility; executar o parser e `qa_c03_r6_native.gd`, `qa_core_integrations_r3.gd`, `qa_atomic_r3_native.gd`, `run_instance_qa.gd` e 23 suites Cidade Viva R2; corrigir todo FAIL antes de validar gameplay.
2. Testar E exterior/interior e dentro da dungeon, salas/corredores/piso, passagem secreta, chave/porta, andar superior, saída/volta à âncora, death/restart/reopen, GPU e colliders; registrar logs e capturas **reais**, seeds 101 e outras.
3. Testar combate com spawn e limite de 8, mortes, XP, fauna R5, fuga/leash/AI e repetição após mudar região; assegurar que NPC exterior retoma sem duplicação.
4. Testar premissa de **um único commit** no sistema de salvamento verdadeiro com 23/24 slots, coleta duas vezes, inventário cheio, interrupção antes/depois de salvar, escrita negada, corrupção e recuperação de `.bak/.tmp` em segundo processo; garantir que item, claim e dungeon sejam atômicos.
5. Avançar trap damage/desarme e chefes reais apenas depois de QA nativo; aprimorar loot procedural com autorização do domínio Inventário.
6. Medir FPS e memória em Vega 8/ Ryzen 3200GE, não inferir desempenho por testagem estática.

**Resumo:** R6 fez **nova integração funcional de código** de Dungeon/Itens, encontros, marcadores, progresso e recibos. A aprovação é **bloqueada** pela ausência de parser/F5 e testes adversos nativos.
