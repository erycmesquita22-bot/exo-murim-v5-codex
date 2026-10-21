# R10 — Rig e animações — estado real

- `rig.gd` **continua** sendo o corpo voxel oficial (classic/slim), com pivôs torso, head, dois braços/antebraços e duas pernas/panturrilhas. Não foi trocado por humanoide genérico.
- R10 adiciona apenas encaminhamento `roll` por troca de estado ao adaptador cosmético; `arsenal.gd` encaminha `two_handed` após equipamento oficial. O adaptador altera visibilidade de saias/cuffs, **não** rotação de bones de combate.
- Não foram criadas animações falsas para `idle/walk/run/roll/attack/hit/crouch/two_handed`. Os estados existentes permanecem intactos.
- Pendências NÃO HOMOLOGADAS: contato mão/arma, arco e besta, espadas 2M, adagas/lanças/cajados, arma na rolagem, colisão com túnicas, extrusão de ombros/joelhos, hierarquia das bainhas. Precisam de captura real na Godot e teste do Arsenal por arma.
- Não existe benchmark de draw calls, FPS ou p95/p99. Evitar afirmar ausência de clipping.
