# Matriz de contratos auditados na C3 ALFA R13

Referência conferida: `EXO-MURIM-CONVERGENCIA-03-ALFA-R13.zip`, SHA-256 `48ee4ea0bb9cd357ef416fcd6db099df9f8bc06d17be342d93afdc8f1de6fe21`. **Não extrapolar para a versão final do Work.**

| Dono | Interface real R13 | Nosso uso | Estado |
|---|---|---|---|
| `exo_core/module_registry.gd` | `register(spec: Dictionary)`; `initialize(callback)`; `requires`, `optional`, `entrypoint` | manifesto candidato `crowd_illusion` como `optional_module` | Auditado, não registrado na C3 |
| `exo_core/core.gd` | `initialize_module(id)` carrega `entrypoint` e invoca `initialize(self)` | `module.gd.initialize(core)` | Auditada assinatura, não rodado nativamente |
| `exo_core/service_registry.gd` | `register_service(id, owner_id, provider, methods, version)` | `crowd.illusion` com methods explícitos | Auditada assinatura, sem invocação nativa |
| `exo_core/event_bus.gd` | `subscribe(type, consumer, callback)` | observa `region_entered`, `region_exited`, `entity_state_changed` | Auditada assinatura |
| `exo_core/contracts/event_contracts.gd` | OWNERS tem esses eventos e valida contexto/schema 1 | apenas recebe eventos, não publica | Auditado |
| `genesis/region_data.gd` | região `data.spec`; `settlement_roads` com `a`, `b`, `width` | leitura de caminhos e escala de cidade | Adaptador implementado, teste na região pendente |
| `convergence/region.gd` | `route_points`, `station_points`, `data.lots` | exclusão próxima a portas e rotas NPCs | Adaptador implementado, teste nativo pendente |
| `cidade_viva/renderer.gd` | `set_meta("cidade_viva",report)` e `"cidade_viva_pois"` | exige cidade materializada, sem adicionar objetos | Adaptador implementado, teste nativo pendente |
| `npc_system02/director.gd` | `tick(delta, actors, clock)` e suas rotinas reais | **nenhum**: fantasmas ficam fora da lista `actors` | Separação validada por inspeção |
| `living_world/bridge.gd` | `record_roster(...)` persiste NPCs reais | **nenhum**: jamais chamar em fantasmas | Exclusão por projeto |
| `exo_core/integrations/humanoid_presets.gd` | `choose(actor_descriptor)` / `valid(selection)` / `status()` | contrato disponível para futura geração do atlas autoral aprovado | Ainda não vinculado na renderização |
| `exo_humanoids03_r2/scripts/preset_selector.gd` | skins 64×64 e catálogo de papéis | respeitar perfis/identidades ao converter para atlas | Ainda não há pipeline do catálogo para atlas integrado |
| `narrative/`, `journey_dynamic/`, `inventory/`, `exo_martial/` | donos de narrativa, missões, inventário e artes marciais | **não integra**: fantasmas são cenografia | Exclusão intencional |

## Contrato futuro com City Forge 01

City Forge poderá colocar em `region.set_meta("exo_city_forge_crowd_zones", array)` um array de zonas aprovadas, cada uma contendo:

```json
{"id":"market/01", "points":[[1,0,2],[20,0,2]], "capacity":12, "role":"merchant", "activity":"walk", "lateral":0.6, "safety_radius":2.5}
```

- `points` são coordenadas **locais ao nó de região**, não posições globais. O adaptador dá prioridade às zonas de City Forge, se válidas. Cada zona suporta 2 ou mais pontos e capacidade 0–60.
- O controlador de cidade deve reservar portas, postos e áreas NPC. O Crowd aplica filtros adicionais por proximidade e não possui qualquer autoridade sobre lotes, circulação formal ou spawn real.
- O serviço não cria saves e não registra ou inventa `npc/r`.
- Reação coletiva: `core.services.invoke("crowd.illusion", "notify_event", ["combat", global_position])` apenas por produtor autorizado no host; não existe publicação de evento inventado.
