# QA GATES — SKILL FORGE 01 R2

**PASS comprovados em Python**

- P0: Integridade R13 contratual: 6 arquivos com SHA-256 exatos; 16 legadas e 28 R1 não modificadas.
- P1: 7 famílias × 4 origens × 5 técnicas = 140 novas; IDs e nomes únicos; 16 armas reais referenciadas.
- P2: Coerência de escolas e posturas, whitelist de efeitos, fases de mídia pendentes, tiers 1..5, limites de custo/recarga e alcances.
- P3: Aleatoriedade reproduzível, seed não altera IDs, 40 seeds sem colisões.
- P4: 180.000 + 549.998 iterações sintéticas (simulação abstrata de recursos, filtros e alcances, sem hits reais).
- P5: Instalador validado em espelho mínimo criado dos arquivos oficiais do R13; recusa edição de hash, duplicação e instalação sem backup.

**PENDENTE / BLOQUEIA PUBLICAÇÃO DE TÉCNICAS NOVAS**

- G1: Godot 4.6.2 headless, parse de scripts, import JSON, inicialização Core e teste nativo `tests/qa_native.gd`.
- G2: Revalidar contratos na C3/R14 consolidada; o instalador R13 bloqueia automaticamente versões divergentes.
- G3: 16 habilidades legadas completas: custos, cooldown, equipagem, acertos e regressão.
- G4: Host de execução genérica com transações idempotentes, consumo/recarga/HP autorizados, hitboxes, colisão, alvos e reentradas. Testar 1000+ casts reais por cenário, player/NPC/inimigo, com rejeições corretas.
- G5: Integração de animação, VFX e múltiplas pistas reais de áudio, direitos comerciais, spatialização, volume e sincronização.
- G6: Balanceamento em engine: duração de combate, dano efetivo por alvo, interrupção, boss, treino, nível, PvE e risco/recompensa.
- G7: Perfil Godot Compatibility em PC Ryzen 3200GE/Vega 8, Android, 5/20/60 inimigos executando técnicas, FPS, memória, quadro P95/P99 e culling.
- G8: Validação de desbloqueio/treino no Martial, slots, SaveCoordinator, economia e regressão geral.

**Nunca converter PASS de Python em homologação de Godot.**
