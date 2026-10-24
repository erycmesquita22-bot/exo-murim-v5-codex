# Menu inicial EXO — revisão visual 02

Cena inicial: `res://modules/village_npcs/VillageNPCs_V11.tscn`. O fluxo funcional da versão anterior permanece: Jogar → Novo/Carregar → três slots → criação de personagem → vila. O Coração segue como menu interno.

A arte `source/user_reference.jpg` é a captura enviada pelo usuário, preservada. `haneul_reference_clean.png` deriva diretamente dela: textos e ícones antigos foram removidos e suas áreas reconstruídas, mantendo a perspectiva da rua, personagem à direita, montanhas, lanternas, céu, flores, sombra e contornos. Título, assinatura, três ícones e botões são elementos separados, editáveis e clicáveis na Godot. `atmosphere_overlay.png` acrescenta vinheta quente de baixa intensidade. O fundo é um composto editado da captura, não uma renderização literal sem alterações do mapa.

Fontes comerciais permitidas: Permanent Marker sob Apache License 2.0; Kalam Bold e Kaushan Script sob SIL Open Font License 1.1. Arquivos de licença acompanham `fonts/`. `build_icons.py` gera os três ícones originais do menu, sem assets externos. Referência gráfica: título laranja com contorno preto de pincel, créditos abaixo, opções alinhadas à esquerda e cenário totalmente visível. Dicas de controles não aparecem na base da tela.

Os submenus usam papel escuro translúcido para leitura, enquanto a tela principal deixa o ambiente exposto. O criador tem preview 3D enquadrado e a mesma linguagem de tinta/cobre. Saves, perfil, NPCs e GLB V4 permanecem integrados.

## Revisão de profundidade 03

As telas Jogar, Configurações, Slots, confirmação de substituição e Criar Personagem usam painéis de madeira escura e cobre em nove recortes, com sombras, topo iluminado, base escura e cantos ornamentados. Os botões usam placas em relevo distintas para normal, hover, pressionado e desabilitado; texto desce ao pressionar. Campos de nome e seleção, incluindo lista suspensa, receberam o mesmo material. O quadro do preview 3D segue a mesma moldura. O título principal e a captura da vila permanecem com a composição da versão 02.

`build_ui_panels.py` gera os PNGs de UI de modo determinístico; são assets próprios, sem fontes ou imagens de terceiros adicionais. É profundidade visual em controles 2D, com o avatar efetivamente renderizado em 3D no criador.
