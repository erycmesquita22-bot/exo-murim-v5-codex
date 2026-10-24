# Coração 01 — atualização visual 1.1

A tela principal agora usa **a imagem de referência fornecida pelo usuário** como composição aprovada: painel esquerdo, círculo central com as opções, paisagem e figura à direita. Quatorze áreas interativas foram alinhadas aos botões desenhados na arte. Cada área responde ao clique, recebe foco e mostra realce ao passar o mouse. A arte à direita é ilustrativa do menu; não é a skin 3D do jogador.

O cartão conceitual “Baek Woon / Level 60” foi coberto por um cartão vivo com vida, Qi e selos reais. Continuar fica desativado quando não há save. Telas internas de mapa, treinamento, seita, conquistas, loja, eventos e opções abrem sobre a arte; suas ações continuam integradas ao Coração 01. A cena principal permanece `res://modules/coracao_01/Heart_V11.tscn`.

## Validação real

- Importação no Godot **4.6.3 Standard**, Compatibility, sem erro de parse/script: `qa/coracao_01/visual_import.log`.
- Suíte `qa/coracao_01/suite.gd`: 14 áreas clicáveis, Começar via botão da arte, Treinamento via círculo, pausa/retorno por ESC, compra com vida/saldo reais, save e restauração de vila/estrada/interior, afiliação/reputação, vitória sem recompensa duplicada e conquistas. `HEART_SUITE_PASS` em `visual_suite.log`.
- Capturas reais por X11/Mesa llvmpipe 1280×800: `home.png`, `training.png`, `map.png`, `sect.png`, `pause.png`; `HEART_CAPTURE_PASS` em `visual_capture.log`. O projeto mantém viewport de 1280×800 para não alterar a câmera do jogo; a arte de 1280×720 aparece com barras de 40 px acima e abaixo.
- Assets 3D, controlador de movimento, modelos, UVs e animações do Coração 01 anterior não foram alterados. Imagem de referência original incluída no módulo.

## Limites

A figura da arte é decoração do menu. As opções usam as funções descritas no relatório Coração 01; gestão de membros de seita, inventário e cidade de Yunseong permanecem fora deste módulo. Áudio foi testado com driver dummy no ambiente; não há teste auditivo. Não há benchmark de FPS novo para esta alteração de interface.

## Instalação

Extraia `EXO_Coracao_01_Visual_Update.zip` e execute `python3 install.py /caminho/do/projeto_Coracao_01`. O instalador verifica hashes da versão anterior, preserva backup e pode ser executado de novo sem duplicar arquivos. Abra o projeto no Godot para importar o JPG novo. Também há distribuição completa em TAR.XZ.
