# Cenários de laboratório — EXO Mestres R2

Os cenários chamam `res://exo_martial/r2/engine_r2.gd` em um dicionário v4 fictício. O jogo real conecta ações de combate, tempo, Qi/stamina e locais pelo validador confiável configurado no `module.gd`. Marcadores `lab/*` são rejeitados explicitamente pelo serviço de produção.

1. **Aula individual — Pavilhão da Lança:** mestre vivo ensina técnica `investida_brutal`, com arma equipada resolvida pelo UID (`item_1` -> `spear`/`halberd`). Observação de `watch_spear_spacing` em `training_lane`, seguida de três `spacing_thrust` com custo validado e da prova `range_trial` em `trial_lane`. IDs de eventos únicos. Não há ganho de XP antes da aprovação. Após prova, `finish_lesson` concede só maestria pedagógica e, ao cumprir requisito, gera ticket para `Core cultivation`.
2. **Treino coletivo — Seita do Bambu:** professor único, dois aprendizes NPC pré-existentes. Ambos usam `site/classroom_bamboo`, porém recebem chaves de vínculo, `lesson_id`, `event_id` e progresso independentes. Ações válidas de um aprendiz não incrementam o progresso do outro. NPCs não são duplicados nem teleportados; o cenário é lógico.
3. **Prova marcial — Clã da Montanha:** após aulas e maestria exigidas, `promotion_exam` consulta `school.promotion`, o examinador fornece evidência verificada de `endure_duel`, e `exam/<pair>/rank/4` registra uma única aprovação. Repetição do mesmo exame falha; falha no duelo não promove.
4. **Mudança de mestre — Vale do Grou para Jade:** o aprendiz pede `transfer`, a matrícula continua ativa e bloqueia candidatura ao segundo mestre enquanto o Núcleo Narrativo mantém `master_disciple`. Após o autor narrativo confirmar a remoção, `finalize_separation` suspende o vínculo; o segundo mestre pode receber candidatura, mas depende de novo vínculo narrativo. A maestria já aprendida no Core não é removida.
5. **Mestre morto e facção alterada:** progressão e aulas param imediatamente. O estudante ainda pode abrir pedido de saída, mesmo com o mestre indisponível, para não ficar preso em escola antiga; confirmação final continua exigindo remoção do vínculo pelo Narrativo.

## Sequência de execução (laboratório)

`discover` → `apply` → `mock_narrative.authorize` (teste somente) → `confirm` → `begin_lesson` → `record_action` (observar) → `record_action` (prática × N) → `record_action` (exame) → `finish_lesson` → [repetição de novas aulas para atingir maestria, se necessário] → ticket → execução pelo owner do `cultivation` → `confirm_core_unlock`.

QA automatizado disponível em `exo_martial/tests/qa_r2_native.gd`; a prova de integração física com NPC System / Forja Monumental permanece **NOT_RUN**.
