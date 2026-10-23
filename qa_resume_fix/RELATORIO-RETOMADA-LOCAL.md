# EXO-MURIM V5 — Retomada e Interiores — QA real

BASE: `EXO-MURIM-V5-CHECKPOINT-MENU-PROFISSIONAL-CANDIDATO.zip` (preservada, sem sobrescrita).

## Correções implementadas

1. `main.gd`: ao continuar uma jornada com `phase=adventure`, não gera os objetos do cenário de teste legado. A vila legada permanece restrita ao fluxo antigo de prólogo. Não houve remoção destrutiva dos recursos históricos usados por outros sistemas.
2. `convergence/game.gd`: tela de carregamento prioritária enquanto o atlas, região e eventual interior são restaurados. Preserva snapshots internos e âncora externa antes da construção; impede simulador/autosave de modificar saves enquanto a restauração está pendente; protege contra fallback silencioso ao camp; mostra erro com retorno ao menu se a restauração falhar.
3. `exo_settlement_forge/runtime/portal_controller.gd`: ao RESTAURAR uma visita autenticada por identidade do edifício, permite reabrir o interior mesmo se a loja estiver fechada naquele momento; não altera a política de entrada normal. Restaura posição salva, caso válida na planta, e usa âncora externa calculada pelo endereço atual.
4. `worldgen_v5/runtime/visit_host.gd`: valida identidade do edifício/região e autoriza apenas o RESTORE da visita existente. A autorização de entrada normal permanece inalterada.
5. Recuperação institucional R7: mantém os dados da visita anterior; não sobrescreve a posição externa original durante o retorno.

## QA efetivamente executado

Engine disponível: Godot 4.7.2 Standard (Compatibility), Linux, headless. Versão-alvo 4.6.2 NÃO testada.

- Importação Godot: saída 0, sem erros de script nos logs.
- `res://qa_resume_fix/qa_interior_restore.gd`: saída 0. Entrada, snapshot, reconstrução com loja fechada, identidade, posição exata e saída para âncora externa passaram.
- `res://qa_resume_fix/qa_reopen_game.gd`: saída 0. Gerou região real 86, entrou em loja autorizada, salvou JSON, destruiu a sessão, reabriu com `load_on_start=true`, confirmou ausência de vila legada, região, interior e coordenadas. Salvou novamente do lado de fora e confirmou mesma região e posição externa após outra reabertura. Nenhum teste marcou falha.

## Limites

- São testes de engine e comportamento em simulação, **não homologação visual em PC/Android**.
- Interiores institucionais R7 e dungeons não tiveram regressão específica de save/reabertura neste ciclo; o código de recuperação R7 foi inspecionado e corrigido pontualmente.
- Saves antigos sem identificador válido de construção/visita não permitem inferir de forma segura o interior; o jogo informa o bloqueio em vez de inventar um local.
- Não cria novo formato de save, não apaga nenhum save do jogador e não modifica funcionalidades do menu.

**Status:** candidato validado em QA automatizado no Godot 4.7.2. **Não homologado no Godot 4.6.2 nem por gameplay humano.**
