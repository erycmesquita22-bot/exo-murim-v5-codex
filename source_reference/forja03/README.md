# EXO-Murim — Forja Arquitetônica 03

**Pacote independente de arquitetura voxel Murim para Godot 4.x, candidato a testes no motor e futura integração com World Genesis.** Evolui a Forja 02, preservando casas e praças existentes; não altera os mapas do Genesis, o jogo EXO principal ou os saves.

## Entrega real

- **163 modelos GLB no catálogo**: 121 modelos trazidos da Forja 02 e **42 modelos novos** no diretório `models/forja_v3/`. Todos os 42 têm geometria exportada, materiais e bounds no catálogo (5.148 triângulos ao todo no conjunto novo).
- **Fortificações:** módulos em pedra, madeira e ameias, cantos, dois tipos de portão com vão central, torres de observação e perímetros retangulares em lotes aprovados. Portões reservam 6m entre células vizinhas e deixam uma abertura útil de pelo menos ~4m.
- **Locais comunitários:** edifícios independentes para clã, templo e guilda; escola de artes marciais, área de treino com bonecos e armazeiro, celeiro e pequenas parcelas agrícolas. **Seis papéis planejáveis** com entradas/âncoras declaradas.
- **Compostos:** clã murado com planejamento combinado do salão e da fortificação; um lote, uma seed e um ponto de acesso coerente.
- **Ambiente:** faixa opcional de árvores, bambus e pomar, reutilizando modelos da coleção anterior e preservando o corredor local x=[−2,5; +2,5] metros.
- **Integração:** `forja/genesis_adapter_v3.gd` reúne lotes independentes, valida sobreposições/IDs, replaneja antes de construir e desfaz o batch diante de falhas.
- **Preservação:** 467 arquivos da Forja 02 permaneceram **byte a byte idênticos**, incluindo `forja/forja_planner.gd`, `forja/forja_builder.gd`, `forja/detail_pass.gd`, `forja/plaza_furnisher.gd` e `godot/modular_kit.gd`. As alterações intencionais de versões afetam `README.md`, `RELATORIO.md`, `project.godot` e `catalog.json`.

## Abrir o laboratório

1. Extrair todo o ZIP. Importar `project.godot` na Godot 4.x, aguardando a importação dos 42 novos GLBs e dos assets existentes.
2. Pressionar **F5** para abrir `res://forja/laboratorio_03.tscn`.
3. **Teclas 1–9:** muralhas; clã; templo; escola marcial; fazenda; celeiro; guilda; clã murado; vegetação de beira de estrada. **R:** alterar seed.
4. Os laboratórios da Forja 02 continuam em `forja/laboratorio.tscn`, `forja/galeria.tscn` e `forja/praca_laboratorio.tscn` (F6).
5. A imagem `previews/forja03-20-glbs-projecao-offline.png` mostra uma **projeção 2D offline da geometria GLB realmente exportada**, não uma captura da Godot.

## Módulos de programação

| Função | Arquivo |
|---|---|
| Lotes de casas, seis funções da V02 | `forja/forja_planner.gd` / `forja/forja_builder.gd` |
| Praça e mobiliário da V02 | `forja/plaza_furnisher.gd` |
| Montador de muralhas | `forja/fortification_planner.gd` / `forja/fortification_builder.gd` |
| Templos, clãs, guildas, celeiros e agricultura | `forja/civic_planner.gd` / `forja/civic_builder.gd` |
| Composição de conjunto muralha + sede | `forja/compound_assembler.gd` |
| Vegetação existente ao longo de eixo reservado | `forja/green_buffer_v3.gd` |
| Validação e construção de lotes múltiplos | `forja/genesis_adapter_v3.gd` |
| Gerador reprodutível dos 42 GLBs | `tools/build_assets_v3.py` |

## Testes

**Executado neste ambiente:**

```bash
python qa/verify_v3.py
```

Resultado final: **62.215 verificações aprovadas, zero falhas**, incluindo inspeção geométrica de todos os 163 GLBs, conferência de hashes da V02, 1.521 dimensões de fortificação, 40.000 reservas rotacionadas e 12.000 faixas vegetais. Isto NÃO comprova parse GDScript, import Godot, física real ou performance/FPS. A validação é autocontida (não depende de encontrar o ZIP da V02).

**Preparado, não executado aqui por ausência do executável Godot:**

```bash
godot --headless --path . --editor --import --quit
godot --headless --path . --script res://qa/run_headless.gd
godot --headless --path . --script res://qa/run_headless_v3.gd
godot --headless --path . --script res://qa/benchmark_v3.gd
```

Consulte `docs/ROTEIRO-WORK-QA-03.md` para colisão/navegação, renders reais e desempenho. Os scripts Python `qa/check_package.py`, `qa/check_geometry.py` e `qa/check_stress_offline.py` foram preservados da V02 como referência histórica; **seus assertivos fixos de versão/catálogo são destinados à V02**, não devem ser interpretados como suíte de aprovação da V03.

## Contrato de integração

O Genesis deve entregar parcelas com `id`, coordenadas globais, dimensão, `yaw_quadrants` e quatro alturas verificadas. `civic`, `fort` e `compound` exigem `approach_clear=true`; `green` exige `road_clear=true`. Exemplo em `examples/approved_sites_v3.json`. API:

```gdscript
const Adapter = preload("res://forja/genesis_adapter_v3.gd")
var plan = Adapter.plan_sites(world_seed, reserved_sites)
if plan.ok:
    var outcome = Adapter.build_sites(world_structures_root, plan)
```

**Limites:** muralha retangular para terrenos planos; não gerador de perímetros acompanhando o relevo de uma cidade inteira. Sem interior completo, NavMesh comprovada, rotinas de NPCs, comércio, geração de via, nivelamento, carregamento regional ou DLC. Não substituir o planejamento das 88 regiões nem misturar scripts da Forja na cópia principal até passar a validação Work/Godot. Para detalhes, leia `docs/CONTRATO-GENESIS-03.md`.
