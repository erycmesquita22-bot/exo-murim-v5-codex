# EXO — Living World 0.1 | Núcleo lógico independente

**Entrega:** módulo GDScript e dados verificáveis, destinado a receber os assentamentos do World Genesis/Forja depois de aprovados. **Não é uma nova versão completa do EXO-Murim, nem instala NPCs andando pelo cenário.** Foi feita auditoria sobre os arquivos reais listados abaixo, mas o executável Godot não estava disponível para rodar os testes da engine neste ambiente.

## O que está programado

- `living_world/names.gd`: nomes por seed/região/slot, nome pessoal estável, prefixos de profissão e sufixos de vínculo social. Os nomes foram redirecionados de fantasia ocidental para um conjunto próprio inspirado na romanização de nomes chineses; não pretende simular fidelidade histórica perfeita.
- `living_world/people.gd`: NPCs como **dados**, com ID determinístico, profissão, facção, nível, seis atributos alinhados ao catálogo 09.4.6, aparência compatível com chaves do Wardrobe, slot de trabalho, slot de casa e atividade horária planejada. Sem AI, locomoção, renderização ou colisão inventadas.
- `living_world/quests.gd`: quatro modelos de contratos, até **3 contratos ativos** e **6 ofertas** por consulta, objetivos contabilizados por eventos com IDs únicos, bloqueio de recebimento antecipado e recompensa única. A descrição é apenas dado; mundo/jogabilidade devem emitir eventos reais.
- `living_world/factions.gd`: seis grupos adequados ao cenário base, reputação −100 a +100, faixas de relação e fator de preço consultável (sem alterar lojas ainda).
- `living_world/fate.gd`: **Destino de Vida opcional**, persistido, pistas descobertas por eventos. Não determina parentesco ou eleição obrigatória.
- `living_world/state.gd` e `bridge.gd`: namespace persistente adicional `living_world` na raiz do save, transações rollback em falha, sem alterar campos validados da jornada legada. `balances.bronze` é carteira isolada temporária; **não é ainda a moeda da HUD**.
- `living_world/integration.gd`: contexto semântico de região para o Genesis 03 (`kind`, `settlement_scale`, `difficulty`, `id`) e das estações funcionais fornecidas pela Forja. Não presume casas, população nem navmesh que não existam.

## Arquivos auditados de fato

**Godot:** EXO-Murim-09.4.6-Base-de-Assets.zip (incluindo `procedural/seed_stream.gd`, `world_state.gd`, `loot_generator.gd`, `data/loot_rules.json`, `journey_save.gd`, `cultivation.gd`, `murim_flow.gd`, `inventory.gd`, `world/event_rules.gd`, `world/village_layout_v2.gd`) e EXO-Murim-09.2-Fundacao-Procedural.zip. **Genesis:** EXO-WorldGenesis-03-Godot-Validacao.zip (`genesis/world_planner.gd`, `region_data.gd`, relatório e descritores).

**EXO Minecraft original (Java, Forge 1.12.2):** Exo-Continuidade-Fontes.zip, Exo-Reinos-Vivos-Fontes.zip, Exo-Jornada-Fontes.zip, Exo-Arsenal-Encaixe-Fontes.zip e Exo-Profissoes-Fontes.zip. Inspecionados diretamente `br.exonpcs.NpcNames`, `ResidentIdentity`, `VariationProfile`, `Contracts`, `Factions`, `Wallet` e `br.exoarsenal.EquipmentRoll`; consultados testes do módulo NPC.

**Port 1.21.1:** Exo-1.21.1-Teste-Maior.zip, usado para mapear a organização dos catálogos de classes, títulos, passivas e ativas. Esse protótipo de migração não é o pacote completo do mod 1.12.2.

### O que reutilizar e o que não transportar literalmente

| Origem auditada | Decisão | Por quê |
|---|---|---|
| Java `NpcNames` e `VariationProfile` | **Adaptar** pool/cargo/aparência por seed | Manter a ideia; revisar nomes e aparência para tema Murim |
| `ResidentIdentity` | **Adaptar** ID, nível, seis atributos e identidade materializada | Evita reroll de NPC no load e permite história individual |
| `Contracts` | **Adaptar** limite 3 ativos, 6 ofertas, objetivos/eventos | Evita diário ilimitado, preserva o ciclo aceitação → progresso → recompensa |
| `Factions` + `Wallet` | **Adaptar** clamping/conta isolada | Integração direta com `coins` do save v4 quebraria validação |
| `EquipmentRoll` do Java | **Não copiar sobre a 09.4.6** | Godot já tem `loot_generator.gd` com afixos reais e caps; copiar reverteria o sistema validado |
| `WorldState` + `SeedStream` da 09.2 | **Reutilizar** Park–Miller e SHA-256, em domínio próprio | Independência do RNG global e do mundo físico |
| `Cultivation` e `Catalog` | **Preservar** ids de maestria, atributos e habilidades | Evitar renomear habilidades e quebrar saves ou UI |
| `murim_flow.gd` / `main.gd` | **Não modificar nesta etapa** | Dois chats estão alterando outros subsistemas; integração sem merge pode causar regressões |
| `genesis/world_planner.gd` | **Adaptador read-only** | 88 regiões, 23 assentamentos; regiões são imutáveis pelo Living World |

## Instalação experimental

1. Extraia EXO-Murim-09.4.6-Base-de-Assets.zip em uma pasta separada.
2. Copie a pasta **`living_world/`** deste ZIP para a raiz do projeto Godot, ao lado de `main.gd`. Não substitua nenhum arquivo existente.
3. Godot 4.6.2 Standard, Compatibility. Abra o projeto e execute:

   ```bash
   godot --headless --path /caminho/projeto --script res://living_world/tests/qa_living_world.gd
   ```

4. O teste de engine deve sair com código 0 e imprimir `EXO_LIVING_WORLD_QA` sem falhas. Relatório no diretório `user://` (`living_world_qa_result.json`). A execução desse passo deve ser feita pelo modo Work/instalação local — **não foi executada nesta sessão**.
5. Para um exame de código e dados sem engine, execute `python tools/static_audit.py` dentro deste ZIP (não valida o script Godot).

## Contratos de integração

O gerador fornece `region.id`, `region.kind`, `region.settlement_scale`, `region.difficulty`, e a Forja fornece `assigned_slots`, por exemplo `[{"id":"guild_01","role":"guild_agent","work_slot":"guild_01","home_slot":"house_01"}]`. A função `Integration.preview(atlas, region_id, slots, stage)` só **descreve** os NPCs e os contratos; não cria geometria, caminhos nem entidades. Para materializar no save, use `Bridge.record_roster(journey, region, slots, str(atlas.seed))`.

Para a campanha antiga, `Bridge.setup(journey)` adiciona o módulo sem alterar `stage`, `coins`, `character`, `items`, `world.events` ou a versão de `journey_save.gd`. `Bridge.accept_contract(journey, id, context)` exige ofertas elegíveis. `Bridge.event(journey, unique_source_id, type, target, region_id, amount)` só deve receber **eventos autoritativos e verificáveis** — uma morte confirmada, marcador inspecionado, treino concluído etc. `Bridge.claim_contract` concede a recompensa uma vez, dentro de `living_world.balances`, e só após persistência segura.

**Atenção:** a coleta e a entrega de ervas não estão ligadas ao inventário real; o gerador de NPC não instancia rigs; caravanas não se deslocam automaticamente. Não mostrar essas mecânicas como prontas na UI antes da integração com o sistema correspondente.

## Versionamento e exclusões

- Schema desta extensão: `living_world.schema=1`, `ruleset="living_world/1"`. Não mudar o comportamento da geração v1 sem criar v2/migração.
- A seed regional do Genesis 03 é um texto decimal de até 63 bits; derive nomes de `str(atlas.seed)` diretamente, sem transformar para float. A seed `world.seed` antiga é uint31. São contextos diferentes e não devem ser confundidos.
- Separar a progressão narrativa/contratos do ciclo físico e da geometria. Geração de identidade somente quando o slot é alocado, não a cada frame ou portal.
- O limite v4 de moedas já existentes (`coins` igual a 0 ou 100 conforme o contrato de prólogo) torna a integração direta insegura. A carteira `living_world.balances.bronze` precisa de um contrato formal com a futura Economia.
- Nenhum arquivo de áudio, textura, modelo ou código Java de terceiros foi empacotado ou copiado literalmente.
