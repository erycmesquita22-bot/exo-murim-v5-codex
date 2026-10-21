# Correções dos bugs reportados — 21/10/2026

Revisão sobre 5cb6103. Implementada e validada nos cenários abaixo; não significa ausência de todo bug em qualquer seed/dispositivo.

## Falhas e correções

1. Multidão surgia perto do jogador e parava amontoada: trajetos terminavam em poucos segundos e compartilhavam extremos. Agora há circuitos fechados de ida/volta em faixas separadas, ocupação inicial distribuída e movimento contínuo sem teleporte ao fechar o circuito. As ruas são estendidas somente enquanto os testes físicos passam, até 96 m de eixo por rua. Na amostra seed101 foi medido circuito de 194,2 m. O horário adia replanejamento até nenhum figurante estar visível. Figurantes continuam sem inventário/colisão/IA persistente; o diretor é único.
2. Antebraço dobrava para trás: sinal do eixo local do cotovelo corrigido no Rig, Arsenal, combate desarmado e poses compartilhadas. O solver de duas articulações foi ajustado para preservar a mão no mesmo alvo. A prévia agora reaplica a pose específica da arma depois do reset do rig, como o gameplay.
3. NPCs parados olhavam nordeste: orientação inicial agora usa a rua autorada, repouso usa a aproximação da atividade, conversa usa o interlocutor e deslocamento distante também atualiza orientação. Não se sorteou uma rotação decorativa desconectada da atividade.
4. Árvores/portais brancos: a fusão de malhas descartava cores dos materiais. A cor efetiva de cada superfície é preservada como cor de vértice, inclusive quando a malha não possui um array de cores original.
5. Árvores sob montanhas: altura analítica não é igual à interpolação triangular da malha de 1/4 m. O assentamento da vegetação usa exatamente as mesmas amostras, diagonal e costura da malha renderizada/física. Colisor do tronco acompanha a nova raiz. A câmera também testa obstrução antes de posicionar-se atrás do relevo.
6. Portal sem efeito: cada portão de trânsito aberto exibe membrana animada, presa à abertura da moldura. E continua usando a autoridade atual de viagem; teste real mudou da região1 para42. Não se atribuiu destino fictício a todo arco decorativo do cenário.
7. Passos ausentes: os OGG foot.* agora alimentam uma voz reservada do mixer EXO existente por superfície (grama, terra, pedra, madeira, cascalho, água e folhas). São gravações multietapas: reproduzidas como cama de movimento, sem disparar o arquivo inteiro para cada pé. Param ao cessar movimento, perder piso, teletransportar, mutar ou pausar. Os 20 canais existentes foram preservados, sem segundo gerenciador de áudio.
8. Texturas mal amostradas: os atlas R2 de3 linhas haviam sido combinados com um manifesto R3 de4 linhas. Foram incorporados os169 PNG R3 da origem fornecida e reempacotados80 recortes em4×4 com margens periódicas de8px. Cada recorte bate byte a byte com seu PNG256. Além disso, os três shaders selecionados pelas opções de vídeo ainda usavam lógica antiga: agora compartilham um único corpo de shader e preservam índices R3/textura de rocha ao trocar filtro. Encostas usam projeção de rocha natural, não piso de praça esticado. A rocha e outros8 recursos de terreno foram reconstruídos pelo gerador editável próprio já fornecido.
9. Combatente dos Ecos sem textura: Enemy aplicava somente acessórios Skin3D sobre a textura básica de Rig. Agora passa pelo mesmo Wardrobe/FighterArt/Skin3D dos habitantes, com aparência determinística por UID; HP, colisão, IA, dano e dono do combate permanecem os existentes. Também foi conferido visualmente o Conjurador dos Ecos em cena real.
10. Diálogo exibia IDs cf/r*/s*/b*: removidos os identificadores internos de moradia/trabalho da interface; atividade apresentada em linguagem comum.

## Evidências reais

- PASS: bugs-final/summary.json — 16 suítes Godot4.6.2 oficial, incluindo campanha, save/reload, combate, economia, NPC04, mundos, casas, regiões e os novos cenários reportados.
- PASS: bugs-current-code/summary.json — regressões afetadas repetidas após consolidar os shaders e trocar calçamento por rocha natural: bugs reportados, recursos, campanha e gameplay.
- Teste específico: inimigos usam textura256, cotovelos para frente, erro mão/empunhadura<5cm para arco e besta, dimensões dos5 atlas, ligações preservadas nos3 filtros, NPCs com orientações diferentes, circuito fechado, multidão ainda andando após24s virtuais, distribuição sem amontoamento no trecho amostrado, passos com input real e parada ao soltar, membrana visível, interação E viajando,175 árvores ancoradas contra raycast da colisão e cores verdes preservadas.
- PASS:80 recortes de atlas com pixels exatos, dimensions1088×1088,4×4 células272px; relatório terrain-atlas-packing.json e gerador reproduzível. O primeiro audit dos atlas fornecidos encontrou diferenças, por isso foram reempacotados a partir dos PNGs individuais em vez de declarar equivalência inexistente.
- Capturas OpenGL reais: besta/cotovelos, terreno, multidão, portal, montanhas nos3 filtros, inimigos texturizados. Renderizador Mesa llvmpipe; não benchmark de GPU alvo.
- Tentativas anteriores FAIL preservadas no QA como histórico. Incluem erro de array de cores nulo corrigido, perfil de teste incompleto, atlas incorretos e tentativa de E antes de o corpo do teste assentar no piso. Não são resultados atuais PASS disfarçados.
- NOT_RUN: Windows/Steam exportado, Android físico, audição em hardware, todas as seeds possíveis, todas as rotas por horas. Não há alegação de QA exaustivo global.

## Recursos e documentos

As imagens Terrain/FighterArt permanecem autorizadas pelo proprietário, que prometeu comprovação depois. Os169 PNG R3 usam a mesma cadeia declarada dos recursos Terrain do projeto fornecido; atlas derivados e geração original de rocha têm registros separados de fonte/hash. Não foram restauradas as480 skins em quarentena ou packs externos.
