# EXO-Murim V5 — Menu Murim 02 — Candidato

BASE ÚNICA: EXO-MURIM-V5-CHECKPOINT-CORRECOES-FOCADAS-CANDIDATO.zip

## Implementado
- Substituição da cena principal por `main_menu_01/main_menu.tscn` (uma única cena de menu).
- Arte Wuxia/Murim em arquivo separado, sem botões desenhados na imagem de fundo.
- Cinco botões TextureButton reais: normal, hover vermelho, pressionado vermelho e desativado.
- Continuar e Carregar usam save real; Carregar apresenta o slot existente. Não foram inventados múltiplos slots.
- Nova Jornada usa o autoload `MenuBoot` como handoff antes da troca de cena; não faz await a partir de cena removida.
- Na cena de destino, Nova Jornada não carrega o save anterior, abrindo o fluxo nativo de personagem/prologo.
- Painéis personalizados no próprio menu: configurações, confirmação de substituição de save e carregamento.
- Configurações persistidas nos arquivos do próprio projeto para áudio e gráficos.
- Nenhuma alteração nos outros sistemas do checkpoint corrigido; menu legado de aventura permanece somente dentro do jogo.

## Evidência de teste
- Godot 4.7.2 Compatibility: importação/headless executada, sem erro de resource de menu.
- `EXO_MENU_RENDER`: 5 botões, captura gráfica e configurações, validado em 1152x720 e 540x337 (llvmpipe).
- `EXO_MENU_BOOT_QA`: issues=[], nova jornada entra na fase hero/criação, UI de pausa não visível.
- `EXO_STARTUP_QA`: jogo de aventura em estado gameplay não pausado (da bateria do checkpoint anterior).
- `EXO_FOCUSED_QA`: ruínas, colisões, câmera/NPC herdados do checkpoint corrigido; não foi feito novo teste visual completo destes sistemas.
- Godot 4.6.2 não disponível aqui. 4.7.2 não substitui certificação em 4.6.2.

ESTADO: CANDIDATO. NÃO HOMOLOGADO.
Não se confundem execução do fluxo de menus e jogabilidade validada por humano.
