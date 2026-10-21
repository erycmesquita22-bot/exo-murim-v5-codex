# Matriz de contratos — Convergência 03 futura

Estado: auditoria estática, sem merge. “Implementado” abaixo significa código encontrado no pacote indicado; não execução nativa. Não há aceite formal dos owners demonstrado nos arquivos.

| Domínio / owner | Interface real / autoridade | Encontrado | Pendência / gate |
|---|---|---|---|
| Save / Core | `JourneySave.data`, `JourneySave.write()`, `save_coordinator.commit(save)`; v4 | Base possui `.tmp/.bak` e recuperação | Aplicar 01-P integral; backup existente válido, rollback total, reopen em outro processo |
| World / Core 01-P | `WorldState.create(seed,identity)`, `valid(w)`, `upgrade(w)`, `has_event(w,id)`, `mark_pending(w,id,details)`, `mark_collected(w,id,details={})` | Patch schema 2; claims em ledger, events só pendências | RAM não equivale a disco; 17 arquivos juntos; todos leitores cobertos |
| EventBus / Core | `core.publish(type,id,context,region,persistent)`; bus `publish(event,persistent)` | Assinaturas mantidas, evento schema 1; dedupe/fingerprint | Auditar efeitos de listeners antes do commit; trace 256 não é ledger |
| Loot / Inventário | `drop_for(actor)`, `collect(source)`; `data.items/pending_loot/next_item` | Base, 24 slots; R3 prepara extensão | Um único executor por fonte, sem concessão duplicada; autorização do dono Inventário |
| Itens R3 | estáticos `prepare_pending(data,source)`, `confirm_pending(world,source,expected_fingerprint,domain_stage=Callable())`, `abort_pending`, `inspect`, `recover_pending` | Adaptador em arquivo, não registrado no entrypoint | Ativar só após 01-P nativo; domain_stage somente mesmo data, sem I/O/save/efeito externo |
| Dungeon R2 | `bind_visit_checkpoint(callable)`, `enter_instance`, `leave_instance`, `active_status`, `recovery_status`, `recover_to_exterior(verified_position,region_id,location_id)`, `interrupt_active_visit` | Serviço `dungeons`, domínio `dungeon_genesis` | Host precisa commit verdadeiro; snapshot guard; recuperação anterior a movimento/snapshot normal |
| Loot dungeon | `bind_reward_verifier(callable)`, `confirm_reward_receipt(dungeon_id,reward_id,receipt)` | Marcador sem item/XP e sem commit próprio | **BLOCKED:** conciliar verificador pós-commit com staging pré-commit R3 |
| Entrada / WorldGenesis | `entrance_footprint.request`, `construct_authorized` com Callable oficial | Pedido e autorização fail closed no módulo | Footprint real fora de rio/via/muro/declive, piso/cápsula e acesso; construct simples só lab |
| Forja / WorldGenesis | `Planner.footprint(kind,yaw_quadrants)`, `Planner.plan(seed,request,reservations)`, `Builder.build(parent,plan,reservation_receipt)` | Plan schema 5; proposed ≠ reserved | Reserva persistente real antes de lotes; bool true fictício/QA_LAB_ONLY proibidos como aprovação |
| Salões / Host | `interior_bridge.from_plan(plan)` → scene/id/entrada/retorno | Cena `hall_interior.tscn`, descritores de 5 tipos | Transição geral ainda ausente; preservar único player/save e retorno seguro |
| NPC R2 | `Stations.resolve(semantic,person,available={})`, `resident_routes()` mantida | Fallback @activity/@square/home_slot | Converter Marker3D aprovado em rotas/capacidades; sem teleporte ou NPC duplicado |
| Social / Narrativo | `relationship_system.get_bond`, `narrative.relationships` | Leituras existentes; `Bonds.establish` é interno mutável | API pública `request_master_disciple_change(request)` apenas proposta, idempotente+autorizada+rollback |
| Marcial | `configure_host_integrations(proof_validator,admission_validator)`, `confirm_enrollment`, `finish_lesson`, `confirm_core_unlock`, `finalize_separation` | Módulo R2; domínio exo_martial schema1/r2_schema2 | Provas do runtime real, matrícula só após vínculo Narrativo; mocks nunca produção |
| Progressão | `cultivation.reveal(core_skill_id)`, `eligible`, `learn`; `known/learned/loadout` | Base possui técnicas e slots oficiais | 16 IDs R2 conferem; não editar arrays diretamente; UI mantém Qi, campo mana interno existente |
| Bestiário | catálogo, políticas e sinais de intenção do ator | 16 fauna / 8 humanoides / 3 elites / 2 chefes | Spawn/UID/ecologia pertencem ao Core; ligar dano, janela real, loot e XP antes de gameplay |
| Arte criaturas | `visual_catalog.gd`, catálogo por species.id, cena recomendada e sockets | 17 IDs / 20 GLBs | +X original → wrapper -Z; escala uma vez; sem hitbox/dano implícito; 3 IDs sem GLB |
| Humanoides | `on_visual_created`, `on_wardrobe_reapplied`, `on_action_changed`, `on_visual_removed` | Adaptador R2 sem física | Eventos actor.* propostos, não registrados; salvar visual_r2 pelo owner; rig classic/slim e outer layer preservados |
| Câmera / Visual | `Builder.set_roofs_visible` | Método da Forja | Conectar câmera EXO sem esconder cenário/hitboxes indevidamente; medir culling real |
| HUD | arquivos do patch exo_ui/ + exo_hud/menu/pause/settings | Ramo paralelo | Portar blocos sobre Cidade Viva R2; conservar settings corrigido e input oficial |

## Correção cirúrgica necessária: loot Dungeon × R3

Trechos de origem: `exo_dungeon/module/entrypoint.gd`, função `confirm_reward_receipt`, e `exo_items/integration/atomic_reward_adapter.gd`, função `confirm_pending`.

O verificador Dungeon é definido como prova de transação já confirmada. O domain_stage R3 roda antes do único save. Mesmo que o staging chame confirm_reward_receipt com um verificador permissivo, estaria violando o contrato. Chamá-lo somente após o save deixa o marcador fora do commit que entregou os itens. O código fail closed atual deve continuar assim até acordo explícito.

**Proposta para os owners, não implementada:** manter JourneySave/SaveCoordinator como autoridade; introduzir no contrato Dungeon uma operação de staging restrita ao owner inventário que verifique a concessão staged no mesmo data (ID/fingerprint/UIDs), marque Dungeon em RAM no domain_stage e exija rollback conjunto. Após o commit, somente notificar/confirmar externamente. O método pós-commit pode permanecer como reconciliador idempotente quando um recibo durável for encontrado, sem reentregar itens. Nome/assinatura de staging precisam ser definidos pelos owners; não são APIs existentes. Testar crash antes/depois do commit, repetição e falha de stage. Nunca acessar `State.record_reward_receipt` diretamente para contornar o contrato público.

## IDs e limites que precisam concordar

EventBus aceita IDs até 160 caracteres, WorldState 01-P usa 128 e R3 limita source a 123 por acrescentar `loot/`. O formato canônico longo proposto no contrato Core não garante esse limite. O host deve gerar um source estável de tamanho aceito, derivado de identidade persistente e slot; pode precisar de mapeamento versionado sob o owner. Não renomear IDs já gravados, não truncar ambiguamente e não usar NodePath/instance_id de runtime.

Recibo de evento não é recibo de recompensa: duplicar publicações não deve duplicar itens. `mark_collected` guarda fingerprint do claim no ledger e metadados adicionais no payload; consumidores devem conferir as posições corretas sem assumir que todos os fingerprints são iguais.

`narrative.relationships` tem limite de domínio e pares legados não direcionais. Remover teto de receipts pelo 01-P não resolve saturação de relações/decisões nem define mestre versus aprendiz. A API futura deve resolver capacidade, direção e transferência atômica sem adivinhar papéis.

## Mapa de estações: decisão ainda aberta

Os 62 marcadores Forja são distribuídos em famílias e tipos amplos; NPC System aceita aliases opcionais; Mestres pede evidências em áreas específicas. Antes de liberar treino, o host deve publicar tabela explícita `site_id/station_id → atividade aprovada → rota/capacidade → método de prova`. Um `training_courtyard` sem manequim/rota funcional não comprova `training_post`, furtividade ou esquiva. Não preencher todos os tipos com o mesmo ponto.

## Limites de catálogo vigentes

Itens: 6 raridades/17 afixos apenas preview; runtime 4/11 e 24 slots. Armadura/acessório não fica equipável por R3. Fauna visual: faltam wild_ox, wild_buffalo e qi_serpent; não promover propostas visuais a espécies do gameplay. Humanoides: R2 adiciona geometria e seleções, não outra autoridade de equipamento/facção/combate. Manter 480 skins em quarentena comercial até evidência adequada.
