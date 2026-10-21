# EXO-MURIM — NÚCLEO NARRATIVO 01

**Base real:** `EXO-Murim-Jornada-Dinamica-01.zip` (sobre Mundo Vivo 02 R3).  
**Data:** 19/10/2026.  
**Versão da engine exigida:** Godot 4.6.2 Standard, Compatibility.  
**Estado:** fonte integrada, testes offline PASS; compilação/importação/Godot **NOT_RUN**.

## 1. Auditoria do código real

Inspecionados `journey_dynamic/quest_manager.gd`, `quest_generator.gd`, `convergence/game.gd`, `journey_save.gd`, `living_world/state.gd`, `living_world/factions.gd`, `living_world/people.gd`, `living_world/bridge.gd`, `living_world/fate.gd`, `ai_core/world_clock.gd`, `genesis/world_planner.gd` e os dois atlas reais 101 e 816204. O jogo atual já possui os campos opcionais `journey_dynamic`, `living_world` e `convergence`. A Jornada tem recibos de morte/contrato, XP, ouro/bronze e reputação; o novo núcleo não os reimplementa.

Observação: a fonte da Jornada continha **duas strings simples divididas por quebra de linha literal** (`quest_manager.gd` e `quest_ui_adapter.gd`), risco de falha de parsing em GDScript. Foram transformadas em `\n` escapado, preservando a apresentação. Esta correção é de auditoria estática e não equivale a comprovação de compilação.

## 2. Implementação efetiva

Foram acrescentados **18 arquivos novos** em `narrative/`, com máquina de fatos, 10 tipos de eventos normalizados, recibos duráveis, influências por região, seis facções narrativas configuráveis, relação diplomática, confiança derivada de memórias, vínculo entre NPCs, geração de Destino de Vida, conhecimentos por titular, rumores, três histórias com decisões, cronograma remoto sob relógio e migração opcional para save v4. O núcleo **não** concede XP, loot, dinheiro ou itens, não cria NPCs físicos, não redefine biomas e não reescreve campanha.

**Fluxos de integração:**
- Entrada na região → fato `region_entered` uma única vez por ID/região.
- Diálogo com NPC persistente → `npc_met` e contexto de confiança nas falas existentes.
- Morte regional → `enemy_defeated` por UID completo de membro/geração, independente do XP.
- Coleta real de ferro → `item_discovered` por ID estável de saque.
- Conclusão e pagamento de contrato → `quest_completed` na mesma transação de `journey.write()`, com memória do contratante.
- Autosave periódico (~20 segundos enquanto em região) → `NarrativeScheduler.advance()`; sem processamento adicional por quadro.

O gameplay Jornada continua responsável pela autoria de objetivos. Os três ganchos narrativos **não** são novos contratos fisicamente jogáveis: só podem entrar na Jornada via `JourneyBridge.opportunities()`, e seus resultados são recebidos via `story_choice_made`.

## 3. Cenários demonstráveis pela fonte e suíte nativa PREPARADA

**Manual Perdido** — NPC da região e ruína alcançável pelo atlas, facções Crônicas Silenciosas e Famílias Ancestrais, opções compartilhar ou esconder; consequência em influência e rumor agendado para propagação remota. O item manual não foi adicionado ao inventário ou às cenas.

**Discípulo Rival** — NPC de identidade persistente, resolução pacífica ou agravamento, memória estruturada e confiança derivada; sem criar IA de duelo.

**Disputa Regional** — duas facções (Caminho Celestial e Culto do Abismo), decisão altera influência (-100..100) na região e permanece no save, sem alterar terreno ou economia.

**Vínculos sociais** — relação `social_bond_formed` aceita vínculos de mestre e discípulo, rivais, aliados ou família quando ambos NPCs existem no índice persistido; a inteligência física continua no Living World.

## 4. Testes executados (e seus limites)

| Área | Resultado | Evidência |
|---|---|---|
| Bateria offline | **PASS — 75,906 verificações, zero falha** | `narrative/tests/qa_offline_result.json` |
| Atlas reais e rotas | PASS (descritores Python) | 2 atlas, 88 origens por atlas |
| Destino determinístico | PASS (modelo Python independente) | 12.000 seeds repetidas, distribuição de seis origens |
| Recibos e limite de capacidade | PASS (modelo Python) | 25.000 tentativas, 12.000 recibos retidos |
| Memórias compactadas | PASS (modelo Python) | 300 NPCs lógicos, até 16 memórias por NPC |
| Histórias regionais | PASS (modelo Python) | 46 regiões de assentamento, duas seeds |
| Persistência entre dois processos | PASS (modelo Python independente) | apenas `json` do fixture; NÃO GDScript nem save Godot |
| Integridade do projeto | PASS | 3543 arquivos anteriores preservados, 4 modificados, 0 removidos |
| Execução das classes GDScript na Godot | **NOT_RUN** | binário Godot indisponível e rede sem resolução DNS |
| Reabertura Godot em processo novo | **NOT_RUN** | scripts `qa_native.gd` e `qa_reopen.gd` preparados |
| Funcionamento real dos cenários na Godot | **NOT_RUN** | integração-fonte somente |
| Regressão física combate/NPC/worldgen/Jornada | **NOT_RUN** | executar Work em instalação Godot |
| Tempo P95/GPU/FPS/memória Godot | **NOT_RUN** | sem métricas nativas, sem capturas reais |

**Tempo da bateria offline:** 0.972 segundo(s) nesta execução; não representa custo de simulação no jogo. Sem comparabilidade de hardware/engine. Métricas de tamanho de save P95, FPS, memória física e carregamento **não foram medidas**.

## 5. Defeitos identificados e tratados

1. Strings com quebra de linha literal no módulo Jornada anterior → reparadas sem mudar texto exibido.
2. Saturação de memória social com agressões permanentes repetidas → somente primeira agressão significativa permanece permanente; demais são compactáveis; ordenação de importância estável e capacidade 16.
3. Evento físico pendente cujo relógio estava no mesmo instante do retorno à região → scheduler aceita reentrada no mesmo `clock`, mantendo idempotência por recibo.
4. Estado narrativo corrompido ou schema desconhecido → validação opcional no `journey_save.gd` e recusa de gravação inválida; saves antigos sem `narrative` não são apagados.
5. Referência a NPC/facção inexistente e escolha de história não disponível → evento recusado antes de qualquer efeito.
6. Recibos históricos no limite → rejeição de novos eventos narrativos, sem apagar histórico imutável ou impedir combate/recompensas da Jornada.

Os itens 1–6 foram identificados por revisão de código e modelos offline. Não afirmar que foram reproduzidos e eliminados **na Godot** antes da suíte nativa.

## 6. Preservação

**Arquivos existentes modificados (4):** `journey_save.gd`, `journey_dynamic/quest_ui_adapter.gd`, `journey_dynamic/quest_manager.gd`, `convergence/game.gd`.

**Preservados:** 3543 arquivos originais sem diferenças CRC/tamanho, incluindo `main.gd`, `project.godot`, World Genesis, Living World, armas, IA, rig, materiais e cenas. Todos os novos componentes são aditivos sob `narrative/`. Arquivos removidos: zero. Confira os SHA-256 no manifesto de preservação anexo.

## 7. Limites e pendências

- O contrato com a Jornada foi integrado aos sinais já existentes, mas as **três histórias** aguardam missões reais, assets, gatilhos e telas de decisão na frente Jornada para se tornarem jogáveis.
- A propagação de rumores é lógica e limitada, sem conversas físicas; facções remotas não possuem tropas ou guerras físicas.
- Estado `narrative` admite no máximo 12.000 recibos imutáveis e 2.048 donos de memória; em campanha muito longa será necessário plano de arquivo/corte por origem que preserve idempotência.
- Não há captura real, benchmark, QA humano ou garantia de compatibilidade funcional com uma Godot que não pôde ser executada.
- Os exemplos de dois NPCs em `qa_native.gd` são **fixtures lógicas**, não a prova de que uma cena física os materializou.

## 8. Como validar no Work

```bash
# Na pasta com project.godot, Godot 4.6.2 Standard instalado
godot --headless --path . --script res://narrative/tests/qa_native.gd
godot --headless --path . --script res://narrative/tests/qa_reopen.gd
python narrative/tests/qa_offline.py
```

Depois rodar F5, reproduzir entrada em região, diálogo, morte, contrato, salvar e reiniciar jogo; comparar os mesmos saves e seeds da Jornada 01, sem adicionar sistemas novos. Medir tempo de processamento do adaptador/eventos, P95 de quadro, memória do jogo e tamanho de save em 300 NPCs. Registrar PASS/FAIL/NOT_RUN conforme evidência. Recomenda-se confirmar as duas correções de strings no parser GDScript antes de qualquer teste físico.

**Metas técnicas para gate futuro (NÃO MEDIDAS):** evento narrativo P95 inferior a 2 ms e agendamento inferior a 2 ms por ciclo em fixture de 300 NPCs; incremento narrativo de save preferencialmente inferior a 2 MiB após 2.000 eventos. Uma falha de performance ou parse exige correção e nova regressão.
