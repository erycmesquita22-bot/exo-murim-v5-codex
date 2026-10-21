# EXO-Murim — Biblioteca Universal 01 R2 (Godot 4.6.2 Standard/Compatibility)

**Conteúdo real:** 62 domínios, 888 registros (676 autorais, 212 referências `external_ref`).
**Estado:** candidato independente, read-only; QA offline PASS; QA Godot NOT_RUN; NÃO integrado à Convergência 03.

### Para instalar (sem modificar a C3)
Copie **apenas `exo_world_library/`** para a raiz de uma **cópia** do projeto Godot (`res://exo_world_library/`). Não copie o arquivo `project.godot` deste ZIP sobre o do seu jogo.

### Exemplo GDScript
```gdscript
var Module = preload("res://exo_world_library/core/entrypoint.gd")
var library: Variant = Module.new()
if library.load_catalogs():
    var context: Dictionary = {"world_id":"campaign_01", "seed":101, "region_id":78,
        "biome":"bamboo_forest", "settlement_type":"town", "player_tier":1,
        "tags":["martial","sect","river_access"], "flags":[]}
    var suggestion: Dictionary = library.compose(context, ["region_legacy", "region_tension", "npc_archetype", "npc_background", "npc_motivation", "world_event", "rumor"])
    print(suggestion) # PROPOSAL_ONLY ou BLOCKED; committed sempre false
```

### Testes
```bash
python exo_world_library/tests/qa_offline.py
Godot_v4.6.2-stable_linux.x86_64 --headless --path . --script res://exo_world_library/tests/qa_native.gd
```

### Contratos
`contracts/adapter_requirements.json`: whitelist de 17 consumers/owners, nenhuma aplicação automática.
`contracts/coherence_policy.json`: restrições, pré-requisitos e mutex de tags.
`contracts/record.schema.json`: estrutura de registros.
`contracts/authority_matrix.json`: autoridade de spawn/loot/save/mundo/NPC/quest.
`integration/read_only_bridge.gd`: pedido read-only por owner; permite acessar apenas sugestões de domínios permitidos.
`manifest.json`: versões, proveniência, catálogos e hashes das bases.

**Importante:** para manter mundo persistido determinístico após alterações futuras dos dados, o host deve fixar versão/hash do catálogo por campanha. Este módulo não grava ou migra saves.
