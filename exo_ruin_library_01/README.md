# EXO Ruin Library 01 — INDEPENDENTE

12 estruturas voxel completas, cada uma com **uma única malha estática e um material de atlas**. Texturas originais geradas para esta entrega. Nenhum código da V5 foi modificado.

## Visualizar
Em uma **cópia** do projeto Godot, coloque a pasta `exo_ruin_library_01` na raiz (`res://`) e abra qualquer arquivo de `scenes/`. Os `.glb` importam como cenas.

## Limites reais
- Modelos e texturas gerados e ZIP verificado, mas **não executados no Godot** neste ambiente.
- **Sem colisão e sem navegação**: criar colisores simplificados e bake de navegação na integração futura, após testar o posicionamento.
- Sem geração automática, sem interação, sem dungeon, sem teleporte.
- Uma malha por ruína reduz overhead de nós e materiais, mas não garante FPS; medir no hardware-alvo.
- Escala e encaixe no terreno requerem inspeção visual no Godot.
- Não são réplicas de monumentos específicos nem utilizam modelos/texturas externos.
