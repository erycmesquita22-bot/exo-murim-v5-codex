# EXO-Murim V5 — Menu Aplicar R1

## Base
EXO-MURIM-V5-INTERIORES-EMPUNHADURA-R2-CANDIDATO.zip — não modificada.

## Bug confirmado
Em `main_menu_01/main_menu.gd`, `_clear_panel()` marcava todas as cinco placas como `disabled = true`, mas `_refresh_buttons()` restaurava somente os índices 0 (Continuar) e 2 (Carregar), conforme presença do save. Os índices 1 (Nova Jornada), 3 (Configurações) e 4 (Sair) continuavam desativados após Aplicar ou Voltar.

## Correção aplicada
`_refresh_buttons()` percorre todas as placas e aplica restrição de save exclusivamente para índices 0 e 2. Outras opções são sempre reativadas ao fechar diálogo. Nenhuma imagem, posição ou fluxo de gameplay foi alterado.

## Teste executado
Godot 4.7.2 Standard headless, script `res://main_menu_01/tests/qa_settings_apply_buttons.gd`, usuário/saves isolados via XDG_DATA_HOME. Resultado: saída 0, `EXO_MENU_APPLY_QA {"dialog_closed":true,"issues":[],"options":5}`.

Casos cobertos:
- Inicial sem save: Continuar e Carregar desativados, demais ativos.
- Janela de Configurações aberta: todos bloqueados por trás do diálogo.
- Aplicar sem save: restaurar exatamente as restrições iniciais.
- Voltar sem save: idem.
- Aplicar com save de teste: todas as cinco ações ativas.
- Voltar com save de teste: todas as cinco ações ativas.

## Pendências
Não foi realizada inspeção manual da interface em hardware do usuário ou no Godot 4.6.2. Isso é uma correção específica de gerenciamento de estado, não auditoria geral de UI.
