# CONTRATO-SKILL-HOST-V2 — EXO-MURIM Skill Forge R3

## Status

**CANDIDATO, NÃO APLICADO À C3 WORK.** Baseline `EXO-MURIM-CONVERGENCIA-03-WORK-CANDIDATO-01.zip` (SHA-256 `abe7b5736140d91153e0e6f9343ef443d9ca526f78b636361355b2d895cb69f9`). R2 (`002fc85dad97732ffbbe303eea48f6882f360b478b65fcceddda01cf4a9f4022`). Ambos os ZIPs foram conferidos com CRC.

### Serviços

- Módulo `exo_skill_forge`, **1.2.0**; serviço `skill_forge`, **1.2.0**; manifest/registry/código alinhados.
- Endpoint público do serviço: `summary`, `skill`, `query`, `preview`, `plan`, `legacy_cast`, `authorized_cast`, `compatibility_status`. Nenhum endpoint público faz ligação de callbacks, libera técnicas, escreve save ou cria itens.
- `bind_trusted_host("exo_core_combat_owner_v1", permit, execute)` somente por chamada direta **no processo** do integrador confiável a `core.instances["exo_skill_forge"]` — não é API pública de serviço. Contrato `schema_version=2`.
- **Feature flag padrão OFF:** sem ligação validada, `authorized_cast` devolve `host_adapter_not_bound`. Não adicionar técnicas autorais ao hotbar enquanto o host não estiver homologado. Vinculação direta não é mecanismo criptográfico de autenticação; o Core precisa controlar quem acessa instâncias.
- Host C3 Work real hoje expõe serviço `combat.enemy_defeated` somente. Não há executor físico genérico/atomicidade comprovados. Este módulo **não falsifica** esse executor.

### Payloads de exemplo (apenas contrato)

Pedido ao `authorized_cast("player", "exo.sf.fio_do_bambu")` recomputa **internamente** o plano a partir do catálogo; todos os campos de UI/network são ignorados. Plano: `{ok:true, skill_id:"exo.sf.fio_do_bambu", executor:"generic", actor:{type:"player"}, cost:{qi:0,stamina:16}, actions:[...], ...}`. `HostContract.fingerprint(plan)` = SHA-256 do JSON.stringify do plano em memória, para comparação, não uma assinatura de segurança.

`permit(actor_id, immutable_plan)` retorna `{ok:true, owner:"combat", schema_version:2, receipt:"core-generated-unique-id", plan_sha256:"<fingerprint>"}` **apenas** após validação real. Se negar, `{ok:false, reason:"..."}`. A autorização é read-only ou uma reserva com TTL e rollback; não aplica dano ou gasta duas vezes.

`execute(actor_id, immutable_plan, receipt)` retorna uma das estruturas:

- `{ok:true, committed:true, status:"committed", schema_version:2, receipt:"..."}` após commit atômico no único owner.
- `{ok:true, committed:false, status:"duplicate", schema_version:2, receipt:"..."}` em replay do **mesmo** recibo, sem qualquer novo efeito.
- `{ok:false, committed:false, status:"rejected", schema_version:2, receipt:"..."}` com rollback total ou sem mutações.

O Forge rejeita formatos sem owner, fingerprint, schema, receipt ou consistência. **Não pode provar por si só** que o Core escreveu uma transação correta: salvar, rollback, colisão e controle de targets pertencem ao Combat/Persistence.

### Comprovações que o Core deve realizar para cada cast

1. Identidade/ownership de entidade REAL, existência, HP vivo; jogador, NPC físico ou inimigo ativo. Crowd Illusion **não** executa dano. NPC lógico fora de cena também não.
2. Técnica conhecida/autorizada, slot real (respeitando 3..6 apenas no Core), requisitos de nível/cultivo, escola/estilo, classe, cooldown, Qi/mana, vigor, combo e arma efetivamente equipada (UID oficial do inventário). **Nenhum requisito declarado pelo cliente é prova.**
3. Safe zones e região, física: LOS/raycast 3D, parede, alcance, ângulo, raio, alvo/alinhamento, invulnerabilidade, equipe e friendly fire. Custo/cooldown autoritativos; nunca usar plano serializado da UI como comando.
4. Operações físicas `damage`, `status`, `movement`, `field`, `channel`, `projectile`, `shield`, `heal`, `cleanse`; cada uma exige runtime físico próprio. Preload de VFX não comprova hitbox. Eventos `prepare`, `release`, `impact`, `tick`, `expire`, `cancel` são opcionais na mecânica, sem travar a transação por falta de mídia.
5. Morte do ator/alvo, cancelamento, recuperação e interrupção durante cast; reservas liberadas; despawn de projectile/field e VFX; repetição do receipt não duplica HP, loot, XP, maestria, recarga ou gasto.
6. Persistência via `JourneySave/SaveCoordinator` existente. Skill Forge não cria domínio. Save/reopen e rollback devem preservar recibos e custos no Core.

### Legacy

Somente os 16 IDs de `data/skills.json` têm `legacy_cast`. A ponte consulta `world.journey.data.learned`, `loadout`, mapeia a posição em `world.techniques.DATA` e chama **apenas** `world.techniques.cast(index)`. `techniques.gd` controla custos Qi (`mana`), stamina, cooldown, animação, áudio, VFX e dano; nenhuma nova cobrança pelo Forge. Outros 168 IDs nunca passam pela ponte.

### Compatibilidade e owners

| Sistema | Owner | Consumidor e limite |
|---|---|---|
| `exo_core` service registry | Core | Forge registra serviço read-only; patch de inserção opcional não aplicado |
| `techniques.gd` / `cultivation.gd` | Combat / Cultivation | Forge chama legado somente, não altera slots/progressão |
| Master/Disciple, `exo_martial` | Martial / Journey | Forge lê tags escola/estilo, não concede técnicas |
| `exo_items`, inventário | Inventory | Host valida UID e pose atuais, não Forge |
| `npc_system02`, Bestiary | NPC AI / Combat | AI apenas sugere ID; Combat autoriza ator físico |
| Crowd Illusion | Crowd | Nenhum cast físico por figurantes |
| City Forge R4 (futuro) | City | Somente tags de zona/safe-zone vindas de contrato futuro; adaptador parametrizado, sem especular IDs |
| WorldGenesis | World | 88 regiões e seed são contexto read-only; nenhuma escrita/viagem |
| Sound Forge/VFX | Media owners | Cues faseados; ausências não bloqueiam QA mecânico, mas audiovisual não é homologado |
| Persistence / JourneySave | SaveCoordinator | Único ledger de receipts, rollback/save; Forge zero escritores |
| UI/localização | Localização | `loc_key` estável `exo.skill.<id>`; traduções EN/zh-CN pendentes |

### Limites e fallback

`unknown_skill`, `not_authorial_candidate`, `actor_invalid`, `host_adapter_not_bound`, `host_permit_denied_or_invalid`, `cast_in_flight`, `host_commit_unverified`: todos retornam `ok=false`; nenhuma alternativa simula damage ou cura. Sem mudança de seed/IDs. Manifest R3 não modifica a C3 Work. `legacy_cast` continua independente do host genérico.

### Planejamento de implantação/rollback

1. Integrador recebe este ZIP e os hashes; copia **somente** `exo_skill_forge/` numa árvore C3 Work **temporária**.
2. Aplica `PATCH-SKILL-C3-WORK-PROPOSTO.diff` **apenas** na cópia e valida resolução de módulos; por padrão só serviço de catálogo, sem binding de host autoral.
3. Core implementa transação física autorizada com provas + recibos persistidos; instância bind via integração confiável, nunca em save/editor UI; testamos NPCs, 88 regiões como contexto, 24h, save/reopen e cancelamento.
4. Homologa mecânica antes de conectar assets originais auditados; após testes de hardware Vega 8/Android e Godot 4.6.2, habilita seletivamente algumas técnicas.
5. Rollback: remover registro candidato de `exo_core/modules.json` e diretório `exo_skill_forge/`. Nenhum save nem arquivo do Core tem que ser migrado. Se já houver desbloqueios autorais em outra atualização, rollback requer migração pelo owner de saves, não por este módulo.
