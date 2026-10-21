# EXO-MURIM | Skill Forge 01 R3 — Relatório técnico

**Data:** 20/10/2026 | **Engine alvo:** Godot 4.6.2 Standard / Compatibility | **Entrega:** módulo isolado, patch candidato não aplicado à C3 Work.

## Bases verificadas

| Entrada | SHA-256 confirmado | Integridade |
|---|---|---|
| `EXO-SKILL-FORGE-01-R2-BIBLIOTECA-EXPANDIDA.zip` | `002fc85dad97732ffbbe303eea48f6882f360b478b65fcceddda01cf4a9f4022` | ZIP CRC PASS |
| `EXO-MURIM-CONVERGENCIA-03-WORK-CANDIDATO-01.zip` | `abe7b5736140d91153e0e6f9343ef443d9ca526f78b636361355b2d895cb69f9` | ZIP CRC PASS |

Nenhum arquivo da C3 Work foi alterado; apenas dois arquivos temporários (`exo_core/core.gd` e `exo_core/modules.json`) receberam o patch num diretório descartável e foram restaurados byte a byte para QA.

## Catálogo

**184 IDs preservados:** 16 técnicas legadas ligadas a `techniques.gd`, 28 candidatas da R1 e 140 candidatas da R2. `expansion_r2.json` é espelho das 140 e não produz duplicação. Conservados IDs, nomes, balanceamentos, efeitos e origem de técnica. Apenas dois ajustes técnicos de metadata:

- `exo.sf.fio_do_bambu`: `tags.weapon_poses` de `[blade]` para `[blade,draw]`.
- `exo.sf.sete_cortes_do_vento`: mesma correção, necessária porque a `katana` da base C3 Work usa pose `draw`.

O validador passou a checar a correspondência entre IDs de armas e poses para **todas** as técnicas, não só R2. A tabela CSV registra o estado individual das 184 técnicas: **16 `legacy_connected`, 168 `candidate_not_unlocked` com runtime autoral `BLOCKED_HOST`**.

## Contrato de combate R3

Ajuste de versão `manifest.json` / `module.gd`: serviço `skill_forge` **1.2.0**. Adicionado `runtime/host_contract.gd` (`schema_version=2`) com fingerprint de plano, recibos de até 160 caracteres, owner `combat`, detecção de retorno de commit/replay e falha fechada. `module.gd` inclui guarda in-flight e **nenhum** writer de HP, mana/Qi, stamina, cooldowns ou save.

`legacy_cast` mantém `world.techniques.cast(index)` e o runtime original da C3, sem dupla cobrança. `authorized_cast` das demais 168 técnicas devolve `host_adapter_not_bound` enquanto o owner de combate não registrar callbacks confiáveis. O serviço real `combat` da C3 Work hoje expõe apenas `enemy_defeated`; não há API de cast físico genérico e transação persistida pronta para integrar.

**Não foi criado um executor físico paralelo**. Permissão, custo único de Qi/vigor, slot real de 3..6, arma equipada, nível/cultivo, safe zone, LOS, hitbox, alvo, facção, morte/cancelamento, ledger idempotente, save/reopen e rollback pertencem ao Core/Combat/Persistence, por contrato. Família temática não produz mecânicas não suportadas (dreno de sangue, dano demoníaco etc.).

## QA — execuções e status

| Suíte | Estado | Exit code | Evidência/escopo |
|---|---|---:|---|
| QA offline R3 | **PASS** | 0 | 49 testes: catálogo/diff exato, schemas, fontes C3 Work, RNG determinístico, seed impossível, mock replay 10 mil vezes, custos, cooldowns, arma, físico/ghost, aliados, paredes, safe zone, rollback, save/reopen, simulação mock 24h e 88 labels regionais |
| QA patch de integração | **PASS** | 0 | 6 testes: aplicação/dry-run, módulos únicos, bloqueio de aplicação dupla, reversão byte a byte, sem escrita na C3 real |
| Validação de preloads (`res://`) | **PASS** | 0 | 12 preloads `*.gd` resolvem no módulo ou na referência C3 Work |
| ZIPs de origem | **PASS** | 0 | SHA-256/CRC conferidos |
| Godot `--headless --editor --import` | **NOT_RUN** | — | Executável Godot ausente neste ambiente |
| Godot `qa_r3_native.gd` | **NOT_RUN** | — | Script entregue, engine ausente; mock nativo não substitui gameplay |
| Habilidades autorais em cena C3 Work | **BLOCKED** | — | Ausência de host Combat autoritativo, hitboxes físicas e commit persistido |
| QA em Ryzen Vega 8 / Android | **NOT_RUN** | — | Hardware não disponível; não inventar métricas de FPS |
| Áudio/VFX/licenças finais | **BLOCKED** | — | Chaves pendentes não equivalem a assets aprovados/comerciais importados |

**Total Python:** 55/55 PASS, 0 FAIL, exit code 0. As simulações Python são de contrato e mocks, **não representam 55 testes jogáveis**. R2 scripts históricos preservados em `docs/historical_r2`, não fazem parte da suíte R3: eram voltados à R13 e versão 1.1.0 e por isso deixam de ser válidos após a R3.

## Entregas nominais

1. `EXO-SKILL-FORGE-01-R3-CORRIGIDO.zip` — módulo integral, dados, scripts, contrato, testes e notas de rollback; sem C3 Work embutida.
2. `CONTRATO-SKILL-HOST-V2.md` — contrato de callback v2, owners/consumers, payloads, rejeições e flags.
3. `MATRIZ-184-SKILLS-ESTADOS.csv` — classificação de cada uma das 184 técnicas.
4. `PATCH-SKILL-C3-WORK-PROPOSTO.diff` — apenas registro de módulo e aviso de catalog-only, **não aplicado** à C3.
5. `QA-R3-RESULTS.json` e `QA-R3-OFFLINE.log` — status, evidência e execução.
6. `SHA256SUMS-R3.txt` — hashes de arquivos entregues, incluindo ZIP final.

## Riscos restantes e ações para próxima integração

- **Autoridade real não comprovada:** o Core deve implementar/assinar callbacks atômicos e persistência de receipts. A ligação `bind_trusted_host` não é autenticação de segurança por si só e só pode ser realizada por integrador confiável in-process.
- **Sem teste no motor:** compilar na Godot 4.6.2 Compatibility e depois testar execução física de **7 técnicas representativas**, uma de cada família, antes de liberar todas 168. Testar interrupção, inimigos/NPCs físicos, spawn/impacto/cura/controle e remoção de VFX em cenas reais.
- **Progressão e slots:** integração separada com Cultivation/Journey/Martial. Nenhuma concessão automática de técnica na R3.
- **Versionamento de cidades:** City Forge R4 ainda é futuro/externo ao escopo; não foram inventados contratos de safe zone da R4.
- **Mídia:** contrato por `prepare`, `release`, `impact`, `recover` e cancel; as chaves atuais dependem de assets originais com direitos comerciais e binding/QA. Não considerar nenhuma técnica audiovisual homologada.
- **Rollback:** o registro candidato pode ser removido junto do módulo sem migrar saves, pois este pacote não produz novo writer nem desbloqueios.

**Conclusão:** R3 está pronta como biblioteca e gateway de execução condicionado, com contrato testado offline e patch candidato reversível. **Não é versão jogável ou integrada** até superar os bloqueios no Core Combat e no teste Godot nativo.
