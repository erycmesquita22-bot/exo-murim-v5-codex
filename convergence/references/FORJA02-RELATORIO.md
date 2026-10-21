# RELATÓRIO REAL — EXO Forja Arquitetônica 02

Data: 2026-10-18. Escopo independente: sem escrever no World Genesis nem no projeto principal do EXO-Murim.

## Implementado

**34 novos GLBs** com geometria real e materiais PBR simples (mais **6.068 triângulos no conjunto inteiro de novos modelos**), combinados com **87 GLBs herdados** e **5 paletas originais**. Novo planejador de papéis/arquétipos com seed, pátios, três perfis de detalhe e validação da reserva física. Montador com peças de profissões e caixas de colisão econômicas para obstáculos maiores; galeria + laboratório de praça + gerador independente de mobiliário público.

O catálogo passou de 87 para 121 itens. `catalog.json` foi ampliado de propósito; os **387 outros arquivos identificados no manifesto de origem** mantiveram SHA-256 inalterado.

## Testes OFFLINE executados após correções

| Suite | Execução | Resultado |
|---|---|---|
| `qa/check_package.py` | hashes legados, schema, IDs, caminhos, referencias, estrutura textual dos scripts | **963 verificações, 0 falhas** |
| `qa/check_geometry.py` | parse GLB, checagem de AABB vs catálogo, remontagem de 120 combinações de 8 arquétipos/3 perfis e corredor de acesso | **663 verificações, 0 falhas**; 121 GLBs lidos |
| `qa/check_stress_offline.py` | simulador/referência geométrica de lotes, assinaturas por seed, reserva rotacionada e mobiliário | **707.388 verificações, 0 falhas**; 120 mil cenários de lote + 18 mil praças simuladas |

**Defeito encontrado e corrigido**: na primeira rodada de `check_geometry.py`, a versão `standard` usava vaso/lanterna com AABB além da reserva original (`z=3.05`). O planejador passou a reservar até `z=4.95` para as fachadas com detalhes; depois da correção, 120 combinações passaram. Nenhuma falha foi ocultada nos relatórios finais.

**Escopo do stress:** o script Python simula os invariantes de engenharia e **não executa o RNG/GDScript nem a física da Godot**. Contagens altas não demonstram 100% de sucesso do projeto em gameplay.

## Testes na Godot preparados, ainda pendentes

`qa/run_headless.gd`: 12.000 lotes + 1.000 seeds de praça + casos negativos + instanciação das seis funções e batch; `qa/benchmark_runtime.gd`: 4/8/16/32 casas reais por seed com métricas, quando executado. As cenas `laboratorio.tscn`, `galeria.tscn` e `praca_laboratorio.tscn` precisam inspeção visual na Godot. Execução **não foi possível neste ambiente**, por ausência de Godot instalado e acesso à distribuição do binário.

## Limites e riscos remanescentes

1. As 8 fachadas usam a casa-base existente; não há interiores comerciais/templos completos. Algumas peças criadas são apenas catálogo para World Genesis e decoração futura.
2. A entrada do pátio é checada por geometria AABB e reserva de corredor, **não** por pathfinding em malha de navegação.
3. Grande parte das paredes herdadas ainda gera colisores trimesh individuais; custo real em 32 casas precisa medição antes de otimização (não reescrever o kit sem evidência).
4. Integridade SHA-256 preservada dos originais não é sinônimo de execução fiel: a Godot deve importar 34 GLBs e passar gates G0-G6.
5. Sem autorização, nenhuma cena ou script foi inserido no World Genesis nem no EXO-Murim 09.4.6.

**Decisão:** marcar como **candidato para validação Work/Godot**, não como código já aprovado para produção.
