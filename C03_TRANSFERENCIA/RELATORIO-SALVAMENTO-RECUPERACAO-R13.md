# R13 — Salvamento, recuperação e integridade

1. `project.godot` da R12 dizia `ALFA R12 QA`, mas `config/custom_user_dir_name` ainda era `EXO-Murim-Convergencia-03-ALFA-R11-QA`. Corrigido para **`EXO-Murim-Convergencia-03-ALFA-R13-QA`**, evitando testes futuros sobre dados da R11.
2. `convergence/game.gd::change_region()` retornava `true` após `save_progress()` falhar e sobrescrevia a mensagem de erro. Agora preserva o erro, registra via `push_error` e retorna `false`, deixando explícito que a região em memória **não foi confirmada em disco**.
3. Não foi criado SaveCoordinator novo nem modificado JourneySave, schema ou migração. O ambiente não executou reabertura, crash, rollback físico ou teste de disco cheio.

**Limite residual:** após falha de gravação, a nova região pode continuar em memória; não há rollback físico da troca já aplicada. A correção evita sucesso falso, mas recuperação plena depende de testes nativos e possível transação mais abrangente. Nunca carregar saves pessoais em sessões de teste.
