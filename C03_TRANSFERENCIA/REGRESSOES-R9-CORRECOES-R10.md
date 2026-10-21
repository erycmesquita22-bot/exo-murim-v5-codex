# R10 — Correções de riscos identificados na R9

1. **Navegação dos mestres**: corrigida a prova degenerada de conexão `navigator.route(road,road)`; agora grafo roda `route(home_anchor,road)` e verifica conectividade dos endpoints e todos os segmentos linha de visão/collision layers. Continua propositalmente `fail closed`: sem navmesh 3D certificado ou teste físico por seed. Não declara mestres efetivamente caminhando até escola.
2. **Qi/stamina runtime**: `techniques.mana/stamina` são preservados sob campo opcional com validação em `convergence/state.gd`; carregados no boot e após recuperação de região. `exo_martial/module.gd` passa a chamar o host `save_progress`, não `journey.write` direto, de forma que o checkpoint da energia acompanhe o recibo da aula. **Sem teste de crash/reopen**, logo não homologado.
3. **Mestres Jade**: visual escolhe paleta somente quando `martial_school_id` é catálogo oficial Mosteiro de Jade; nenhum vínculo narrativo novo criado. Rotinas/meditação sem teste real.
4. **Regressão dos sistemas R3–R9**: SHA da R9, preservação de arquivos e Python de referência passaram; gameplay R6/R7/R8/R9, import e parser Godot NÃO executados.
