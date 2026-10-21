# Forja 02 — contrato de integração com World Genesis

**Integração consumidora, não proprietária.** Genesis decide as 88 regiões externas, os caminhos/estradas, o posicionamento de lotes, as alturas do terreno e sua ausência de sobreposição; Forja recebe parcela validada, cria o plano da construção e monta GLBs. Nunca modificar o grafo das regiões a partir da Forja.

## API principal

```gdscript
const Planner = preload("res://forja/forja_planner.gd")
const Builder = preload("res://forja/forja_builder.gd")
var outcome: Dictionary = Planner.plan_settlement(world_seed, approved_house_lots, true)
if outcome.ok:
    var built: Dictionary = Builder.build_batch(structure_root, outcome)
```

**Cada lote de casa** deve conter `id` (único, persistente), `center_x`, `center_z`, `ground_y`, `width_m`, `depth_m`, `yaw_quadrants` (0..3), `district` (`hamlet`,`village`,`city`), `approach_clear=true`, `terrain_samples_y` (4 valores dentro de ±0,18m do `ground_y`), `role` (`auto`,`dwelling`,`shop`,`tea_house`,`workshop`,`herbalist`,`inn`), `max_stories` (1/2), opcional `preferred_stories` (0/1/2), opcional `detail_profile` (`low`,`medium`,`high`). `flat_verified=true` substitui quatro amostras **somente** quando o gerador de relevo confirmou nivelamento; `terrain_samples_y` incompleto não é aceito.

Tamanhos aprovados de casa: **4, 6 ou 8m de largura e 4m de profundidade**, 1/2 pavimentos. Reserva padrão com fachada: `x = [-width/2-1.35, width/2+1.35]`, `z=[-2.65,4.95]`, zona de chegada até z=5.35; pátio `courtyard` somente com casa **6m**, terreno plano de pelo menos **10,9×19m**, extensão até z=6.95 e zona de chegada até z=9.20. **Lote com largura/depth apertado é rejeitado**, sem forçar resize dos GLBs.

Em loteamentos `plan_settlement(seed,lots,true)`, falha de qualquer lote / sobreposição => **zero planos para montar**. Máximo por chamada: **32 casas**. Todos os lotes precisam orientações/posições já determinadas pelo Genesis. Cada plano inclui `schema_version=2`, `lot_id`, `role`, `archetype`, `detail_profile`, `signature`, `decor_seed`, `origin_world`, `footprint_local_xz`, `access_local_xz`, `entrance_local`, `gate_local`, `approach_local`, `interior_anchor_local`, `npc_anchor_local`. O montador recusa planos adulterados/incompatíveis e fornece nós âncora `AnchorEntrance`, `AnchorGate`, `AnchorApproach`, `AnchorInterior`, `AnchorNPC`.

## Mobiliário de praça (opcional, parcela não sobreposta às casas)

```gdscript
const Plaza = preload("res://forja/plaza_furnisher.gd")
var result: Dictionary = Plaza.plan_plaza(world_seed, approved_plaza_parcel)
if result.ok:
    var built: Dictionary = Plaza.build_plaza(public_space_root, result)
```

Parcela requer `id,center_x,center_z,ground_y,width_m,depth_m,yaw_quadrants,role,terrain_samples_y,approach_clear`. Papéis `hamlet_square` ou `market_square`; largura mínima **18m**, profundidade mínima **14m**, quatro amostras de altura. Cada praça recebe seis objetos, incluindo poço e banca, além de `AnchorPlazaCenter`, `AnchorRoadNorth`, `AnchorRoadSouth`, `AnchorVendor00..05`. Faixa central local em `x = [-2,2]` deve conectar-se às rotas do Genesis; o script **não valida pathfinding nem controla a geração de ruas**.

## Versionamento e limites

- **V02 quebra o formato de blueprint da V01 (`schema_version=1`)**: reconstruir planos a partir dos lotes originais, sem sobrescrever saves. A seed sem ID estável é insuficiente.
- Nenhum contrato oferece terrenos nivelados automaticamente, navmesh, NPC com IA, loja funcional, interiores ou portais prontos.
- Reutilização do kit original via `res://godot/modular_kit.gd`; manter suas dependências e paletas. A Forja 02 acrescenta `forja/detail_pass.gd`, `forja/plaza_furnisher.gd` e `models/forja_v2/*.glb` e expande `catalog.json`.
- Após import, o Work deve passar `docs/ROTEIRO-WORK-QA-02.md` antes de qualquer merge na campanha.
