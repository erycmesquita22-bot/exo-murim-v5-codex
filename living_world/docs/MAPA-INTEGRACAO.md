# Contrato de integração entre as três frentes

## Genesis (World planner)

- Publica o atlas de 88 regiões (`genesis/world_planner.gd`). Para cada região, a chave `id` deve ser estável por seed; `kind` pode ser `settlement`, `ruins`, `dungeon_approach`, `wild` e `settlement_scale` pode ser `city`, `town`, `village`.
- O Living World **não escolhe geografia nem distribuição de cidades/vilas/aldeias**. Consome essa classificação.
- Fonte determinística: `atlas.seed` como string decimal. Não usar `RandomNumberGenerator.randomize()`, `Time.get_ticks_msec()` ou hash nativo não-versionado para identidade.
- Regiões sem `assigned_slots` têm **zero NPCs materializados**, mesmo que sejam cidades. Não inventar casas vazias preenchidas com corpos.

## Forja (assentamentos)

- Entrega `slots` imutáveis por região, com `id`, `role`, `work_slot`, `home_slot`; `race` é opcional.
- Papéis permitidos: `resident`, `farmer`, `merchant`, `healer`, `guard`, `guild_agent`, `disciple`, `master`, `courier`, `outlaw`.
- Slots de trabalho/casa são referências lógicas. A Forja é a única responsável por encontrar posição livre, altura, portas, pisos, navmesh e entradas.
- Não renomear slot salvo sem migração. A identidade do NPC é `npc/r{region_id}/{slot_id}`.

## Living World (contratos e NPCs)

- Prepara dados com `Integration.preview`; materializa com `Bridge.record_roster`. NPCs materializados ficam no save e não são sorteados novamente quando a paleta de assets mudar.
- O renderer consulta `npc.appearance` e o catálogo atual, mas não tem permissão de trocar atributos/ID/posição sem evento autenticado.
- `Quests.offers` só disponibiliza contratos com serviço local existente. Contratos da Guilda esperam slot `guild_agent`. Treino da escola requer slot `master`/`disciple`.
- Os eventos devem nascer do combate, exploração e inventário reais, com IDs de ocorrência únicos e persistentes. Não chamar `Bridge.event` em `_process`, nem usar posição aleatória como ID.

## Exemplo mínimo de contrato — após integração

```gdscript
const Living=preload("res://living_world/integration.gd")
const Bridge=preload("res://living_world/bridge.gd")

# O atlas e os slots são entregues pelos sistemas proprietários.
var context: Dictionary=Living.context_from_region(region_spec,assigned_slots)
var roster: Dictionary=Bridge.record_roster(journey,context,assigned_slots,str(atlas.seed))
# Exemplo de evento real com fonte estável (não chamar uma vez por frame).
Bridge.event(journey,"site/86/road_marker/003","visit_site","road_marker",86,1)
```

**Não injetar automaticamente esse exemplo no `main.gd` anterior:** o Genesis 03 é uma demonstração separada e a Forja ainda está evoluindo o schema de slots. Uma integração em cena só deve acontecer após ambos fornecerem dados concretos.

## QA obrigatório depois de mesclar

- `qa_living_world.gd` sem erros de parsing e sem falhas.
- Suite da 09.4.6 e suíte do World Genesis na mesma cópia, sem regressão em controles, menu, trilhas, iluminação, rig e save.
- Teste de ciclo em duas execuções: aceitar missão → avançar → salvar → reiniciar → completar → reclamar → salvar → reiniciar → tentar reclamar de novo (sem recompensa nova).
- Checar que 5 NPCs em cinco slots materializam cinco IDs, sem colisão ou ocupação de caminho.
- Testar Godot com seed regional decimal >2^53, mantendo string até a função de hash para evitar arredondamento.
