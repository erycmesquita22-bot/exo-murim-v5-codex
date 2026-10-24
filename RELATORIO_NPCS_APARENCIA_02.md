# EXO-Murim — aparências dos NPCs de Haneul 02

Base: EXO_Haneul_VillageNPCs_01, projeto Godot 4 Compatibility. A Bíblia V0.1, seção 6.5, define Ji Wol como barqueira e HWA-02 como vila; não atribui estes cinco civis a uma seita específica. As roupas seguem os trabalhos locais sem insígnias inventadas.

- Ji Wol: azul acinzentado, faixa ocre, cabelo preso e mechas laterais.
- Pescador do Vau: tecido areia e barro, cabelo curto sem rabo ou mechas.
- Pescadora do Cais: verde rio e linho claro, cabelo preso compacto.
- Moradora da Praça: terracota discreta, cabelo solto nas laterais.
- Atendente da Casa de Chá: azul fuligem e creme, cabelo preso.

A implementação combina materiais por peça e mostra/oculta componentes de cabelo do GLB V4. O atlas UV, rosto, rig, animações e geometria-base permanecem originais. A arma incorporada ao GLB é ocultada apenas nas instâncias civis. Isso não constitui cinco malhas de roupa modeladas separadamente nem novos rostos. Para associar uma variante a uma seita canônica será preciso a edição da Bíblia que faça essa atribuição.

Verificação real: importação Godot 4.6.3 Standard, suíte existente VILLAGE_NPCS_PASS, nova suíte VILLAGE_APPEARANCE_PASS, render X11/Mesa de Ji Wol e da pescadora. Logs e PNGs em qa/village_npcs. Sem teste manual humano. O Godot 4.7.2 solicitado originalmente não está disponível neste ambiente.
