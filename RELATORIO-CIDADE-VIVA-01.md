# RELATÓRIO — EXO-MURIM CIDADE VIVA 01
**Data:** 19/10/2026  
**Estado:** CANDIDATO / NÃO APROVADO (teste nativo Godot pendente)

## 1. Auditoria de entrada
- Base utilizada: `EXO-Murim-Fortificacoes-02-R2-PROJETO.zip` (arquivo localizado na Biblioteca do usuário; ~195 MB comprimidos).
- Referência de arte: `EXO-Forja-Arquitetonica-03.zip`. A base já inclui os assets Forja e o catálogo de 163 entradas; foi desnecessário importar cópias duplicadas.
- Caminho de integração: `genesis/region_data.gd` → `convergence/region.gd` → `exo_core/adapters_architecture.gd` → `cidade_viva/renderer.gd`.
- `Living World`: `convergence/occupancy.gd`, `convergence/streets.gd` e `living_world/` são mantidos.
- O Atlas de seeds 101 e 816204 possui 88 regiões cada; regiões 78/14/26 na seed 101 são cidades, e 14/26 têm rios no atlas.

## 2. Implementado de fato
- `cidade_viva/planner.gd`: bairros funcionais por função + proximidade de comércio/escola marcial, distribuição contextualizada de 21 tipos de assets com aleatoriedade local determinada por seed e ID do lote.
- Reserva geométrica: portas, corredores de saída, vias civis/portais, faixas fluviais, poço, parcelas, espaço mútuo entre objetos, desnível do terreno e margem interna da muralha.
- Densidade graduada com teto por assentamento: 12 assets adicionais na aldeia, 36 na vila/town, 82 na cidade; alguns assentamentos terão menos, conforme a segurança geométrica.
- A Forja usa seus próprios GLBs: banca, ferramentas, cestos, treinamentos, jardins, bancos, lampiões, carros, etc. A cena só instancia visual onde a regra passou.
- `cidade_viva/renderer.gd`: metadados de distrito/POI para futuras integrações, agrupamento numa árvore única e colisores simplificados para objetos grandes; não duplica NPCs.
- `convergence/region.gd`: aplicação após a fortificação, impedindo props dentro da margem do anel urbano. Toggle `urban_enabled` permite comparativo visual A/B da mesma seed.
- Nenhum contrato original de World Genesis, save, EXO Core, rotas de NPCs, Forja ou fortificações foi reescrito.

## 3. Verificação efetivamente executada neste ambiente
- **47/47 testes estáticos de contrato e assets passaram.** Verificados 14 arquivos centrais intactos e os 21 IDs de asset com arquivos presentes. Detalhes: `offline_contracts.json`.
- **350/350 casos do verificador sintético herdado do Settlement Genesis passaram**, somando 7.381 lotes. Trata-se de um espelho em Python **pré-existente**: não é teste da nova implementação em GDScript nem prova de comportamento físico do jogo. Detalhes: `legacy_genesis_synthetic_350.json`.
- Scripts de QA para Godot criados (`cidade_viva/tests/qa_cidade_viva.gd` e `capture_cidade_viva.gd`), **não executados** neste ambiente.
- Motor Godot não encontrado na máquina; acesso externo para obter o executável indisponível. Sem validação de parse GDScript, cena rodando, gameplay, colisão física real, FPS, memória ou imagens novas do motor.

## 4. Limitações e riscos conhecidos
- A grande geometria viária original continua a mesma para preservar saves/IDs: as ruas excessivamente retas e o anel de muralhas não são reprojetados aqui. Isto é uma melhoria de composição/ambientação, **não** um novo urbanismo estrutural.
- As famílias de assets pequenos são ilustrativas/ambientais; não há atendimento de comércio ou IA de transporte novos. O horário e as atividades continuam os do Living World já existente, e precisam ser observados dentro da Godot.
- Não foram adicionadas casas, NPCs nem identidades persistentes. O aumento de densidade é de objetos funcionais e anexos visuais próximos aos edifícios existentes.
- Distâncias de segurança e colisores dos objetos grandes precisam de QA com a geometria real dos GLBs; raia analítica não substitui testes físicos.
- Sem GLB personalizado, alguns objetos podem deixar espaço vazio entre si; tentativas de aumentar indiscriminadamente a densidade foram evitadas.
- Região 78 é um caso de cidade sem rio; para água usar 14/26. A eficácia do roteiro de captura ainda não foi comprovada.
- O budget de 82 adições não equivale a desempenho validado; medir nós, FPS/P95, memória e streaming com o jogo e efeitos completos.

## 5. Pendências obrigatórias antes da aprovação
1. Executar import na Godot 4.6.2 Compatibility, validar syntax/parser e todos os scripts de regressão; corrigir falhas encontradas.
2. Comparar a mesma seed e câmera com a opção urbana ligada/desligada; capturar no mínimo 10 telas novas diretamente do motor, com caminhos verificáveis.
3. Fazer testes físicos completos (porta, portal, caminho, rio, passagens fluviais, centro, área marcial, periferia, telhados, colisores).
4. Testar um dia do relógio de NPCs e saves antigos em dois processos, sem duplicar IDs.
5. Medir FPS, P95, memória, nós e carregamento com cenário A/B isolado; aprovar somente após revisão.

**Decisão técnica:** código integrado e auditado estaticamente, mas **NÃO APROVADO**. Não há evidência suficiente para afirmar que a Cidade Viva 01 está funcional/bonita na Godot.
