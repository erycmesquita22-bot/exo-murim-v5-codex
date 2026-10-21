# EXO-MURIM / R7 → R8 / Work

**ÚNICA BASE:** `EXO-MURIM-CONVERGENCIA-03-ALFA-R7.zip` produzida neste chat. Confirmar SHA-256 em `EXO-MURIM-C03-ALFA-R7-SHA256.txt` antes de extrair. Nunca recomeçar da R6/Cidade Viva. Não criar Convergência 04.

1. Abrir uma **cópia** do projeto em Godot 4.6.2 Standard/Compatibility. Não modificar ou apagar `user://` dos jogadores. Conferir `C03_TRANSFERENCIA/RELATORIO-C03-ALFA-R7.md`, `QA-C03-ALFA-R7-MATRIZ.json`, `RESERVAS-E-COMPLEXOS-R7.json` e `DIFF-C03-R6-R7.patch`.
2. `godot --headless --editor --path <raiz> --import --rendering-method gl_compatibility` com log de erro e exit code; corrigir parser/GLB nativos sem trocar scripts por versões anteriores.
3. `godot --headless --path <raiz> --script res://exo_monumental/tests/qa_c03_r7_native.gd` e `res://exo_monumental/tests/qa_native.gd`. Inspecionar resultados PASS/FAIL, logs físicos e erros de import.
4. Reexecutar `res://exo_dungeon/tests/qa_c03_r6_native.gd`, `res://exo_core/tests/qa_core_integrations_r3.gd`, `res://exo_items/tests/qa_atomic_r3_native.gd` e as suites City Viva R2; não declarar sucesso sem rodar.
5. Nova campanha seeds 101, 816204, 707, 18026; testar cidades 78, rios 14/26, centros urbanos e ruínas. Contar e capturar sítios aceitos e rejeitados. Não inventar métricas para seeds não testadas.
6. Interiores: testar quatro orientações, E para entrar/sair, física da porta, player único, salvamento e reinício dentro e fora, morte, falha de escrita, não persistência de coordenadas interiores como exteriores. Garantir retorno ao mesmo edifício.
7. Aulas/matrículas e NPCs ainda não estão homologados em monumentos: estação semanticamente publicada não implica rota física funcional. Só integrar ao módulo Mestre com pathfinding e QA.
8. Bench comparativo na Vega 8 (p50/p95/p99 frametimes, memória, load), reportar equipamento real.
9. Corrigir bugs no R8 incrementalmente, com novo ZIP integral, hashes, log, QA, diff e rollback pareado. Preservar R7 imutável.

**Feature flags:** `[exo_murim] r7/monuments_enabled=true`, `r7/institutional_interiors_enabled=true`. Reservas persistidas não devem ser redistribuídas quando feature flag é desligada.
