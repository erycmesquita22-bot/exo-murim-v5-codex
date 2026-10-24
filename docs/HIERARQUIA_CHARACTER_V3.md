# Rig e contrato V3

Mesmos 25 identificadores de ossos da V2. `bone_contract.json` registra nomes, pais, repousos e peças em coordenadas Blender Z-up. O GLB/Godot usa metros e Y-up; frente local +Z. A instância visual é deslocada em -0,125 m para apoiar a sola no chão. Nenhum detalhe facial geométrico foi acrescentado.

```text
root
└─ pelvis
   ├─ spine
   │  ├─ neck → head → socket_head
   │  ├─ socket_back
   │  ├─ clavicle_L → upper_arm_L → forearm_L → hand_L → socket_hand_L
   │  └─ clavicle_R → upper_arm_R → forearm_R → hand_R → socket_hand_R
   ├─ thigh_L → shin_L → foot_L
   ├─ thigh_R → shin_R → foot_R
   ├─ socket_waist (sem bainha)
   └─ weapon
```

Pesos rígidos de um osso por vértice. Cabeça, face e cabelo acompanham `head`; camadas do tronco acompanham `spine`; faixas/tabardo, `pelvis`; painéis de saia, coxas. Os segmentos usam as superfícies do original cortadas nas articulações, com tampas internas. Texturas/UVs externos preservados.

`equipment_slots.gd` mantém os slots públicos `right_hand`, `left_hand`, `waist`, `back` e `head`; substituição de equipamento remove o item anterior. O cabo integrado é uma única malha skinned no osso `weapon`. Na V3 ele pode acompanhar cintura, mão esquerda ou direita, com transformação completa calculada após o AnimationTree. A busca/transferência é também animada no GLB; o controle mantém o encaixe ao misturar ações.

## Animações

Idle, Walk, Run, Combat_Idle, Sword_Draw, Sword_Sheath, Sword_Attack_01, Sword_Attack_02, Dodge e Hit_Reaction mantêm os nomes de contrato. A V3 acrescenta Walk_Armed, Run_Armed, Combat_Back, Combat_Left e Combat_Right. `motion_config.json` fornece duração e condição de loop usadas pelo controle.

O fluxo da AnimationTree é: locomoção livre (BlendSpace1D) / combate direcional (BlendSpace2D + corrida), mistura de postura, cadência, sobreposição de ação. Ações alternam duas ramificações com TimeSeek e mistura contínua; o clipe anterior pode continuar durante a entrada do próximo. Não se usa reset da pose entre golpes. Janelas, deslocamentos e buffer ficam no controlador e não são substituídos por uma alternância cega de clipes.

Os clipes de locomoção e ação são in-place; avanço de golpe e esquiva vêm do CharacterBody conforme a fase. Não há extração automática de root motion. Pés são preparados por cinemática inversa na autoria e exportados como keyframes; não há solver de contato do pé em runtime, terreno irregular ou IK adaptativa ao chão.

## Expansão

Cabeças/cabelos/roupas alternativos devem manter escala, origens, grupos de ossos e contrato de atlas. Rostos continuam na região UV ilustrada. O contrato permite novos módulos, mas não inclui editor nem assets alternativos. A escala uniforme experimental 0,95–1,05 da API de slots não foi integrada à colisão da V3; não é uma opção disponível ao jogador. LODs futuros devem preservar ossos, sockets, animações e material. Não foram criados LODs nem corpos masculinos/femininos alternativos.
