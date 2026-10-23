# EXO-Murim V5 — Otimização urbana A+C (candidata)

Base integral: `EXO-MURIM-V5-MENU-APLICAR-CORRIGIDO-CANDIDATO.zip`. Checkpoint original e builds anteriores não foram alterados.

## Implementação
- `exo_settlement_forge/runtime/house_baker_ac.gd`: monta a casa Forja original uma vez; combina a geometria dos meshes importados em um ArrayMesh de uma superfície, converte até 64 materiais em atlas de 512×512, guarda o resultado em cache compartilhado e cria LOD distante simplificado.
- `exo_settlement_forge/runtime/architecture_builder.gd`: remove a duplicação de shell geométrica e a manutenção de dezenas de meshes por casa. Instancia uma malha detalhada (até 65 m) e uma de LOD distante; um StaticBody3D com sete BoxShape3D preserva porta central vazada. IDs, função, registro, ExteriorDoor e ReturnExterior preservados.
- `exo_settlement_forge/runtime/qa_ac_ab.gd`: benchmark de construção para 47 casas, com versão anterior arquivada em `legacy_architecture_builder_qa.gd`.

## A/B real de Godot 4.7.2 (headless, 47 casas idênticas)
| Métrica | Antes | Depois |
|---|---:|---:|
| Nós | 3.103 | 612 |
| MeshInstance3D totais (inclui LOD invisível) | 1.739 | 94 |
| Corpos estáticos | 329 | 47 |
| Formas de colisão | 329 | 329 |
| Montagem, execução aferida | 62,709 ms | 19,694 ms |

A cena deixa visível uma das duas malhas por casa conforme a distância. A geometria detalhada passou no teste com 7.194 triângulos e 22 materiais combinados em um atlas/material. O cache é compartilhado entre casas da família atual.

## Limitações e pendências
- O teste não mediu FPS nem draw calls gráficos em GPU; não usar tempo de montagem headless como estimativa de FPS na Vega 8.
- A biblioteca atual possui uma família única de casa Forja com dimensões escaladas; não amplia variedades de construções neste pacote.
- Texturas transferidas para atlas em mosaicos, com UV restringida ao tile; inspecionar visualmente telhas/ornamentos por eventuais repetições diferentes da textura anterior.
- As 7 formas de colisão foram preservadas, agora num corpo único. É uma simplificação de nós físicos, não da quantidade de formas.
- Testes de entrada/saída de lojas e saves devem ser repetidos pelo usuário no Godot 4.6.2; não são homologados por este A/B.
- `Godot 4.7.2` é engine de teste do ambiente, enquanto 4.6.2 é alvo do projeto.
