# Menu Murim — revisão candidata de 23/10/2026

Base recebida: `EXO-CHARACTER-REFIT01-CANDIDATO.zip`, SHA-256 `27a411dc7759ae2b55de8334fedadbf2d467dea62b07742dd49e692a60ddbb17`. Esta branch importa essa base integral; a branch `recovery/2026-10-22-exo-murim-v5` permanece como checkpoint anterior. O Refit e as mudanças urbanas do pacote recebido não foram rehomologados por esta revisão de menu.

## Alterações

- A arte antiga do menu foi substituída por `main_menu_01/art/voxel_murim_dawn.png`, gerada para esta revisão com vila de blocos, casas de telhado azul, montanhas e sakura. Texto e botões continuam Controls reais. A arte anterior continua recuperável na build recebida; não há duas artes ativas.
- `ambient.gd` desenha até 28 pétalas quadradas e cinco traços de vento, com redesenho limitado a 30 Hz. O menu limita o FPS a 60 quando não existe configuração salva. Não houve medição de FPS na GPU do jogador.
- O painel segue a paleta da imagem. As abas Vídeo, Som, Interface e Controles usam os arquivos `user://graphics.cfg` e `user://exo-audio.cfg` já usados no jogo. Vídeo mostra as opções de `exo_visual/spec.gd`; Som lê os padrões do único mixer `exo_audio.gd`. Opções Forward+ ficam desativadas em Compatibility.
- O carregamento de cena usa `ResourceLoader.load_threaded_request` e exibe a fração informada pela engine. Depois da troca de cena, a barra progride quando serviços, atlas, região e restauração do save terminam. Erros de restauração mantêm a tela e o botão de retorno. A barra não avança por temporizador.

## Validação executada

- Godot oficial `4.6.2.stable.official.71f334935`: importação de editor com código 0 e sem `SCRIPT ERROR`/`ERROR` no log final.
- `main_menu_01/tests/qa_settings_apply_buttons.gd`: `EXO_MENU_APPLY_QA` com `issues=[]`; verifica estados dos cinco botões e persistência de FPS, volumes geral/combate, HUD e tremor da câmera.
- `main_menu_01/tests/qa_boot_autoload.gd`: `EXO_MENU_BOOT_QA` com `issues=[]`, fase `hero`, criação visível e tela de carregamento presente durante a transição.
- `main_menu_01/tests/qa_menu_render.gd`: renderização OpenGL Compatibility com Mesa llvmpipe, resolução 1152×720; capturas `qa_menu_snapshot.png` e `qa_settings_snapshot.png` salvas. O ambiente não possui dispositivo de áudio, então a engine usou driver de áudio dummy nessa captura.
- `qa_resume_fix/qa_reopen_game.gd`: na execução final, `EXO_REOPEN_GAME_QA` com `failures=[]`; retomou a região 86, interior e posição exterior, e retirou a cobertura após a restauração.

Limites: a barra é uma medida de marcos concluídos, e a geração procedural pode ficar no mesmo marco durante uma etapa longa. O conforto visual, FPS e latência de entrada ainda precisam ser avaliados no PC/Android alvo. A origem comercial individual dos demais recursos recebidos no ZIP candidato continua sob os manifestos de proveniência do projeto.
