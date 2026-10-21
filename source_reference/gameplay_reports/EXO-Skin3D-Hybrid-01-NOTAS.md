# EXO Skin 3D Hybrid 01 — entrega de candidato integrado

| Item | Resultado |
|---|---|
| Base auditada | EXO-Murim-Mundo-Vivo-02-R2-VALIDACAO-FUNCIONAL.zip |
| Engine exigida | Godot 4.6.2 Standard / Compatibility |
| Arquivos GDScript novos do módulo | 8 |
| Teste Godot automatizado | `exo_skin3d/qa_skin3d.gd` |
| Capturas automatizadas planejadas no runtime | 7, sendo 1 baseline |
| Scripts preexistentes modificados | 7 (`wardrobe`, `journey_save`, `ui/character_creation`, `convergence/resident`, `living_world/people`, `enemy`, `murim_flow`) |
| Rig, armamentos, técnicas, animações e IA originais | bytes idênticos aos da base |
| Testes offline executados | 713 verificações PASS; 30.000 combinações aleatórias de UV |
| Testes Godot executados nesta entrega | 0 — executável indisponível no ambiente |
| Estado da aprovação | CANDIDATO; bloqueado até validação visual/funcional real na engine |

**Pacotes**:

- `EXO-Skin3D-Hybrid-01-PROJETO.zip` — projeto Godot completo baseado na R2 de referência, pronto para importar e testar.
- `EXO-Skin3D-Hybrid-01-PATCH.zip` — arquivos incrementais para aplicar SOBRE a R2 exata, respeitando os caminhos `res://`.
- `EXO-Skin3D-Hybrid-01-OFFLINE-REPORT.json` — evidência da auditoria estática/offline.

A implementação de camadas não gera volume por pixel: apenas seis caixas faceadas por malha; volume de roupas e armaduras utiliza meshes voxel modulares explícitos. Os pivôs de articulação e armas permanecem herdados da R2.
