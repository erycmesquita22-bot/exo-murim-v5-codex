# EXO-MURIM — INSTRUÇÕES OFICIAIS DE CONTINUAÇÃO — CONVERGÊNCIA 03 ALFA R4

Última base: **EXO-MURIM-CONVERGENCIA-03-ALFA-R4.zip**. Não iniciar da R3/R2/Cidade Viva; não realizar novo merge geral nem criar Convergência 04. Este arquivo substitui as instruções antigas como fonte atual para Work.

1. Conferir SHA-256 do ZIP R4 usando `MANIFESTO-R4.json` ou TXT externo; preservar ZIP original e abrir cópia.
2. Ler `C03_TRANSFERENCIA/RELATORIO-C03-ALFA-R4.md`, `QA-C03-ALFA-R4.json`, `ESTADO-INTEGRACAO-C03.json`; documentos R1-R3 apenas históricos.
3. **Prioridade:** rodar import/compilação **Godot 4.6.2 Standard Compatibility** e corrigir errors; testes `res://exo_bestiary/tests/qa_c03_r4_regional_fauna.gd`, `res://exo_core/tests/qa_core_integrations_r3.gd` e regressão Core Persistence/RIG.
4. F5: confirmar nas regiões selvagens a fauna voxel real, comportamento, ataque/inimigo único, recolhimento com E, loot `hide`/`fang`, saves/reopen e frequência. Verificar que nenhum segundo ecossistema foi criado.
5. Testes adversos: 23/24 slots, pending_loot lotado, falha no save e recuperação da morte, dois saves e replay, visitar mesma região/seed, ida e volta e 88 regiões, performance Vega8. Não declarar sucesso sem logs/screenshot/medidas reais.
6. Sistemas ainda incompletos: Dungeon real, Itens Procedurais R3 completo, Forja Monumental real, Mestres, harmonização GLB e Humanoides. Preservar gates de Core e quarentena comercial.
7. Entregar ZIP completo atualizado, relatório de testes reais (PASS/FAIL/NOT_RUN), hashes, evidências, diffs e pendências. Preservar R4 para rollback.

## Controles do novo sistema

`ProjectSettings` `exo_murim/r4/fauna_enabled=true`; desligar para triagem de regressão sem tocar em save/WorldGen. O Bestiário só instancia fauna quando `bestiary.catalog` e `bestiary.combat` estiverem registrados. O ator é `regional_fauna_actor.gd`, a ecologia continua sob `regional_ecology/director.gd`. Não usar qualquer GLB/PNG de proveniência não confirmada.
