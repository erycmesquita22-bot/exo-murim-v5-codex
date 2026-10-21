# EXO-Murim 09.4.2 — Vilas Procedurais de Verdade

## O que mudou no código

- `world/village_layout_v2.gd` (novo): gera lotes distintos para Guilda, pousada, pátio de treino e moradias; quatro padrões de ruas; quatro condições de nascimento (20/50/25/5); RNG determinístico separado do saque e dos demais sistemas.
- `world/village_v2.gd` (novo): constrói as vias, estruturas, serviços e mobiliário nos lotes sorteados. Não usa mais o conjunto fixo de quatro edifícios no centro.
- `world/biome_plan.gd`: escolhe layout v1 para saves legados, v2 para novos mundos; valida ambos.
- `region.gd`: usa geração v2 somente em novos mundos; extraiu as ruínas e a arena do prólogo para uma rotina comum. Manteve a construção v1 intacta para saves existentes.
- `world/landscape.gd`: evita sobrepor as vias antigas à vila v2; amplia terreno plano na borda de aldeia para os novos lotes.
- `main.gd`: NPC da Guilda, ponto de nascimento e rótulos usam os locais gerados; após reconstruir uma região, reposiciona o NPC e sincroniza as interações.
- `murim_flow.gd`: novos personagens recebem `landscape_version=2`. Descanso, meditação, Guilda, foco da missão e nascimento consultam os locais registrados pela região, sem perder o progresso ou o arco de patrulha/ruínas.
- `map_view.gd`: marca os serviços e as casas do layout real, e não as quatro casas fixas.
- `qa0942.gd` e `qa0942_playable.gd` (novos): testes definidos para dados e para a cena Godot.

## Compatibilidade

- Saves anteriores com `landscape_version=1` mantêm exatamente a composição antiga (sem alteração silenciosa de construções em partidas em andamento).
- O layout v2 só entra **após criar e confirmar uma nova jornada**. Informar seed diferente em um mundo já existente não troca automaticamente seu layout.
- A seed gera de forma determinística a mesma disposição, incluindo locais de serviços e recompensas externas já existentes.
- Não foram alterados os scripts de personalização, rig, arsenal, animação, inventário nem técnicas.

## Evidências que de fato consegui verificar

- Auditoria independente em Python reproduzindo o algoritmo Park–Miller e SHA-256 do código: **1.000 seeds**, 1.000 arranjos distintos, 4 perfis de nascimento, 4 padrões de vias, sem colisões entre lotes na grade lógica.
- Comparação de hashes de 8 scripts críticos com a 09.4.1: sem diferenças.
- Paths de scripts/referências de recursos dos arquivos modificados existentes, arquivos JSON consistentes e integridade do ZIP.

## Não validado

- **Godot não está instalada no ambiente.** `qa0942.gd` e `qa0942_playable.gd` foram criados mas não executados no editor/engine.
- Não declarar aprovação de performance, acesso físico a todas as portas ou estabilidade de runtime sem rodar a cena em Godot.

## Como testar

1. Extraia em pasta separada e abra `project.godot`.
2. Inicie **Nova jornada** e confirme um novo personagem com seed (por exemplo, 101).
3. Percorra a Guilda, a pousada e o pátio de treino; confira os indicadores e interações `E`.
4. Teste o mapa (`Tab`), patrulha, recompensa, descanso, meditação e salvamento.
5. Comece **outra Nova jornada** com seed 202 (em save separado se quiser comparar simultaneamente). As construções e as ruas devem ocupar posições distintas.
6. Para checagem automatizada: `godot --headless --path . --script res://qa0942.gd` e `godot --headless --path . --script res://qa0942_playable.gd`.
7. Abra uma cópia de save 09.4.1: o layout v1 e o progresso anterior devem permanecer.

## Escopo que continua pendente

O pedido 09.4.2 conserta o problema do **layout fixo da vila** e ancora os serviços às posições geradas. Não afirma corrigir empunhaduras, armaduras, invocados sem animação, personagem afundando no chão, cicatrizes obrigatórias, roupas sem camisa e áudio das habilidades/Deus. Essas falhas relatadas precisam de execução de Godot e correções próprias, para evitar misturar sistemas e causar novas regressões.
