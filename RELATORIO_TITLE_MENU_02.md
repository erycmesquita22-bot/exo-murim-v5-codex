# EXO — revisão do menu inicial 02

A primeira implementação se afastou da referência: trocou a composição da vila por outro cenário e usou fonte/caixas genéricas. Esta revisão parte da captura enviada, preserva a perspectiva e o personagem à direita, reconstrói apenas as áreas de lettering antigo, aplica vinheta/sombra e usa tipografia de pincel contornada. O nome exibido é Daxzin Presents / EXO / Lendas de Murim. Ícones de espada, engrenagem e portão são arquivos próprios. Botões continuam interativos; o fluxo de slots/criação não foi descartado.

Verificação: Godot 4.6.3 Compatibility. `menu02_import.log` sem erros de script; `menu02_capture.log` TITLE_CAPTURE_PASS com capturas reais da tela inicial, Jogar, slots, criador e retorno ao jogo; `menu02_flow_test.log` TITLE_FLOW_PASS por acionamento dos botões e persistência do slot; `menu02_npc_suite.log` VILLAGE_NPCS_PASS. O GLB V4 original permanece SHA-256 fc8af84dc28bd3c5e1a308df7a72efe702558824e924b52ac5d49ea75d11e557. Não houve sessão manual humana nem Godot 4.7.2 no ambiente.

A reconstrução do fundo usa geração de imagem guiada pela captura. Portanto a cena é muito próxima visualmente, mas alguns pixels e traços nas áreas reconstruídas diferem da fotografia original. É arte de menu, sem substituir a vila 3D. A arte original está incluída para comparação. As fontes e licenças estão no pacote.

SHA-256 referência: f19c6eb4d67b71254dd3e233899c40bde78a8a4a7b66cf0b90e337913c36b851
SHA-256 placa editada: adb70fd823ec98f724237f13e73a710dd072fc4b11321f902f2a00ef1459d01f
