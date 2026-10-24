# EXO-Murim — Coração 01

Base: Haneul V11 integrado com Combate Baiano, Sword Frenzy, Clima e Estrada do Vau. O módulo é aditivo: a cena inicial passa a `res://modules/coracao_01/Heart_V11.tscn`, herdando o controlador V11. Nenhum GLB, textura do personagem, animação ou fonte do cenário foi alterado. A imagem conceitual fornecida serviu de direção visual; o fundo do menu é uma captura real e limpa do cenário V11, não representa outro personagem.

## Implementado

- Menu principal e pausa por ESC, azul profundo/ouro, captura de Haneul, navegação por mouse/teclado.
- Começar nova jornada, Continuar, salvar local em `user://exo_coracao_01.json` e restaurar posição/região/vida/Qi/clima/rival em vila, estrada ou interior. A restauração adiciona 0,35 m vertical para evitar interseção com o piso.
- Mapa com região real, rota Haneul–Vau–marco de Yunseong e contagem de visitas. Nenhuma cidade nova foi criada.
- Treino lendo as seis artes do catálogo atual; botão leva à vila e ativa rival.
- Tela de seita escolhe Wong/Wudong para a sinalização real do cenário e variantes dos próximos interiores; contribuição de 10 selos acumula reputação e patente locais. Gerenciamento de membros/política permanece futura integração.
- Conquistas persistentes ligadas a vitória, esquiva e exploração. Evento de duelo usa a IA atual e paga bônus uma vez por vitória.
- Loja de testes: selos ganhos por vitória, compra imediata de recuperação de HP ou Qi e recusa com saldo insuficiente ou atributo cheio.
- Opções: alternância do clima, rival de treino e salvar. Sair encerra o processo Godot.

## Validação executada

- Godot **4.6.3 Standard**, renderização Compatibility, importação sem erro de script: `qa/coracao_01/import.log` e `reimport.log`.
- Suíte headless `qa/coracao_01/suite.gd`: menu pausa/retoma por ESC mesmo com árvore pausada; nova jornada; catálogo ativo; compra afeta HP e saldo; clima; arquivo salvo; restauração de HP/posição; vitória paga só uma vez; snapshot e restauração de estrada e interior; afiliação Wong/Wudong e contribuição; conquista. Resultado `HEART_SUITE_PASS` em `suite.log`.
- Renderização gráfica real em X11/Mesa llvmpipe 1280×800: capturas `home.png`, `training.png`, `map.png`, `sect.png`, `pause.png`; `capture.log` indica `HEART_CAPTURE_PASS`. Áudio da máquina de teste é dummy, sem teste auditivo.
- A suíte V11 anterior já validou combate, portais, interiores e rota; este módulo herda essa cena. Não foi executado um novo benchmark de FPS nem um teste manual por jogador humano.

## Limites honestos

A tela de seita ainda não administra membros; a loja não tem inventário; o mapa não tem viagem rápida; o marco de Yunseong não contém cidade; a progressão de maestria do personagem continua sendo prévia de duas variantes. Esses itens aguardam módulos específicos. O save é local e não inclui estado transitório de golpes/projéteis ou posição/vida do rival; ao continuar, o duelo recomeça com o rival padrão. Shader Forge continua ausente da pasta V11, conforme o relatório anterior.

## Instalação

Use o ZIP de atualização sobre uma cópia do V11 integrado anterior e execute `python3 install.py /caminho/do/projeto`. O instalador verifica SHA dos dois arquivos que modifica, preserva cópias em `.coracao_backup/` e é idempotente. Abra `project.godot` no Godot. A distribuição completa também está disponível em TAR.XZ com todos os assets e QA, pois o ZIP completo ultrapassa o limite de upload do conector.
