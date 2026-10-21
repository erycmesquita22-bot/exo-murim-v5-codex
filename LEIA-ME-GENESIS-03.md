# EXO World Genesis 03 — demonstração Godot

Projeto-fonte executado na **Godot 4.6.2 Standard, Compatibility**. Extraia o ZIP inteiro, importe `project.godot`, aguarde a importação e pressione **F5**. Não depende de Python para jogar. O executável da engine não faz parte do pacote.

A cena inicial é `genesis/demo.tscn`. Esta é uma demonstração isolada; não é uma atualização completa da campanha 09.4.6. Usa diretório de dados próprio e não carrega sua jornada anterior.

## Jogar

- WASD: mover; Shift: correr; Espaço: saltar.
- Siga as estradas até os arcos. Perto de uma passagem aberta, **E** carrega a região vizinha. É possível voltar pelo mesmo arco.
- **P** alterna preparação antecipada. Padrão: sob demanda. A preparação ainda bloqueia brevemente a thread principal.
- Esc fecha a demonstração.
- Os arcos cinza dizem “fora do piloto” e ficam bloqueados. O atlas tem 88 regiões externas; **somente as sete abaixo estão abertas nesta demonstração**.

| ID | Região demonstrada | Conexões abertas |
|---|---|---|
| 86 | Vila inicial | 52, 78 |
| 52 | Floresta / bosque misto | 86, 46 |
| 46 | Montanha | 52, 61 |
| 61 | Acesso de masmorra com pequena câmara caminhável | 46, 32 |
| 32 | Ruínas | 61 |
| 78 | Cidade, composição de maior densidade | 86, 63 |
| 63 | Vale campestre | 78 |

As regiões têm 512 m de lado. O percurso entre centros leva alguns minutos caminhando. A pequena câmara 61 tem teto aberto para inspeção isométrica; não constitui um gerador completo de interiores ou uma masmorra com campanha. Interiores continuam fora da contagem de 88.

## O que foi executado

- **2.048 seeds** na Godot: atlas de 88 regiões por mundo e um descritor regional por seed; zero falhas finais. Não são 180.224 cenas 3D testadas.
- Dois atlas LAB2 completos: 176 descritores regionais, 452 acessos com verificação de faixa e 62 pontas de rios.
- Sete cenas físicas: **36.377 consultas de terreno**, 80 apoios de fundação, zero falhas finais.
- Caminhada real automatizada com cápsula e rig da base: **6.28 km**, portas e câmara atravessadas, **12 transições por E e retorno à vila**, nos dois modos de carregamento.
- Persistência de atlas e seeds grandes, inclusive `9223372036854775807`: 264 seeds regionais preservadas no ciclo de gravação/leitura.
- 21 capturas da engine; nenhuma imagem conceitual gerada.

**Limites:** não houve sessão humana, teste Windows/Android, exportação executável ou aprovação artística. As suítes antigas da campanha não estão todas aprovadas; resultados separados em `evidence/legacy/`. Os 105 scripts/cenas herdados permaneceram idênticos. Consulte `QA-GENESIS-03.md` antes de interpretar documentos 09.x como evidência atual.

## Desempenho medido

Linux, renderização por CPU **llvmpipe**, 1152×720, câmera normal parada no centro de cada região, sem FPS fixo. Medições sequenciais, 1,5 s de amostragem após aquecimento por mapa.

| Medida | Resultado |
|---|---:|
| Planejamento nativo, média / p95 | 19.09 / 24.34 ms |
| Construção do descritor regional, média | 11.00 ms |
| Troca sob demanda, média | 1.31 s |
| Troca com cena preparada, média | 0.12 s |
| Custo antecipado de preparação, média | 1.22 s |
| FPS médio por cena, faixa dos dois modos | 41.9–46.7 |
| Memória estática rastreada, máximo sem preparação | 84.3 MiB |
| Memória estática com uma cena preparada, máximo | 119.5 MiB |
| Pico RSS do processo no benchmark completo | 344.5 MiB |

FPS acima é amostragem em repouso, não FPS durante carregamento ou caminhada. A antecipação desloca o custo de construção para a aproximação do portal; ainda não oferece streaming sem pausas. Uma cena fica ativa e no máximo outra é preparada/registrada para a troca. Não há 88 cenas residentes.

## Arquivos e reprodução

- `genesis/`: planner nativo, descritor regional, malhas/colisões, material, carregador e cena isolada.
- `tests/`: suítes novas executadas pela engine.
- `evidence/`: resultados finais JSON, logs, métricas, capturas e seeds corrigidas.
- `evidence/history/`: tentativas intermediárias, incluindo falhas reais; não são aprovações finais.
- `evidence/legacy/`: resultados atuais das suítes herdadas e prova na cópia intacta.
- `collection/`: acervo real, manifestos, procedência e fontes da coleção.
- `reference_lab/`: laboratório Python original para auditoria; não é dependência do runtime.
- `GENESIS-VERSION.json`: distingue versões do planner/terreno e da base preservada.

```sh
python tools/run_genesis_qa.py /caminho/para/Godot
# Acrescentar --render em máquina com display para capturas e benchmark.
Godot --headless --path . --script tests/plan_stress.gd -- 2048
Godot --headless --path . --fixed-fps 60 --script tests/playable.gd
Godot --headless --path . --fixed-fps 60 --script tests/playable.gd -- preload
Godot --path . --script tests/benchmark_genesis.gd
```

`--fixed-fps 60` é usado apenas para acelerar/reproduzir os testes de física; nunca o benchmark. O runner Python apenas lança processos Godot e verifica seus logs.

## Compatibilidade de seeds

O piloto lê o atlas LAB2 da seed 101, preservando IDs, conexões, categorias, biomas, seeds regionais e contratos de portal. Seeds uint64 legadas são guardadas como strings decimais para evitar perda no JSON.

**O planner Godot nativo 3 não é uma tradução bit a bit de NumPy/SciPy.** Mantém as cotas, grade geográfica, grafo Delaunay/MST com laços, limite de saídas, distribuição climática, drenagem descendente e determinismo. Usa FastNoiseLite e derivação SHA-256 versionada. Um mundo novo v3 pode ter outra geografia que o LAB2 com o mesmo número. Para preservar um mundo LAB2, carregue seu atlas; não gere outro por cima. O terreno Godot também tem versão regional 3 independente do loot/campanha preservados.
