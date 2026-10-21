# EXO-Murim — Fortificações 01: Forjamento e testes prévios

**Status: módulo candidato, NÃO integrado/aprovado na Godot.**

## Arquitetura e escopo

O módulo `fortifications/planner.gd` lê o contrato real de `genesis/region_data.gd` e `genesis/settlements/settlement_planner.gd` sem alterar o plano: coordenadas regionais XZ, lotes com raio 5,5 m, ruas e suas larguras, caminhos até os portais, rios, altura do terreno e área útil de 512×512 m. Ele calcula:

- **Cidades:** perímetro chanfrado com oito vértices, seções de 2,8 m no máximo, torres onde não conflitam com passagens, aberturas nas ruas de acesso e nas travessias de rios.
- **Vilas e aldeias:** somente um pequeno pátio cercado quando existe espaço e acesso seguro. Nenhum fechamento universal de aldeia.
- **Proteção de vias:** abertura dinâmica de largura baseada na direção da via; passagem tangencial demanda mais espaço. Trechos que permanecem próximos a vias/rios são cortados explicitamente, nunca construídos por cima.
- **Relevo:** amostragens de terreno no início, 25%, centro, 75% e fim de cada trecho; fundação abaixo da menor amostra; interrupção em desnível acima de 2,4 m por trecho.
- **Status obrigatório:** `ready`, `partial`, `skipped` ou `invalid`, com contagem dos cortes e motivos explícitos. Falha de viabilidade não é disfarçada como sucesso.

`renderer.gd` contém **visualização voxel provisória** de módulos e portões (portões marcam o vão e possuem postes sem colisão); muralhas recebem colisores reais. A modelagem final de torres, ameias, escadas e portões pertence à Forja, e precisa ser montada e testada na Godot.

## Aplicação sem regressão

**NÃO** substituir `convergence/region.gd` por sua cópia na R2: o Work corrigiu destinos dos NPCs na R3. Para preparar a integração no projeto R3 recém-extraído:

```bash
python tools/apply_to_project.py /caminho/para/EXO-Murim-R3
python tools/apply_to_project.py /caminho/para/EXO-Murim-R3 --apply
```

O comando sem `--apply` apenas descreve a mudança. O modo `--apply` copia os scripts e adiciona um hook ao final do `region.gd`; aborta sem fazer nada se outro método `build()` já existir, se faltarem arquivos ou se o módulo tiver sido instalado anteriormente. Não muda saves, IDs, regiões ou lotes.

## Testes offline executados aqui

```bash
python tools/stress_fortifications.py --cases 5000 --start 0 --universe 20000 --output results/shard_00000_05000.json
python tools/stress_fortifications.py --cases 5000 --start 5000 --universe 20000 --output results/shard_05000_10000.json
python tools/stress_fortifications.py --cases 5000 --start 10000 --universe 20000 --output results/shard_10000_15000.json
python tools/stress_fortifications.py --cases 5000 --start 15000 --universe 20000 --output results/shard_15000_20000.json
python tools/adversarial_fortifications.py
```

Resultado consolidado em `results/QA-FORTIFICACOES-01-AGREGADO.json`. **Os casos são sintéticos baseados nos contratos reais; não são mundos completos instanciados na engine.** O teste adversarial falhou inicialmente por exigir variação da muralha ao mover um lote interno sem alterar sua fronteira. Essa premissa incorreta foi substituída por alteração de um lote extremo e a suíte passou.

## Comandos para Work (Godot 4.6.2 Standard, Compatibility)

Executar **somente depois de extrair a R3 e aplicar o módulo**:

```bash
godot --headless --editor --import --quit
godot --headless --path . --script res://fortifications/qa_native.gd
python tools/run_convergence012_checks.py /caminho/para/godot --rendered
```

A renderização, os portões transitáveis, as cápsulas de NPCs, os níveis do terreno e o FPS ainda precisam de QA físico. Validar especialmente cidade 78, aldeia 86, vila 15 e seeds 101, 707, 816204 e extremos de 64 bits. Em seguida, seguir com Work: ver captura real, medir construção, verificar quatro direções de acesso, colisão de portais, ocultação isométrica, segurança dos moradores e desempenho antes/depois.

## Portões e outras limitações

- O protótipo tem **aberturas planejadas e marcadores de portões**, não torres monumentais ou portões históricos acabados.
- Trechos `partial` devem ser vistoriados: a prioridade é **não bloquear vias nem deixar muralhas flutuando**.
- Fontes visuais existentes: `models/architecture/wall_stone_2m.glb`, `models/forja_v2/courtyard_wall_2m.glb` e `models/forja_v2/courtyard_entry_gate.glb` não substituem ainda o kit de muralhas urbanas.
- Metas de `0 casos geométricos rejeitados` seriam inadequadas: em terrenos inviáveis, rejeição explícita é comportamento correto.
- **Não há binário Godot neste ambiente.** Nenhuma afirmação de compilação ou de FPS nativos é feita nesta entrega.
