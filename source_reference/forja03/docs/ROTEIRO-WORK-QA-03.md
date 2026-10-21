# QA real da Forja 03 — roteiro para Work / Godot

O material do pacote NÃO passou pela execução do motor nesta sessão. Critérios de aceitação antes de juntar ao Genesis:

1. **Importação G0:** abrir `project.godot` na Godot 4.x instalada; executar `godot --headless --path . --editor --import --quit` e registrar versão real, erros/warnings, hora/duração de import e falhas de GLB. Não pressupor Godot 4.7.2 disponível localmente.
2. **Testes herdados G1:** `godot --headless --path . --script res://qa/run_headless.gd`. Importante: esse script V02 valida casas e praças e deve continuar funcionando. Separar falhas de compilação, falhas lógicas e falhas de setup.
3. **Novos sistemas G2:** `godot --headless --path . --script res://qa/run_headless_v3.gd`. Registrar JSON `qa/last_headless_result_v3.json` e garantir zero falhas em seed, papel, adulteração, lotes e montagem real. Corrigir e repetir todos os casos.
4. **Laboratório G3:** F5 abre `res://forja/laboratorio_03.tscn`, teclas 1 a 9. Conferir modelagem e screenshots **reais da janela da Godot** dos 9 cenários, comparando à `previews/forja03-20-glbs-projecao-offline.png` (projeção estática, NÃO screenshot Godot). `godot --path . -- res://` não é a sintaxe para capturar: executar cena com argumentos do usuário `--capture` e coletar 9 arquivos PNG.
5. **Colliders e travessia G4:** usar `CharacterBody3D` de tamanho do jogador, percorrer portão frontal 6m, entrada do hall, acesso ao dojo e portão da fazenda; testar nas quatro orientações e diferentes tipos de terreno. Validar paredes bloqueando de fato o personagem e centros dos portões sem collider invisível.
6. **Persistência G5:** planejar 100 seeds por papel; salvar IDs, papéis, orientação e seed; fechar/abrir Godot; conferir repetibilidade e worldgen co-op; testar 64-bit seeds incluindo valores superiores a 2^31, sem colisões de identidade.
7. **Desempenho G6:** `godot --headless --path . --script res://qa/benchmark_v3.gd`; registrar `qa/benchmark_last_run_v3.json` (1/2/4/8 sites civis, murados e compostos). Capturar FPS GPU/CPU em jogo com 8, 16 e 32 edifícios, profiling de nós, draw calls, physics e VRAM; o benchmark CLI **não mede FPS**.
8. **Integração G7:** conectar loteamento atômico `Adapter.plan_sites` ao Genesis real, verificar ausência de conflitos de lotes, navegação de NPCs, carga de regiões, seeds distintas, memória e unload/reload durante pelo menos um dia de jogo.

**Política:** erros são classificados `BLOCKER` (crash/porta inacessível/colisões erradas), `MAJOR` (arte perdida/objetos no chão/UV/limites violados), `MINOR` (polimento). Não aprovar sem G0–G4; se FPS ou integração falhar, não aprovar G6/G7. Todo screenshot precisa vir de uma execução real, com caminho/hash/log; previews offline não substituem capturas.
