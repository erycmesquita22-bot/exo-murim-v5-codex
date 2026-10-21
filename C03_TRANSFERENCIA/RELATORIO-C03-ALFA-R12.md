# EXO-MURIM — CONVERGÊNCIA 03 ALFA R12 — RELATÓRIO TÉCNICO

**Tipo de entrega:** revisão real e limitada de código sobre o ZIP integral R11, focada na primeira causa observável dos 121 erros Godot da captura. **Status: CANDIDATO NÃO HOMOLOGADO.**

## Origem e preservação

- Base EXCLUSIVA: `EXO-MURIM-CONVERGENCIA-03-ALFA-R11.zip`.
- SHA-256 verificado: `44d2408b91531ca5abe7ea3240a40445f631c5a90a26ece3c5356b09739b9a58`; ZIP R11 possui 4698 entradas, CRC íntegro.
- Nenhum arquivo original excluído. Nenhuma autoridade de combate, WorldGenesis, Dungeon, NPC, visual, Arsenal, Terrain Forge ou Core alterada semanticamente.
- `project.godot`: somente `config/name` alterado para `ALFA R12 QA` a fim de manter a pasta de dados do teste separada das R10/R11. Não migra nem apaga saves existentes.

## Erros reproduzidos no código-fonte

Na captura da Godot R10 observou-se `Used space character for indentation instead of tab as used before in the file` no `convergence/game.gd` linha 401/seguintes, em meio a 121 mensagens. Confirmado o mesmo padrão em R11: **8 scripts misturavam indentação por tabs e por espaços; 242 linhas afetadas**.

Sete scripts usam blocos novos com UM espaço por nível, enquanto `regional_ecology/territories.gd` usa QUATRO por nível. Não foi aplicado um algoritmo global que troca todo espaço por tab: cada bloco foi convertido de acordo com sua unidade de indentação, mantendo o restante do texto de cada linha exatamente igual. O diff permite auditoria humana.

| Script | Linhas corrigidas | Unidade original |
|---|---:|---:|
| `convergence/game.gd` | 126 | 1 espaço(s) |
| `regional_ecology/territories.gd` | 31 | 4 espaço(s) |
| `convergence/region.gd` | 30 | 1 espaço(s) |
| `genesis/settlements/settlement_planner.gd` | 22 | 1 espaço(s) |
| `inventory.gd` | 16 | 1 espaço(s) |
| `cultivation.gd` | 6 | 1 espaço(s) |
| `regional_ecology/rewards.gd` | 6 | 1 espaço(s) |
| `regional_ecology/director.gd` | 5 | 1 espaço(s) |

**Total:** 242 linhas, nos oito arquivos.

## Verificações efetivamente executadas

- SHA e teste CRC da R11: PASS.
- Cotejo linha a linha dos oito scripts: PASS, nenhuma alteração além do recuo inicial.
- Cobertura dos arquivos preservados e JSON: 399 JSON carregados no parser Python sem erro; 461 scripts inspecionados estaticamente.
- Referências `preload(...)` literais inexistentes: 2 preexistentes, em `godot/demo.gd` e `exo_core/module_template/test.gd` (laboratórios). **Não foram forçadas alterações no jogo principal para satisfazer fixtures históricas.**
- Novo teste GDScript `res://convergence/tests/qa_c03_r12_native.gd` preparado para varredura de recursos e parser; **NÃO EXECUTADO**.
- QA Python de reprodução incluído em `C03_TRANSFERENCIA/scripts_de_auditoria/qa_c03_r12_static.py`. A aprovação Python não equivale a parser Godot.

## LIMITES E BLOQUEIOS

**Godot 4.6.2 NÃO foi executada neste ambiente.** Não existe binário Godot local e o acesso a GitHub/índice Python falhou por DNS; não foram executados parser, import de shaders/GLB, F5, criação de campanha, cenários, rollback, saves nem benchmarks. Portanto, **não afirmamos que os 121 erros caíram a zero**, embora a causa textual identificada tenha sido corrigida.

Correções de runtime, erros de tipo, cena ou dependência que só apareçam após um parser válido não podem ser antecipadas com segurança. Repetir inspeção de Godot para cada nova falha sem apagar sistemas.

## Procedimento de teste real (PC Godot 4.6.2 Compatibility)

1. Extrair R12 para uma pasta nova; **não substituir saves pessoais**. Fazer cópia do ZIP e do user-data correspondente.
2. Na Godot 4.6.2, abrir `project.godot` com Compatibility; importar os recursos; capturar mensagens de parser e salvar logs.
3. CLI equivalente (adaptar caminho do executável):
   `godot --headless --editor --path <R12_ROOT> --import --rendering-method gl_compatibility`.
4. Depois: `godot --headless --path <R12_ROOT> --script res://convergence/tests/qa_c03_r12_native.gd`. Usar os logs do Godot; códigos de saída zero sozinhos são insuficientes.
5. Corrigir as próximas **causas-raiz** reportadas nativamente, se houver. Só declarar zero erro após executar de fato.
6. Abrir F5: menu → criador → aventura procedural → primeira região → player caminha → troca de região → NPCs/fauna → combate → dungeon → interior → salvamento/retomada. Desligar Terrain Forge se necessário somente como teste A/B, não remover arquivos.
7. Reexecutar suites R3–R11, especialmente `res://convergence/tests/qa_c03_r11_native.gd`, R10 humanoides, R9 marcial, R7 Forja, R6 Dungeon/Itens e Core Persistence. Capturar telas e comparar FPS Vega8 reais.
8. Se restarem erros, encaminhar logs completos e usar **R12 como nova base**, nunca regredir à R10.

## Prioridades após validação

- Parser/import e abertura do jogo: bloqueios máximos.
- Depois bugs reais de gameplay e regressão (criação de personagem, mapa TAB, missões ruínas, voos, controles/armas, NPCs, region travel).
- Depois optimização e acabamento visual. Não inaugurar Convergência 04 por causa de falhas corrigíveis.
