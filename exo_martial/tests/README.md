# QA R2

`qa_r2_offline.py`: valida identidades, custos/referências oficiais, perfis, método/categoria, recibos no modelo de referência Python e determinismo de 12 mil perfis e 10 mil pares. **NÃO executa GDScript e NÃO valida arquivo save v4.** A distribuição já traz fixtures oficiais sob `tests/fixtures/core_skills_01.json` e `core_weapons_01.json` (somente auditoria); se existir `audit_core/` no workspace, o teste prefere o Core real. Revalidar snapshots após atualização do Core. Resultado arquivado em `QA-R2-OFFLINE-RESULTS.json`.

`qa_r2_native.gd`: suíte de cenário sem execução nesta entrega (`NOT_RUN`). Copiar para `res://exo_martial/tests/` em cópia isolada do projeto EXO Core 01 com Godot 4.6.2 Compatibility e executar `godot --headless --path PROJECT --script res://exo_martial/tests/qa_r2_native.gd`. Testa lógica de aula, exclusividade, recursos de prova, mock de narrativa, desbloqueio Core simulado, separação, transferência, reabertura isolada e 1800 mestres. Não substitui teste in-game de NPC/Forja/combat, nem save v4.

`qa_native.gd` e `qa_offline.py` são legado R1, mantidos por rastreabilidade. Não interpretar R1 como prova de R2.
