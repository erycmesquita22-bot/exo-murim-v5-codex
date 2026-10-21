# Escolas, mestres e técnicas conectadas — R9

Catálogo oficial preservado: 9 escolas, 12 estilos, 16 técnicas. A R9 **não mediu** em Godot quantos NPCs estão materializados por seed/região.

| Escola | Matrícula R8 | Prova física R9 | Status |
|---|---|---|---|
| Seita do Bambu | Coordenada Narrativo/Marcial; exige mestre real | Sem atividade física completa | Bloqueio de aula |
| Clã da Montanha | Coordenada Narrativo/Marcial; exige mestre real | Sem atividade física completa | Bloqueio de aula/trial |
| Pavilhão da Lança | Coordenada Narrativo/Marcial; exige mestre real | Sem atividade física completa | Bloqueio de aula/trial |
| Templo da Corrente | Coordenada Narrativo/Marcial; exige mestre real | Sem atividade física completa | Bloqueio de aula |
| Vale do Grou | Coordenada Narrativo/Marcial; exige mestre real | Sem atividade física completa | Bloqueio de aula |
| Pavilhão da Sombra | Coordenada Narrativo/Marcial; exige mestre real | Sem atividade física completa | Bloqueio de aula/trial |
| Mosteiro de Jade | Coordenada Narrativo/Marcial; exige mestre real | Meditação/observação; código implementado | Candidato nativo NOT_RUN |
| Ordem da Cinza | Coordenada Narrativo/Marcial; exige mestre real | Sem atividade física completa | Bloqueio de aula/trial |
| Ermitagem do Vazio | Coordenada Narrativo/Marcial; exige mestre real | Sem atividade física completa | Bloqueio de aula |

## Amarração de estação / mestre
Um `master_station` só libera slot `master` se Builder criou de fato complexo, WorldGenesis emitiu recibo R7 e rota até rua/porta/estação passou. O Living World cria o NPC normal com ID estável; o módulo Marcial lê o currículo persistido. Sem prova física, não há slot e não há mestre artificial. Regiões visitadas na R8 não são retroativamente preenchidas.

## Cobertura de técnicas
Todas as 16 permanecem no catálogo oficial. Apenas técnicas ensinadas por um mestre Jade e aceitas por `lesson_preview` podem alcançar o desbloqueio Core em R9; nenhuma foi comprovadamente aprendida em runtime aqui.
