# QA nativo obrigatório — R9/R10/Work

**Base EXCLUSIVA**: `EXO-MURIM-CONVERGENCIA-03-ALFA-R9.zip`. Conferir SHA em arquivo de entrega, extrair em cópia, Godot 4.6.2 Standard Compatibility. Não reutilizar a Cidade Viva antiga/R8 nem iniciar Convergência 04.

```bash
GODOT=/caminho/Godot_v4.6.2-stable_linux.x86_64
ROOT=/caminho/EXO-C03-R9-COPIA
"$GODOT" --headless --editor --path "$ROOT" --import --rendering-method gl_compatibility > qa-r9-import.log 2>&1
"$GODOT" --headless --path "$ROOT" --script res://convergence/tests/qa_c03_r9_native.gd > qa-r9-contract.log 2>&1
"$GODOT" --headless --path "$ROOT" --script res://convergence/tests/qa_c03_r8_native.gd > qa-r8-contract.log 2>&1
"$GODOT" --headless --path "$ROOT" --script res://exo_martial/tests/qa_r2_native.gd > qa-r2-martial.log 2>&1
"$GODOT" --headless --path "$ROOT" --script res://exo_monumental/tests/qa_c03_r7_native.gd > qa-r7-monuments.log 2>&1
"$GODOT" --headless --path "$ROOT" --script res://exo_dungeon/tests/qa_c03_r6_native.gd > qa-r6-dungeons.log 2>&1
"$GODOT" --headless --path "$ROOT" --script res://exo_core/tests/qa_core_integrations_r3.gd > qa-r3-core.log 2>&1
```

**Separar exit code e warnings/errors do log.** Corrigir import, compilação e RIG antes de considerar gameplay.

## Cenários manuais e instrumentados

1. Seed 101 / 816204 / 707 / 18026: regiões 78/14/26, cidades/towns, monumental R7. Registrar quantos `martial_medium/grand` realmente são aceitos; quantos slots `martial` são criados; quantos foram rejeitados por estrada/parede; nunca inventar resultados. Uma POSSIBILIDADE de currículo Jade sob derivação estática é seed 816204 região 26, MAS o site pode ser rejeitado no WorldGenesis: não anunciar como garantido.
2. Nova campanha: localizar escola real e aguardar NPC `master` percorrer caminho desde lot/rua até `master_station`, verificando rig, orientação, corpo, paredes, colisão e rotina 12–16h. Confirmar identidade/currículo persistentes após sair/voltar, save/reopen e alternância dia/noite. Não injetar NPC de QA na release.
3. E mestre: consulta→candidatura→matrícula atômica R8; recusar nível/trust/reputação/vaga/escola incompatível, recibo repetido e prova de trial ausente. Falha I/O do save deve restaurar narrativa e marcial juntos.
4. Jade somente: mestre presente no pátio de escola construída, currículo válido, técnica elegível; E novamente para aula; E no círculo físico, imobilidade e observação de `work_cycles` real. Medir tempo de 3/5/8 segundos, saldo Qi/stamina antes/depois, recibos únicos, tentativa duplicada, interrupção por movimento, inimigo, combate, morte, saída de região, desativação de flag.
5. Completar aula e gerar `pending_unlock`: usar `Cultivation.stage_martial_reveal/learn` com `Engine.confirm_core_unlock` no **mesmo save**. Injetar falha de I/O e verificar rollback. Salvar/reabrir em outro processo e checar técnica em known+learned + estado Marcial sem pendência, mantendo 3 slots iniciais.
6. Acompanhar medidores de Qi e stamina ao reabrir: runtime original pode resetar medidores; consertar persistência de energia se isso permitir exploração, sem criar segunda carteira. Testar estresse/replays e limites de receipts.
7. Regressão R7 (cidades, rios 14/26, portas 4 yaw, interiores), R6 (dungeon E, encontros, tesouros/loots), R5 (20 GLB, 13 fauna e 3 fallback), R4 (fauna combate/loot), R3 (Core), R2 (armas/cotovelos, fluxo procedural), mapa TAB, HUD Qi e missão ruínas.
8. Perfil Ryzen 3200GE / Vega 8 8GB: coletar FPS p50/p95/P99, draw calls e memória, comparando seed/região/quality idênticos; não confundir llvmpipe com GPU alvo.

## Segurança e continuação

- NÃO liberar as outras oito escolas antes de suas provas por atividade real e estação correspondente.
- Validar se a ocupação R9 é suficientemente frequente: a rota fail-closed pode legitimamente produzir zero mestres; buscar melhoria autoritativa no WorldGenesis/NPC caso os testes indiquem bloqueio excessivo.
- Terrain Forge continua ramo R6 separado, exige merge seletivo auditado mais tarde.
- Se quaisquer gates falharem, manter flag R9 desativada; preservar ZIP R8 e seus saves de QA como rollback. Entregar R10 somente após evidência nativa ou com pendências NOT_RUN explícitas.
