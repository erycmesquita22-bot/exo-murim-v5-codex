# EXO-MURIM — CONVERGÊNCIA 03 ALFA R3 — Engenharia de integração do EXO Core

**Data:** 19/10/2026. **Base efetiva:** `EXO-MURIM-CONVERGENCIA-03-ALFA-R2.zip`. **Status:** CANDIDATO DE CÓDIGO, NÃO HOMOLOGADO, GODOT NATIVO `NOT_RUN`.

## Resumo de entrega

A Alfa R2 foi copiada integralmente e preservada. A R3 modificou o registro central de módulos do EXO Core, endureceu a migração/backups, criou pontes de domínio e conectou um caminho real de entrada/saída de dungeon ao `convergence/game.gd` e a entradas físicas de `genesis/region_scene.gd`. Não houve merge de ZIPs antigos, reimplementação de subsistemas, nem substituição de texturas aprovadas.

**QA estático desta R3:** 35 PASS, 0 FAIL, 6 grupos GODOT NOT_RUN. Os testes GDScript novos foram escritos, mas não executados; **não declarar Godot boot PASS**.

## Alterações de código efetivas

1. **Core Registry:** `exo_core/modules.json` passou de 10 para 17 módulos. Os sete candidatos foram ligados por `optional_module=true`, com políticas explícitas (consultas/planejamento, sem ativação de gameplay não validado). Os 10 módulos anteriores continuam declarados. `core.gd::integration_status()` informa o estado real dos serviços após boot.
2. **Persistência 01-P:** `save_coordinator.gd::_migration_backup` valida arquivo de origem e backup existente por `WorldState.valid`, esquema, identidade e seed; rejeita backup corrompido/não correspondente. Não alteramos o formato de save V4 nem substituímos `JourneySave/SaveCoordinator`.
3. **Dungeon via Core:** `dungeon_genesis` registra serviço/dado persistente e recebe do Core o checkpoint oficial. O exterior recebe identidade estável `cave_rXX_lXX`, derivada da região e do índice do lote sem alterar `RegionData`/seed/digest. A interação `E` passa um descritor real ao Dungeon R2 (`family=cavern`, versão 4), e `interact_active` é chamado dentro da instância. O snapshot da região NÃO armazena coordenadas de interior; há tentativa de recovery exterior validado por raycast e cápsula em `restore_region`.
4. **Itens × Dungeon:** `core.gd::claim_dungeon_reward` prepara um único commit com `atomic_reward_adapter.confirm_pending` e `domain_stage`. O marcador da recompensa é alterado por `exo_dungeon/module/entrypoint.gd::stage_atomic_reward`, autoridade do Dungeon. **Ainda não libera loot**: exige `bind_trusted_dungeon_reward_proof` do verdadeiro host de pickup, que permanece ausente; sem isso falha fechado. Nenhum commit fictício foi instalado.
5. **Narrativo × Marcial:** `core.gd::request_master_disciple_change` autentica via prova do host e delega mutação à nova autoridade `narrative/society/authorized_master_disciple.gd`. Verifica relação exclusiva e recibo idempotente, salva pelo coordenador oficial, faz rollback em falhas. O host de provas `bind_trusted_social_proof` NÃO está vinculado; não autoriza matrícula fictícia.
6. **Outras pontes:** `exo_items` (consulta/preview), `bestiary` (catálogo, IA/encounter planner sem spawn), `monumental_plans` (footprint sem reserva), `creature_visuals` (lookup de .tscn sem instanciar ator), `martial_catalog` (9 escolas/estilos/técnicas em catálogo), `humanoid_presets` (escolha visual preview sem 480 PNGs em quarentena).
7. **Testes:** nova `res://exo_core/tests/qa_core_integrations_r3.gd` para grafo, dependências, backup corrupto e identidade de campanha. R3 usa namespace de QA próprio via `project.godot`.

## Estado real — NÃO confundir arquivo, serviço e gameplay

| Domínio | Integração R3 | Limite factual |
|---|---|---|
| EXO Core / Registry | Código integrado | Boot Godot não testado |
| Persistence 01-P | Validação de backup reforçada | Migração/falha I/O/reopen nativos pendentes |
| Dungeon Genesis 02 R2 | Registro + ponte exterior/instância + checkpoint | Entrada e saída não testadas; combate/loot ainda bloqueados |
| Itens R3 | Serviço preview e estágio atômico com owner gates | Drops de dungeon inativos sem prova real de pickup |
| Forja Monumental 04 | Serviço footprint/planejamento | WorldGenesis não reserva nem materializa monumentos |
| Mestres R2 | Catálogo e API pública narrativa com gate | Matrícula, Qi, provas trusted e técnicas não ativadas |
| Bestiário 02 | Serviços de catálogo/IA/encounter disponíveis no registry | Sem novo spawn/combate/XP vinculado ao dono Ecologia |
| Harmonização 02 | Caminhos de cena visual consultáveis | Sem equipar modelos em atores do jogo |
| Humanoides 03 R2 | Escolha de preset visual disponível | Sem Wardrobe/Rig runtime; 480 skins comerciais em quarentena |
| HUD/NPC/Terreno/RIG/Flow | Preservados da Alfa R2 | QA nativo da Alfa R2 também pendente |

## Bloqueios de aprovação

- Godot 4.6.2 Standard/Compatibility indisponível nesta sessão. Parser, shaders, render, F5, FPS e save/reopen não foram executados.
- Dungeon precisa validação de navegação/âncora, instanciamento E, morte, saves e crash entre checkpoints. O sistema de encontros/recompensas ainda não está conectado ao pickup real; não entregar XP/items automaticamente.
- Forja requer reserva de terreno autoritativa ANTES de lotes; dados atuais de Região usam lotes pequenos e monumentos de escala diferente. Não usar `approved=true` sem recibo real.
- Matrícula real exige ponte verificadora de provas e Qi/stamina/Cultivation; evitar vincular mock. A API pública agora existe, mas requer host validado.
- Bestiário precisa conectar a um único `regional_ecology/director.gd`; duplicar spawner, UID ou recompensa é proibido.
- Modelos de criaturas e Humanoides ainda dependem de ligação de atores e auditoria de proveniência; assets legados em quarentena permanecem.
- Não apagar arquivos históricos nem saves por busca textual. A R2 continua recuperação intacta.

## Antes de qualquer aprovação

Executar Godot nativo em **cópia**: import, `res://exo_core/tests/qa_core_integrations_r3.gd`, `res://exo_core/tests/qa_persistence01p.gd`, `res://convergence/tests/qa_rig01_eight_directions.gd`; campanha nova, região dungeon física, E entrar, explorar, E sair, fechar/reabrir em cada fase; 88 regiões e cidade 78/rios 14/26; falha simulada de save; FPS no PC Ryzen 3200GE/Vega 8. Toda falha deve gerar correção + regressão + checkpoint novo, nunca PASS artificial.
