# EXO Lendas de Murim — menu de entrada 01

Implementado: título Daxzin Presents / EXO / Lendas de Murim com Jogar, Configurações e Sair; etapa Iniciar novo jogo ou Carregar jogo; três slots persistentes; criação de personagem com preview 3D real, nome, rosto, cabelo, roupa e corpo; aplicação e restauração do perfil no player; isolamento de vida dos NPCs por slot; reaproveitamento de saves legados via slot 1; remoção das dicas inferiores. A tela Coração continua como menu interno da jornada.

Teste real: Godot 4.6.3 Standard Compatibility importou o projeto. `title_flow_test.log` contém TITLE_FLOW_PASS (título, criação no slot 2, perfil e NPC save persistidos, carregamento). `title_npc_suite.log` contém VILLAGE_NPCS_PASS, incluindo conversa e combate. `title_capture.log` contém TITLE_CAPTURE_PASS; capturas reais mostram título, escolha de jogo, slots, criador e vila sem dicas inferiores. Não houve teste manual humano nem Godot 4.7.2 neste ambiente.

Limites: o fundo de menu é uma ilustração gerada com base na imagem enviada, não um render do mapa. O criador usa as variantes de rosto pintadas e as peças V4 existentes; não oferece esculturas corporais ou roupas com malhas novas. Save legado anterior é apresentado no slot 1; a migração é por cópia para preservar o original. A configuração de tela cheia não foi validada manualmente fora da sessão virtual X11.
