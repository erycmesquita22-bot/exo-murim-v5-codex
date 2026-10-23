# Menu Murim

A cena principal é `res://main_menu_01/main_menu.tscn`. As cinco placas são botões reais. O fundo é voxel; pétalas e linhas de vento usam um CanvasItem limitado a 30 desenhos por segundo. Sem configuração salva, o menu limita a atualização a 60 FPS.

Configurações leem e gravam os arquivos usados dentro do jogo: `user://graphics.cfg` e `user://exo-audio.cfg`. Vídeo expõe as opções da especificação EXO Visual, desativando as que exigem Forward+ no Compatibility. Som expõe os oito grupos do mixer. Interface expõe HUD e tremor da câmera. Controles descreve os comandos atuais.

Ao iniciar ou continuar, a barra mede o carregamento real da cena pelo ResourceLoader. Após a troca de cena, a cobertura do jogo avança conforme terminam serviços, mapa, região e restauração do local salvo. Uma nova jornada conclui a barra quando a criação de personagem está pronta. Falhas de restauração mantêm a cobertura e a opção de retorno visíveis.

Validação de menu: `main_menu_01/tests/qa_settings_apply_buttons.gd`, `qa_boot_autoload.gd` e `qa_menu_render.gd`. Aparência e FPS no aparelho do jogador ainda devem ser conferidos.
