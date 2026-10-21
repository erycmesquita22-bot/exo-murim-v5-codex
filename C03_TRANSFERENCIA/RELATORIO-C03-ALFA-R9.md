# EXO-MURIM — Convergência 03 Alfa R9 — relatório técnico

**Origem exclusiva:** `EXO-MURIM-CONVERGENCIA-03-ALFA-R8.zip`; SHA-256 `df50cefb9b2f51e5692a83e9ddf796247df8168bd32348ccf78aeafb48f7b86a` verificado em bytes. A R8 e os saves originais não foram modificados. **Estado:** candidato técnico, NÃO homologado; Godot 4.6.2 e F5 **NOT_RUN**.

## Alterações de integração feitas sobre a R8

1. **Ocupação marcial legítima, R7/WorldGenesis → NPC System 02:** `convergence/region.gd` usa somente complexos `martial_medium`/`martial_grand` aceitos e materializados, encontra `master_station` + `entrance_anchor`, exige acesso rodoviário e colisão desobstruída e acrescenta um slot de profissão `master` no roster oficial do Living World. `convergence/martial_occupancy_r9.gd` valida rotas físicas; não teleporta NPCs. Registro estável `martial/<sha_site>`, escola oficial derivada determinística por seed/site e persistida em `living_world.npcs`. A criação da identidade cabe a `living_world/people.gd`, não há novo diretório de NPCs. Se não houver via ou estação verificável, o local não ganha mestre. Reentradas de locais R9 utilizam IDs existentes; regiões visitadas pré-R9 NÃO recebem novos NPCs nem novos círculos silenciosamente.
2. **Mestres e escolas:** `martial_engine.profile_data` respeita `martial_school_id` de uma ocupação escolar real; perfis já descobertos persistem. O host agora verifica que mestre e estação pertencem ao MESMO complexo e currículo, além de posição e disponibilidade; evita mestre aleatório perto de um pátio receber um perfil incompatível.
3. **Treinamento físico mínimo e específico:** para uma escola **Mosteiro de Jade** materializada, a R9 acrescenta uma composição voxel original de círculo de meditação em um pátio aprovado. Uma aula pode ser solicitada junto do NPC após confirmação de matrícula; somente uma técnica compatível é selecionada pelo `lesson_preview` oficial. O jogador interage no círculo com E, permanece imóvel sob condições válidas, testemunha um ciclo real `work_cycles` do mestre para observação, consome Qi e stamina nas ações de observação/prática/prova, registra recibos únicos via `exo_martial.record_action` e conclui a aula via `finish_lesson` existente. Falhas de transação reembolsam débito da ação no runtime. Temporizador e testemunho são criados pelo host, nunca por um menu ou laboratório. A máquina oficial R2 continua verificando ordem, custos, estágio e recibos.
4. **Técnicas sem segunda autoridade:** o Core recebe `confirm_martial_unlock_atomic`; o dono Cultivation expõe `stage_martial_reveal` e `stage_martial_learn`, e a máquina R2 confirma `pending_unlock` no MESMO salvamento `world.save_progress()`. Se o Core negar elegibilidade ou o commit falhar, o snapshot inteiro do save é restaurado. Nenhum slot de habilidades é alterado automaticamente.
5. **Preservação e desativação:** flags `[exo_murim/r9] school_occupancy_enabled` / `martial_training_enabled`. `project.godot` isola a pasta de saves de QA R9. Sem modificação do gerador de mundo, Forja original, Dungeons, Itens, ecologia, catálogo marcial ou Terrain Forge independente. Nenhum asset de terceiro foi importado.

## Restrições e lacunas REAIS

- **NÃO foi comprovado em cena** nenhum mestre chegando à estação, escola/seed com complexo aceito, porta desobstruída, aula concluída nem técnica reaparecendo após reabrir. Não há screenshot ou FPS da Godot; não declarar ciclo jogável homologado.
- A **cobertura prática está limitada ao Mosteiro de Jade** quando essa escola ocorrer num complexo válido e houver NPC e técnica elegíveis. Clã da Montanha, Pavilhão da Lança, Seita do Bambu, Templo da Corrente, Vale do Grou, Pavilhão da Sombra, Ordem da Cinza e Ermitagem do Vazio NÃO receberam provas/aparelhos/duelos falsificados. As escolas com trial obrigatório continuam com `admission_attestation` bloqueado.
- Rotas por ruas e dois segmentos submetidas a `PhysicsRayQueryParameters3D`, não comprovadas como navigation mesh completo. Uma escola pode legitimamente permanecer sem mestre devido a paredes, terreno, distância ou ausência de vias. O limite de até 125m é deliberado e deve ser ajustado somente com inspeção física.
- Os medidores de Qi/stamina são os medidores originais do runtime (`techniques.mana/stamina`): débito na ação está implementado, mas **persistência da energia num desligamento** não foi validada e o sistema base pode restaurá-la. Não afirmar conservação energética após reopen.
- Em caso de crash entre operações nativas de sistema de arquivos, nenhum teste ACID real foi executado; confirmar save/reopen e falha de escrita na R10.
- O visual Jade não é cópia de asset de terceiros; oito slabs voxel originais mais marcador físico. A fidelidade visual, colisão, alinhamento com relevo e iluminação ainda requerem inspeção Godot.
- A regra dos três slots ativos foi preservada porque não há novo executor ou configuração automática de loadout.
- Dois preloads antigos de arquivos de laboratório seguem ausentes (`godot/demo.gd→qa/walker.gd`, `exo_core/module_template/test.gd→example/module.gd`), preexistentes na R8.

## Testes efetivos

- SHA e CRC da base R8: **PASS**.
- Auditoria de integridade: 4.541 membros da base R8 preservados byte a byte ou alterados apenas na lista cirúrgica autorizada: **PASS**.
- Verificações de contrato R9, flags, dicionários JSON, preloads literais, presença física do novo ponto, limpeza de autoridade: **PASS**.
- Referência Mestres R2: **152/152 PASS** em Python; Dungeon 02 R2 e Itens R3 também passaram nos seus modelos Python de referência. **Esses são testes offline, não gameplay nem parser GDScript**.
- Total da matriz offline nesta rodada: **4.594 PASS, 0 FAIL, 9 NOT_RUN nativos/hardware** (conta por arquivos + verificações).
- Godot 4.6.2: comando não encontrado; `github.com` indisponível por DNS. Parser/import, cenas, rollbacks, economia, hardware e interações **NOT_RUN**.

## Status de entrega

**Checkpoint técnico R9** com ponte de ocupação física, caminho restrito de aula Jade e desbloqueio Core/Marcial em commit conjunto implementados no código. **Não** equivale a nove escolas jogáveis nem a uma release aprovada. Prosseguir somente a partir do ZIP integral R9 para R10/Work. Preserve R8 e saves em checkpoint pareado.
