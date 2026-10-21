# EXO WORLD GENESIS 05 — BATERIA EXTENSA DE TESTES E CORREÇÕES

**Estado: CANDIDATO DE FONTE PARA O WORK — NÃO CERTIFICADO NA GODOT.**

Data: 2026-10-18. Base: `EXO-WorldGenesis-04-Settlement-Core-FULL.zip`. Projeto: Godot, arquitetura regional de 88 regiões preservada. Não foi modificado o catálogo visual, o combate, os saves nem a organização regional existente.

## 1. O que foi realmente executado

| Verificação | Execução | Resultado |
|---|---|---|
| Fuzzing inicial de layouts 04 | Python, espelho de geometria | 10.000 cenários; 9.930 completos, 70 rejeitados |
| Fuzzing final de layouts 05 | Python, espelho de geometria | **56.000 cenários; 55.998 completos; 2 rejeitados** |
| Verificação independente de geometria 05 | Python, pós-condições de planos aceitos | 8.500 cenários completos; **191.336 lotes inspecionados; 0 violações** |
| Reprodutibilidade | Python, repetição de cenários amostrados | Nenhuma divergência observada nos cenários reexecutados |
| Atlas/portais existentes | Python, parsing de dois atlas arquivados | 176 registros regionais, 226 portais, 46 assentamentos, conectividade e cotas corretas |
| JSON e marcações da integração | Python, `check_settlement_static_05.py` | PASS; código presente e JSONs válidos |
| Arquivos protegidos | SHA-256, comparação com 04 | `world_planner.gd`, `region_data.gd`, `region_scene.gd`, projeto, `main.gd`, `arsenal.gd`, `journey_save.gd`: **inalterados** |
| Parser/compilação GDScript | Godot não disponível neste ambiente | **NOT_RUN** |
| Física, navegação, carga real e FPS | Godot não disponível | **NOT_RUN** |

**Cuidado estatístico:** 55.998 / 56.000 = **99,9964%** apenas nos cenários sintéticos usados. A simulação usa funções de terreno sintéticas, posições de saída construídas proceduralmente e RNG Python. **Não equivale a executar `settlement_planner.gd` dentro da Godot, nem representa a taxa de sucesso real com FastNoiseLite.** Os dois casos rejeitados não foram contados como gerados com sucesso e são rastreáveis pelos índices/entradas abaixo.

## 2. Defeitos encontrados e corrigidos no código

1. **Poço sobre corredor de saída regional (P0).** A versão 04 fixava o poço a apenas ~8 unidades do eixo da estrada principal, dentro da faixa de reserva. A versão 05 reserva um ponto válido antes de distribuir lotes, conferindo estrada, rio, limites e inclinação.
2. **Aldeia saturada com 3–4 saídas (P1).** Duas vias centrais não ofereciam lotes suficientes em regiões com rios/saídas numerosos. A busca de aldeia foi ampliada de forma limitada e ramificações secundárias são criadas para aldeias com pelo menos 3 acessos ou 2 rios. O padrão arquitetônico continua Murim.
3. **Bloqueio posterior do caminho de um lote (P1).** A validação agora checa os caminhos de todos os lotes contra todos os demais; o posicionamento também rejeita candidatos que bloqueariam entradas existentes.
4. **Bloqueio de acesso ao poço (P1).** A verificação inicial continha um erro no segmento examinado. Foi corrigida para comparar o centro da construção com o segmento entre o poço e a rua. A suíte de propriedades encontrou o problema e depois passou após a correção.
5. **Validador sem verificação de infraestrutura (P1).** Agora confere quantidade de poços, distância das vias e rios, conflitos com construções e acesso da infraestrutura.

**Observação:** o planejador ainda pode devolver `invalid` em configurações sem área viável. Isso é preferível a reduzir silenciosamente o número de residências; o gerador global deverá tratar esse caso com relocação de assentamento ou replanejamento, não instanciando plano parcial.

## 3. Resultados quantitativos — amostra sintética FINAL

- **56.000** cenários independentes (lotes variados por seed, escala, relevo aproximado, saídas e rios).
- **55.998** completos; **2** rejeições explícitas (`insufficient_valid_parcels`), sem aceitar lotes parciais como sucesso.
- **18.768** aldeias: 18.767 completas, 1 rejeitada.
- **18.696** vilas: 18.696 completas, 0 rejeitadas.
- **18.536** cidades: 18.535 completas, 1 rejeitada.
- Os dois cenários restantes foram `synth_7270` e `synth_17189`, com falta de **um único lote** em cada um. Eles são contraexemplos úteis e **não** podem ser omitidos de uma aprovação.
- A verificação independente das 8.500 situações aceitas totalizou **191.336 lotes**, sem colisões, obstrução dos trajetos, violações de faixa de rio/portal nem poço sobre lote **no modelo sintético**.

Os relatórios originais e os detalhes das falhas estão em `evidence/settlement_v05_synthetic/`. Os espelhos externos reutilizáveis estão em `tools/external_settlement_qa/`; eles são testes matemáticos, não transpiladores ou executores do código GDScript.

## 4. Riscos NÃO resolvidos — bloquear promoção

| Prioridade | Risco | Ação no Work |
|---|---|---|
| P0 | **GDScript 05 ainda não compilado** | Importar o projeto em Godot 4.6.2, registrar parser e erros de runtime antes de prosseguir |
| P0 | **Inclinação das ruas secundárias** | Rodar `tests/settlement_grades.gd` em 101 e 816204; checar terreno renderizado e colisores; corrigir gradientes perigosos |
| P0 | **Travessias de água sem pontes certificadas** | Inspecionar ruas vs. rios e cruzamentos reais; reservar travessias ou redesenhar ruas, sem ocultar barrancos/água |
| P0 | **Alcance de portas e poços no 3D** | Verificar trajetos físicos nas cenas, passagens livres e raio efetivo dos modelos |
| P1 | **Nenhuma recolocação regional para plano inválido** | Tratar raros `invalid` com decisão explícita do World Planner e log da seed, sem sumir com aldeias |
| P1 | **Custo de terreno urbano/colisores** | Medir ms de construção, pico de memória e FPS, comparando com piloto 03 no mesmo hardware |
| P1 | **Assets com formas L/U só em metadados** | Não considerar casas I/L/U visualmente finalizadas; integração geométrica virá depois |
| P1 | **Regressão das sete regiões piloto** | Rerodar `tools/run_genesis_qa.py` e testes de transição, água, altura e player |

## 5. Ordem de execução na Godot pelo Work

Não aumentar conteúdo, refazer UI ou tocar nos saves agora.

1. `python tools/check_settlement_static_05.py`
2. `python tools/run_settlement_qa.py /CAMINHO/PARA/GODOT 10000`
3. Avaliar arquivos `evidence/settlement_v05_real/*.log` e `summary.json`, inclusive `SETTLEMENT_EXTREME_RESULT` e `SETTLEMENT_GRADES_RESULT`.
4. Repetir testes de física, acessibilidade, cena e desempenho em 2–4 regiões de cada escala e nos casos mais acidentados. Cotejar os resultados de grade por rua, com imagens e posição no mapa.
5. Reexecutar **o piloto inteiro de sete regiões** com o runner anterior, para identificar regressões antes de integrar novos assets.
6. Devolver correções, logs completos, primeiros casos mínimos reproduzíveis, hash do build testado e medidas reais. Usar `PASS`, `FAIL` ou `NOT_RUN`, nunca considerar a existência de script como evidência de sua execução.

**Critério de promoção:** Godot importa sem erro; todas as regiões do atlas continuam acessíveis; a geração é determinística; nenhum plano `ready` contém colisões ou entradas inacessíveis; as ruas são transitáveis; a travessia de rios é física e visualmente válida; os custos de geração/cena são aceitáveis no hardware escolhido.

## 6. Arquivos modificados de execução

- `genesis/settlements/settlement_planner.gd`: **modificado**, código efetivo do núcleo.
- `SETTLEMENT-VERSION.json`: promovido de planner 1 para **planner 2, não certificado**.
- `tests/settlement_extreme.gd` e `tests/settlement_grades.gd`: **novos**; dependem da Godot.
- `tools/run_settlement_qa.py` e `tools/check_settlement_static_05.py`: **novos**; runners e auditoria estática.
- `tools/external_settlement_qa/`: **novo**, espelhos independentes de estresse e pós-condições.
- Relatórios, manifests e evidência: **novos**, sem substituição de cenas e assets do piloto.

`GENESIS-VERSION.json`, os relatórios herdados do Genesis 03 e o manifesto histórico do projeto **não são certificados para a versão 05**. O documento de hashes desta alteração é `SETTLEMENT-SHA256-05.json`.
