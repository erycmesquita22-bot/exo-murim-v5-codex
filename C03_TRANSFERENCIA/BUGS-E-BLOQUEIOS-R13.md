# R13 — Pendências e bloqueios reais

- P0: Godot 4.6.2 indisponível: parser/import, boot e F5 NOT_RUN. Contagem atual dos erros Godot DESCONHECIDA.
- P0: Fluxo do menu→criação→primeira região→personagem controlável NÃO COMPROVADO.
- P0: Falhas save/reopen (incluindo energia, loot, matrícula, interior e dungeon) ainda sem QA nativo.
- P1: Após falha de save regional a região permanece carregada em RAM (não reverter destrutivamente sem transação segura).
- P1: Terrain Forge R11 shaders/vegetação, NPCs/mestres, Forja/interiores, Dungeon R6, modelos Humanoides R10 sem QA de GPU/cena real.
- P1: Bugs históricos mapa TAB, missão Explorar ruínas, voo, mão/arma, bainha/2 mãos, colisões NPC/bambu, limites regionais, densidade e IDs UI ainda NÃO REPRODUZIDOS nesta rodada.
- QA histórico: humanoides R2 offline 2 falhas por assumir módulo isolado; NPC R2 offline 3 falhas de hashes upstream antigos; Bestiário offline exige README.md de outra distribuição. Preservar registros como falhas de fixture, não converter em PASS nem atribuir automaticamente ao gameplay.
- Segurança comercial: 480 skins herdadas continuam em quarentena; nenhum asset novo/terceiro foi adicionado nesta rodada.
