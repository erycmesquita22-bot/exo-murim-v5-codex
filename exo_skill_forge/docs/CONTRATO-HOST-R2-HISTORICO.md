# Contrato do host autoritativo — Skill Forge 01

## Separação obrigatória de responsabilidades

**Skill Forge:** classifica, valida, consulta, propõe planos, audita referências e encaminha casts legados. Não escreve HP, Qi, stamina, inventário, maestria, técnica aprendida, cooldown ou receipts da campanha.

**Host legado `techniques.gd`:** continua a executar as 16 técnicas existentes e a controlar os custos reais internos (`mana` = Qi de UI, `stamina` = vigor), cooldowns, impactos e áudio existente.

**Host genérico futuro (Combate/EXO Core):** valida e aplica atômica e idempotentemente técnicas autorais, incluindo NPCs e inimigos. Skills novas começam com `state=candidate_not_unlocked` e não devem aparecer no loadout oficial antes da migração acordada com Cultivation/Journey.

## API preparada

Método privado `bind_trusted_host("exo_core_combat_owner_v1", permit, execute)` é chamado pelo integrador confiável diretamente na instância do módulo. Não está na lista do serviço público. Dupla ligação é recusada.

`permit(actor_id: String, plan: Dictionary) -> Dictionary`: valida o ID vivo da entidade, ownership/servidor, mundo/combate ativo, cooldown, Qi, stamina, arma, culto, escola, nível, estado de aprendizado, slots/AI loadout, posição legal e se a técnica está autorizada. Retorna `{ "ok": true, "receipt": "<id único>" }` ou `{ "ok": false }`. Não consome recursos antes de commit ou usa reserva transacional real com rollback/TTL.

`execute(actor_id: String, plan: Dictionary, receipt: String) -> Dictionary`: valida novamente o receipt e os dados do plano; aplica uma única vez custos, cooldown, controle de interrupção, ações, colisão, alvo/amigo/inimigo, status, dano e eventos no owner autorizado. Repetir o mesmo receipt não pode conceder segundo dano, cura, XP ou gasto. Falhas parciais devem executar rollback ou transação idempotente; nunca aceitar plano arbitrário como código.

Um plano é **descrição, não comando confiável**. O host precisa conferir o ID de habilidade com o catálogo oficial, limites máximos, habilidade equipada/aprendida e não confiar em dano/custo enviados pelo cliente.

## Casos bloqueados

- Player sem aprendizado, cooldown ativo, energia insuficiente, arma errada ou fase/cultivo insuficiente.
- Ataque em região segura, ator morto ou inexistente, NPC lógico fora do mundo, NPC fantasma não interativo.
- Inimigo sem acesso válido à técnica, invulnerabilidade, alvo fora de alcance, paredes/colisões e dano em aliados.
- Cast replay, recibo duplicado, reentrada/competição e aplicação de status duplicada.
- Técnica com VFX/áudio `requires_binding`: não deve tocar o placeholder nem tentar `preload` inexistente; efeitos mecânicos podem ser validados sem apresentação no laboratório, mas não devem ser liberados como release final.

## Integração com outros sistemas

| Sistema | Interface requerida |
|---|---|
| `techniques.gd` / `combat/player_combat.gd` | Disparo antigo preservado; host genérico deve usar o owner de combate |
| `cultivation.gd`, Journey v4, Slots | Aprendizado e equipagem autorizados, preservando 3 a 6 slots; tickets e migração por outro módulo |
| `exo_martial` | `exo_martial.technique.<id>` permanece ligado a ID legado; novas IDs exigem permissão pedagógica explícita |
| `exo_bestiary`, `enemy.gd` | Seleção IA separada, alvo e combate pelo host; apenas tipos `enemy`/`npc` permitidos quando autorizados |
| `npc_system02`, Crowd Illusion | NPC físico autorizado pode executar; multidão fantasma não executa dano |
| Sound Forge, audio/skill_registry, exo_audio | Pistas de prepare/release/impact; som antigo fica no pipeline existente |
| VFX Forge, Rig | Só tocar chaves `asset_verified`; chave `requires_binding` é bloqueada |
| Exo Items e equipamentos | Resolver UID equipado através do inventário, nunca aceitar pose declarada pelo cliente |
| SaveCoordinator | Nenhum escritor novo no Skill Forge 01; migração/skill unlock fora do escopo |

## Limites anti-abuso

Técnica: custo Qi e stamina até 100, dano até 5000 no catálogo (não significa balance aprovado), cooldown até 180 s, alcance até 18 m, área radial até 8 m, até 16 efeitos por técnica, até 20 alvos/instâncias/ticks/projéteis por entrada e até 12 pistas por fase de tipo. São **limites de schema**, não metas de jogo; o host poderá impor limites menores por dispositivo/bioma/PvE.

## Anexo R2 — taxonomia e mecânicas que não existem no host
`inspiration_origin`, `power_family`, `combat_role`, `rarity_tier` e `combo_role` são metadados de design. **Nunca podem conceder status, multiplicadores ou gastos adicionais sozinhos.** Os únicos efeitos aprovados para os candidatos R2 são os primitivos de `validator.gd`. A família sangue usa `bleed` apenas quando suportado e não faz roubo de vida; defesa usa `shield`, nunca invulnerabilidade permanente; habilidade mundana usa stamina; celestial/demoníaca são **identidade temática**, não um sistema de facções/equações avançado.
A grade `rarity_tier` 1..5 é provisória e NÃO equivale ao nível oficial de cultivo, maestria ou graduação da escola; exige mapeamento explícito. NPC fantasma da Crowd Illusion não é um agente físico elegível.
