# EXO-MURIM V5 — Correções focadas do checkpoint (candidato)

## Proveniência
- **Base única:** `EXO-MURIM-V5-ATUALIZADO-2026-10-22.zip`
- **SHA-256 da base:** `506d31005e897d448e0a384010959aab5643975120809d6f7f7d042c2bff348b`
- O checkpoint não foi alterado. Arquivo resultante é candidato integral, não homologado.
- **SEM MENU:** `project.godot` preservado byte a byte; cena inicial segue `res://convergence/game.tscn`. Nenhuma versão anterior do menu foi integrada.

## Código alterado (5 arquivos)
1. `main.gd`: câmera isométrica deixa de mudar de posição ao bater contra geometria. Efeito de tremor da câmera foi mantido conforme configuração original.
2. `genesis/region_data.gd`: a região `ruins` deixa de fabricar três locais iguais e reserva um sítio maior.
3. `genesis/region_scene.gd`: troca os arcos decorativos sem interação por uma ruína de família contextual e determinística. A física estática foi criada a partir da malha baixa em polígonos. As passagens regionais e as entradas reais de masmorras **não foram alteradas**.
4. `npc_system04/actor.gd`: NPCs ociosos derivam orientação dos caminhos autorizados que levam para a rua, em vez da rota degenerada `posto>posto`; durante conversa eles olham para a posição do jogador. Não muda lógica de horários, inteligência, economia ou contratos de navegação.
5. `pause_ui.gd`: se já existir jornada em fase de aventura, não abrir o overlay de pausa no boot; criação/prólogo continuam pausados quando necessário.

## Assets integrados
- `exo_ruin_library_01`: 12 arquivos `.glb`, 12 cenas `.tscn`, atlas original e manifesto.
- Cada ruína visual tem uma malha de baixa complexidade e uma textura. A física concava estática é criada apenas no sítio carregado.

## Validação REAL neste ambiente
Executável disponível: **Godot 4.7.2 Standard Linux, Compatibility** (versão de desenvolvimento alvo é Godot 4.6.2).
- Reimportação pelo editor: código de saída 0, sem mensagens de erro encontradas no log.
- Boot headless do jogo (`--quit-after 120`): código 0; nenhuma mensagem de erro no log.
- `qa_checkpoint_fix/qa_focused.gd`: código 0. Verificou as 12 cenas/meshes importadas, lote de ruína único, colisão, ausência de destino falso de dungeon, escolha determinística e orientação dos NPCs.
- `qa_checkpoint_fix/qa_startup.gd`: código 0. Fluxo de novo personagem pausado, aventura carregada sem pausa, telas de pausa/fluxo escondidas.
- Prova complementar de cidade (fixture isolada): 48 NPCs válidos, 30 deslocaram-se mais de 0,2m na janela medida, nenhum com yaw padrão exato, nenhum bloqueio de rota no período. Resultado de observação parcial, **não homologação de IA/navegação**.

## Não validado / limites
- **Godot 4.6.2** não está disponível neste ambiente: validar na versão alvo antes da aprovação.
- Renderização visual e FPS na GPU do usuário não foram validados.
- A movimentação de NPCs em todas as regiões e rotas não foi homologada; esta mudança corrige especificamente a orientação de idle/conversa.
- Ruínas agora são marcos exploráveis com colisão, **não dungeons**. Não foi adicionada interação fictícia.
- Não há alteração do fluxo de botões do menu inicial, que será um trabalho separado conforme instrução do usuário.

## Reprodução
`godot --headless --path . --script res://qa_checkpoint_fix/qa_focused.gd`
`godot --headless --path . --script res://qa_checkpoint_fix/qa_startup.gd`
