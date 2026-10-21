# EXO-MURIM — NÚCLEO NARRATIVO 01

**Alvo:** Godot 4.6.2 Standard / Compatibility.
**Base:** EXO-Murim-Jornada-Dinamica-01.zip (a versão baseada na R3 funcional).
**Estado:** fontes integradas; QA offline executado, validação Godot **NOT_RUN**.

## Donos dos dados

- `journey_dynamic`: missão, contrato, XP, moeda bronze, equipamentos, objetivo, recompensa, reputação de comunidade/local e inventário. **Não alterado pelo Núcleo Narrativo**.
- `living_world`: identidades dos moradores, NPC IDs, rotinas, profissão, reputação legada, saldo financeiro, sorte inicial preexistente. **Não alterado pelo Núcleo Narrativo**.
- `convergence`: mapa, regiões, terrenos, ecologia, relógio e evolução dos grupos hostis. **Não alterado pelo Núcleo Narrativo**.
- `narrative`: fatos resumidos, recibos de idempotência, decisões, memória social, vínculos, influência de novas facções, conhecimento, rumores, cronograma lógico, destino narrativo independente. **Único dono do estado narrativo**.

## Arquivos

- `core/narrative_state.gd`: schema, limites, integridade e histórico.
- `core/narrative_events.gd`: validação normalizada, aplicação de consequências, idempotência.
- `core/narrative_scheduler.gd`: simulação por relógio; pendências físicas só na região carregada.
- `factions/faction_registry.gd`: facções configuráveis e diplomacia (JSON).
- `society/npc_memory.gd`: memória compacta e projeção de confiança.
- `society/relationship_system.gd`: vínculos mestre–discípulo, rival e aliado.
- `destiny/destiny_generator.gd`: destino inicial determinístico independente das escolhas cosméticas.
- `knowledge/rumor_system.gd`: conhecimento por ator/facção/jogador, rumor não confirmado.
- `stories/narrative_hooks.gd`: oportunidades lógicas, sem implementar missões físicas.
- `persistence/narrative_serializer.gd`: opção de schema no save v4 e migração aditiva.
- `adapters/journey_bridge.gd`: interface única com a Jornada e com a engine.
- `data/*.json`: definições de facções e lore sem conteúdo não canônico novo.
- `tests/`: bateria offline, GDScript nativo e reabertura independente preparada.

## Contrato de evento v1

```gdscript
var event := {
    "id": "quest/j01/<quest_id>", # estabilidade exigida; nunca timestamp aleatório
    "type": "quest_completed",
    "source": "journey_dynamic",
    "region": 86,                 # ID real do atlas, 0..87
    "clock": 980.0,              # convergence.clock persistente
    "npc_id": "npc/r86/<slot>", # opcional, mas deve existir no living_world.npcs
    "context": {"quest_id": "j01/..."}
}
var result := preload("res://narrative/adapters/journey_bridge.gd").ingest(journey.data, atlas, event)
# A chamada NÃO escreve em disco nem paga recompensas.
# Persistir pelo journey.write() da transação do módulo chamador.
```

IDs admitidos: `enemy_defeated`, `quest_completed`, `item_discovered`, `npc_helped`, `npc_attacked`, `npc_met`, `region_entered`, `story_choice_made`, `knowledge_acquired`, `social_bond_formed`. As fontes `JourneyManager` usam IDs estáveis: UID completo da morte, ID único da missão e região. O mesmo ID repetido retorna `duplicate=true` sem consequências.

**Contratos de leitura:**

```gdscript
JourneyBridge.opportunities(journey.data, atlas, current_region)
JourneyBridge.context_for(journey.data, atlas, npc_id, convergence.clock)
FactionRegistry.relationship(journey.data.narrative, "caminho_celestial", "culto_abismo")
FactionRegistry.influence(journey.data.narrative, 86, "caminho_celestial")
RumorSystem.knows(journey.data.narrative, "player", "manual_perdido")
```

Para registrar resultado de história, receber `story_choice_made`, com `context.story_id` de uma oportunidade existente e `context.resolution` em sua lista `outcomes`. Sem essa validação, o Núcleo recusa o evento. O motor de missões continua dono das condições de gameplay que autorizam emitir esse resultado.

## Geração de histórias

A saída de `narrative_hooks.gd` contém `id`, `kind`, `origin`, `region`, `npc_ids`, `factions`, `outcomes`, `requires_physical` e pista de conhecimento. `Manual Perdido` exige NPC persistido e ruína alcançável, `Discípulo Rival` exige NPC persistido, `Disputa Regional` exige NPC persistido e região válida. **São oportunidades lógicas / contratos preparados**, não novas missões que possam ser aceitas no diário.

Mitos canônicos são apenas metadados no lore; os 12 heróis e 12 deuses são entidades distintas; destino divino é opcional. O módulo não gera divindades, raças, personagens especiais ou chefes.

## Persistência e limites

Campo opcional `narrative` no save original **v4**, sem alterar a versão do save pai. Schema narrativo `1`. Saves sem campo são carregados normalmente e recebem schema novo quando o Núcleo é utilizado. Schemas desconhecidos são recusados, preservando o arquivo original, não substituídos automaticamente. `journey_save.gd` valida o campo antes de gravação e normaliza números JSON após reabrir.

Capacidades: **12.000 recibos imutáveis**, **384 fatos recentes no histórico**, **1.024 decisões permanentes**, **2.048 NPCs com memória**, **16 memórias por NPC**, **2.048 vínculos sociais**, **256 rumores**, **128 agendamentos**, **88 regiões**, influência -100..100 e até 32 fatos por titular. Quando a capacidade de recibos é atingida, novos eventos narrativos são rejeitados; não se apagam IDs imutáveis e o gameplay de combate/quests continua independente. A ampliação/arquivo permanente será necessária em campanhas muito longas.

O relógio avança no sistema existente. O agendador é consultado apenas no autosave regional (~20 s), não por quadro. Histórias que precisam de geometria ou NPC físico são apenas pendências; nenhuma região descarregada é instanciada.

## Rodar QA no Work ou PC

1. Extraia o ZIP completo e abra `project.godot` em Godot **4.6.2 Standard / Compatibility**.
2. Faça backup dos saves de `user://` e importe o projeto sem sobrescrever os originais.
3. Rode em dois processos sequenciais, reutilizando a mesma pasta de usuário:

```bash
godot --headless --path . --script res://narrative/tests/qa_native.gd
godot --headless --path . --script res://narrative/tests/qa_reopen.gd
python narrative/tests/qa_offline.py
```

4. Execute a regressão: `tools/run_convergence_checks.py`, `tools/run_convergence012_checks.py`, `journey_dynamic/qa_journey.gd` e suites R3 existentes segundo seus roteiros; não trate ausência de tela como validação visual.
5. Em gameplay F5, visitar aldeia, conversar com NPC, combater, concluir contrato, fechar/reabrir, verificar mesmo UID/histórico; trocar região e avançar ao menos um dia lógico. Executar cenário de dois NPCs quando houver roster aplicável.
6. Medir duração de `NarrativeEvents.apply`, `NarrativeScheduler.advance`, tempo P95 de quadro, tamanho da parte narrativa do save e memória da cena em processos **sequenciais** sobre as mesmas seeds 101 e 816204. Metas preliminares (a validar): P95 processamento do evento narrativo < 2 ms em 300 NPCs; agendador < 2 ms/ciclo; incremento do save narrativo < 2 MiB com 2.000 eventos. Não são resultados medidos.

**Atenção:** Godot não estava disponível no ambiente que gerou esta entrega. Nenhum resultado nativo, captura do jogo ou benchmark de FPS foi produzido nesta rodada. A suíte `qa_native.gd` é **preparada, não executada**.
