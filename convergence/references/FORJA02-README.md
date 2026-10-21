# EXO-Murim — Forja Arquitetônica 02

**Implementação independente para Godot 4.7.2 / GDScript, candidata a integração ao World Genesis.** Não altera os mapas do Genesis nem o EXO-Murim principal. Evolui a Forja 01 reutilizando os **87 assets GLB originais**, mantendo **387 arquivos herdados idênticos** e atualizando intencionalmente `catalog.json` para incluir **34 GLBs inéditos** e novos sistemas. Total: **121 modelos GLB**.

## Novidades reais

- Oito formas funcionais de fachada/montagem: `standard`, `veranda`, `merchant`, `teahouse`, `forge`, `herb_shop`, `inn` e `courtyard`. São **composições de estruturas base + peças reais**; **não** são oito prédios independentes com plantas interiores completas.
- Seis atividades de assentamento suportadas: `dwelling`, `shop`, `tea_house`, `workshop`, `herbalist` e `inn`; as duas primeiras só usam um piso se a configuração permitir, a hospedaria exige **largura >=6m e dois pavimentos**.
- Planta com pátio (quando lote e seed permitem), entrada externa, passagem central, portal e muretas; o prédio continua com porta real na face +Z.
- Três níveis de detalhe **estrutural/cosmético**: `low`, `medium` e `high`. O núcleo da casa não muda ao variar o perfil. A densidade dos detalhes é limitada por orçamento, com colisores simples para poucos obstáculos relevantes.
- Planejamento independente de praças e mercados em `forja/plaza_furnisher.gd` com seis peças e faixa de passagem central de 4m.
- Modelos adicionais de portão, muro de pátio, toldo, balcão, letreiro, ferraria, bigorna, bancas, carroça, poço, mobiliário para casa de chá, secagem de ervas e outros; consulte `docs/ASSETS-02-MANIFEST.json`.
- Ampliação do laboratório (aldeia/cidade/pátios/detalhes altos), nova galeria dos 34 GLBs e laboratório de praça independente.

## Como abrir e inspecionar

1. Descompacte tudo em uma pasta local; importe **`project.godot` na Godot 4.7.2** e aguarde o import de todos os GLBs.
2. Execute **F5**. Pressione **1** (aldeia), **2** (cidade), **3** (pátios), **4** (cidade com mais detalhes) e **R** (nova seed).
3. Para ver cada GLB novo, execute `res://forja/galeria.tscn` como cena atual (F6).
4. Para testar o mobiliário público, execute `res://forja/praca_laboratorio.tscn` (F6).
5. A imagem `previews/forja02-16-assets-reais.png` é uma **projeção offline da geometria dos GLBs reais**, não uma captura dentro da Godot.

## Testes incluídos

**Offline, já executados neste pacote:**

```bash
python qa/check_package.py
python qa/check_geometry.py
python qa/check_stress_offline.py
```

**Godot, preparados e AINDA NÃO executados nesta entrega (executar no Work):**

```bash
godot --headless --path . --editor --import --quit
godot --headless --path . --script res://qa/run_headless.gd
godot --headless --path . --script res://qa/benchmark_runtime.gd
```

O teste no motor executará ~12 mil lotes com múltiplas verificações, 1.000 seeds de praça, casos de erro, montagens 3D reais e inspeção de âncoras. O benchmark cria 4, 8, 16 e 32 casas para coletar tempo de instanciamento, nós e memória; **não é medição de FPS**. Os resultados aparecem em `qa/last_headless_result_v2.json` e `qa/benchmark_last_run.json` somente **depois** de executar esses comandos.

Consulte `docs/ROTEIRO-WORK-QA-02.md` para gates visuais/física/performance, e `docs/CONTRATO-GENESIS.md` para integrar somente depois da aprovação.

## Limites explícitos

- Ainda não foram validados **parser GDScript, cena Godot, navegação, colisão física em runtime, FPS, iluminação e gravação/carregamento reais** nesta execução, pois não havia binário do motor aqui.
- Nova versão de plano **`schema_version = 2`**. Não alimentar o Builder 02 com planos serializados na Forja 01; replanejar com seus lotes originais aprovados ou executar migração revisada. Nada modifica saves existentes.
- O gerador de casas usa a estrutura física de madeira/telhado da coleção modular. Interiores de hospedaria, loja, comércio, rotina de NPC e ligações verticais não estão prontos.
- Praças são MOBILIÁRIO de parcelas previamente aprovadas. Não são gerador de vias, tráfego, regiões ou terrenos; passagens de NavMesh não estão comprovadas.
- Os três níveis reduzem decorações **mas não** mudam automaticamente distâncias de visão, draw calls da casa original ou batches. Perfis de culling/HLOD e análise de FPS ficam para próximas fases.
