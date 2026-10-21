# EXO-MURIM — FORTIFICAÇÕES 02 / EXO River Gate

**Versão:** CANDIDATO-CORRIGIDO — **não aprovada como OFICIAL**.

## Implementação entregue

Este patch altera o projeto Godot real fornecido e não cria um segundo gerador de mundo. `fortifications/river_gate.gd` planeja uma travessia sobre as linhas existentes de `RegionData.rivers`, referenciadas por índice e geometria de `river_hub` a `r.p`. Lê cotas de superfície do contrato Genesis, valida margens e declives, rejeita curvas quase paralelas à muralha, portões rodoviários conflitantes e ligações em cantos. O curso da água, relevo, parcelas, vias, 88 regiões, NPCs e contratos de save não foram alterados.

`fortifications/planner.gd` registra para cada interseção o índice do rio, a abertura geométrica e a travessia associada. Distingue `river_openings` intencionais de lacunas de segmento rejeitado, que continuam bloqueando a aprovação. `exo_core/adapters_architecture.gd` instancia os portões apenas para um plano inteiramente `ready`; outros resultados seguem `BLOCKED` e não depositam muralhas parciais.

Peças arquitetônicas em estilo voxel formam pilares de margem, abóbadas vazadas, passarela e parapeitos. As peças se repetem por `MultiMesh` e colliders em um `StaticBody3D`, mantendo somente duas instâncias de MultiMesh por travessia. Reutiliza `city_wall_battlement_2m` e as torres da Forja 03. Três tamanhos são diferenciados pela extensão projetada: pequeno até 27 m, médio até 44 m e monumental até 94 m. No monumental, arco múltiplo transversal exige apoios intermediários em ilhas SECAS válidas; na ausência deles usa-se arco amplo com nervuras paralelas, sem pilares dentro da água. Isto é uma configuração alternativa, não alega possuir pilares ou múltiplos vãos sem sustentação.

O contrato principal mantém nove módulos; apenas `architecture` passa de `1.0.0` para `1.1.0` por adicionar campo de leitura `river_gates`. Nenhum evento novo ou domínio de save foi introduzido. A raiz v4 e seus arquivos antigos são preservados.

## QA realizado e limites

**PASS estático:** extração e integridade do arquivo-fonte; comparação de todos os arquivos originais com hashes SHA-256; conferência das únicas quatro modificações previstas; presença dos três scripts novos; consistência dos nove módulos; verificação simples de equilíbrio de delimitadores GDScript. Essas verificações **não substituem parser, importação ou física da Godot**.

**NOT_RUN:** importação limpa na Godot 4.6.2, testes nativos e físicos, cidades fluviais com seeds reais, cidade 78, testes de persistência/reabertura, Core/Jornada/Narrativa/Skin/combate/NPCs, números de FPS/nós/memória/carregamento e seis capturas reais. O binário Godot não está instalado neste ambiente; tentativa de buscar a distribuição externa falhou por DNS indisponível. Não há capturas novas anexadas. Sem esses testes não existe aprovação OFICIAL.

## Gates de validação na Godot

1. Importar a pasta no editor Godot 4.6.2 Standard / Compatibility sem erros; registrar log de importação.
2. Executar `--headless --path . --script res://fortifications/qa_river_gate.gd` e `fortifications/qa_native.gd`. A primeira suíte cria três travessias físicas, testa abertura de água e verifica determinismo e cidades com os dados de hidrografia reais do Genesis.
3. Executar `exo_core/tests/qa_city.gd`, `qa_core.gd`, `qa_integration.gd`, demais suites do release anterior, scripts de Jornada/Narrativa/Skin/Forja e persistência; não aceitar SCRIPT ERROR.
4. Rodar com viewport `--path . --script res://exo_core/tests/capture_river_gate.gd`. As capturas só são gravadas para regiões reais que contenham travessias aprovadas; tipos ausentes permanecem **NOT_RUN** e exigem outras seeds reais.
5. Navegar com jogador e NPCs pelas ruas, conferir pontes e portais regionais, água/colliders e volumes acima/abaixo de cada arco; confirmar colisões próximas sem interseção.
6. Comparar performance com os mesmos parâmetros anteriores e reabrir saves em processo novo. Somente depois dessas evidências revisar a promoção.

## Riscos conhecidos / sem aprovação

- Terrenos onde o Genesis aterra a cidade podem ocultar visualmente o rio, apesar da malha hídrica contínua; o patch **não** altera esse comportamento do terreno por contrato.
- Canais tangentes aos muros, curvas em esquinas, margens instáveis, arcos adjacentes a portões terrestres e trechos fora do limite de 94 m são recusados até solução física verificada.
- As colunas de uma travessia monumental não são colocadas no leito molhado apenas para forçar a composição de múltiplos vãos.
- A continuidade de navegação sobre a passarela do perímetro NÃO foi validada. A travessia não é um portão de NPCs.
- Material/textura e proporções finais são provisórios até inspeção visual na engine.

**Decisão:** Entregar CANDIDATO-CORRIGIDO, sem utilizar o nome `EXO-Murim-EXO-Core-01-OFICIAL.zip`.
