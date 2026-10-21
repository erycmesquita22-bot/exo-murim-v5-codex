# EXO-Murim — Fortificações 01 | Forjamento e QA pré-Work

Data: 18/10/2026. Fonte arquitetural auditada: `EXO-Murim-Mundo-Vivo-02-R2-POLIMENTO-CANDIDATO.zip`, com contratos reais de `genesis/settlements/settlement_planner.gd`, `genesis/region_data.gd`, `convergence/region.gd` e catálogo GLB. **O destino de integração é a R3 já validada pelo Work, e NÃO a R2 antiga.** O kit não contém cópia substituta de `region.gd`.

## Resultado principal

- **20.000 cenários sintéticos** em quatro execuções de 5.000 casos (cada uma terminou PASS).
- **0 violações geométricas reportadas** pelo oráculo independente nos resultados aceitos. Casos inválidos são contabilizados separadamente.
- **115.003 verificações adicionais de mutação e casos adversariais**, 0 falhas na execução final.
- **2.178.002 peças de muralha/parede calculadas**, **111.785 aberturas rodoviárias** e **51.217 torres elegíveis** ao todo nos cenários sintéticos; estes números são operações simuladas, não objetos 3D realmente instanciados.
- **9.501.519 verificações elementares contabilizadas** no modelo massivo (contagem ponderada de invariantes), não asserts da Godot.
- **Validação do instalador em cópia isolada:** dry-run, cópia dos quatro scripts, anexação preservando o script existente e rejeição de segunda instalação: PASS.
- **Engine Godot/GDScript, colisões físicas, renderização e FPS: NOT_RUN neste ambiente** (o executável da Godot não está instalado). Os scripts nativos e o renderizador serão executados no Work.

### Distribuição de resultados

| Escala | Ready | Partial | Skipped | Invalid explícito | Total |
|---|---:|---:|---:|---:|---:|
| Cidades | 5.428 | 1.223 | 0 | 16 | 6.667 |
| Vilas | 6.374 | 219 | 33 | 41 | 6.667 |
| Aldeias | 6.383 | 206 | 35 | 42 | 6.666 |
| **Total** | **18.185** | **1.648** | **68** | **99** | **20.000** |

**Partial não é sinônimo de cidade fortificada completa.** Indica trechos suprimidos por proximidade a uma estrada, rio ou relevo impraticável, e necessita de validação visual e reprojeto caso a abertura fique inadequada. `Skipped` ocorre quando não há espaço seguro para o muro de pátio; não elimina construções ou NPCs. `Invalid` indica impossibilidade explícita (99 casos adversariais), sem gerar muralhas flutuantes ou geometria espúria. Não houve erro de validação nas plantas aceitas.

## Arquivos entregues

- `fortifications/planner.gd`: interpreta os dados da região (lotes, ruas, portais, rios e terreno). Produz plano com segmentos, portões, torres e status.
- `fortifications/renderer.gd`: visualização 3D provisória via MultiMesh, materiais voxel simples e colisores do muro; aberturas de portões marcadas com pilares visuais ainda sem colisores.
- `fortifications/adapter.gd`: aplica plano e renderização, mede o custo e devolve status, sem alterar o World Genesis.
- `fortifications/qa_native.gd`: suíte GDScript pronta para a Godot 4.6.2 e baseada em seeds reais do World Genesis.
- `tools/apply_to_project.py`: instala o módulo na R3 de forma opt-in, sem sobrescrever o `convergence/region.gd` validado.
- `tools/fortification_reference.py`, `tools/stress_fortifications.py`, `tools/adversarial_fortifications.py`: simulador geométrico independente, stress por intervalos e validação adversarial.
- `results/`: logs JSON individuais, consolidados, adversariais e do instalador.

## Defeitos, correções e riscos identificados

1. A geração atual do EXO fornece muros de pátio, mas não muralhas de cidade completas com torres e portões. O kit implementa **planejamento e protótipo visual**, não o conjunto arquitetônico final da Forja.
2. Ruas cruzando a futura muralha criariam bloqueios se fossem usados trechos sólidos. Foram introduzidas interseções geométricas e largura de abertura dependente do ângulo, inclusive para passagens aos portais externos.
3. Declives excessivos poderiam produzir paredes flutuantes. A regra de amostrar a cada 25% e rejeitar variações acima de 2,4 m por módulo evita esse comportamento no modelo.
4. Testes adversariais iniciais tiveram 16 falhas de **expectativa incorreta**: mover um lote ainda dentro da área cercada não deve necessariamente alterar o perímetro. O teste foi refinado para alterar um lote extremo, sem mudar o código de planejamento por causa dessa falsa premissa. Resultado final: 115.003 verificações, zero falhas.
5. Perímetros parciais continuam frequentes em geometrias de ruas/rios; o próximo refinamento deve transformar cortes irregulares em portões secundários, aquedutos, paredes escalonadas ou limites geológicos coerentes. Não disfarçar `partial` como fortificação completa.
6. A estrutura R3 validada pelo Work possui conserto de espaçamento dos NPCs. O kit **não contém** uma cópia de `convergence/region.gd` antigo, e o instalador aborta em caso de conflitos.

## Testes obrigatórios no Work

1. Extrair a última `EXO-Murim-Mundo-Vivo-02-R2-VALIDACAO-FUNCIONAL.zip` (R3 corrigida) em pasta limpa.
2. Extrair este patch na pasta auxiliar e inspecionar `README.md` e `fortifications/optional_hook.txt`.
3. Rodar `python tools/apply_to_project.py /caminho/R3` (dry-run) e, se compatível, adicionar `--apply`.
4. Com Godot 4.6.2 Standard Compatibility: executar importação limpa, `res://fortifications/qa_native.gd`, regressões gerais existentes, cena principal e renderização real.
5. Medir cruzamentos de todos os portões com cápsula de jogador/NPC, interseção de rua/caminho, acesso a casas, guarnições de guarda, colisões e fundamentos no terreno.
6. Capturar em jogo a cidade 78, uma vila e uma aldeia; repetir com seeds 101/707/816204 e extremas de 64 bits. Fazer screenshots sem imagens conceituais.
7. Verificar perspectiva isométrica: trechos altos atrás da câmera precisam desaparecer/ficar translúcidos se ocultarem o jogador; preservar a navegação.
8. Medir tempo adicional de instalação de muralhas (`fortification_ms`), nós da cena, triângulos/meshes, memória e FPS antes/depois, especialmente cidade 78.
9. Entregar resultados PASS/FAIL/NOT_RUN, logs brutos, falhas mínimas reproduzíveis, capturas reais, ZIP Godot integrado e relatório de mudanças.

**Critério de aprovação futura:** nenhuma rua de acesso bloqueada, 100% dos portões fisicamente acessíveis, nenhuma colisão com construções, nenhum trecho flutuante, save e combate sem regressão, qualidade visual suficiente, tempo de carga e desempenho aceitáveis. A atual rodada offline NÃO satisfaz sozinha esse critério.
