# QA e auditoria — World Genesis 03

## Resultado e alcance

Os testes finais do **piloto de sete regiões** passaram, sem erro de script/engine nos logs finais. Isso comprova execução automática na Godot e os percursos descritos, não uma aprovação humana, universal ou artística. Não foi anunciado que os 88 mapas são jogáveis.

## Auditoria dos três pacotes

| Pacote / módulo | Achado no código | Reutilização / integração |
|---|---|---|
| Forjamento 02, `world_genesis_v2.py` | 88 regiões; cotas 23/12/10/43; 4 cidades, 7 vilas maiores e 12 aldeias; Delaunay/MST, reparos de grau, laços, serviços, clima e drenagem. Depende de NumPy, SciPy e NetworkX. | Atlas LAB2 mantidos como contratos de entrada; planner nativo v3 sem dependências Python, com MST e laços geográficos, regras de cotas e validação. |
| Forjamento, `region_synth_v2.py` | Grade 112² em 512 m, A* e nivelamento; não possui física Godot. O fallback de lote não garante por si só um prefab acessível. | Reescrito como gerador regional v3: malha/colisão de 1 m nas estradas e lotes, 4 m distante, encaixe entre resoluções, corredores graduados e acessos aos edifícios. Não há equivalência bit a bit com a grade NumPy. |
| Coleção 02, manifestos e GLBs | Os recursos são protótipos reais; não trazem colisões funcionais. Alguns módulos têm origem elevada, vãos que não aceitam AABB única e dimensões reais diferentes do grid nominal. | Texturas originais e GLBs reais importados. Malhas de cada asset consolidadas preservando cores por vértice; colisão triangular preserva portas/arcos. Paredes da câmara usam seu passo real de 3,3 m; fundação, parede e telhado têm alturas compatíveis. |
| Base 09.4.6 | `AGENTS.md` e projeto exigem Godot 4.6.2 Standard/Compatibility, apesar de referências divergentes no histórico de conversa. Rig, cápsula, animações e combate têm dependências próprias. | Cápsula criada por `main.gd.make_player()`, rig e animação originais. Adaptador isolado limita a execução à exploração; sem reconstruir o combate. 105 scripts/cenas herdados conferidos por SHA-256, sem alterações. |

A coleção permite uso no EXO e mantém sua documentação de origem. Licenças preexistentes da base foram preservadas. Nenhum recurso artístico novo foi inventado para substituir os GLBs entregues.

## Arquitetura executável

`world_planner.gd` planeja dados puros e salva/lê atlas com seeds decimais e precisão completa de floats. `region_data.gd` gera terreno, corredores, ecótonos, rios, pads e distribuição de plantas sem RNG global. `region_scene.gd` materializa chunks, texturas e colisões. `demo.gd` controla entrada, E, troca em duas fases, descarregamento e um único candidato preparado.

A preparação acontece fora da árvore. Para validar o destino com física, o candidato é registrado temporariamente a 2.048 m do mapa antigo. O commit ocorre após verificar piso e espaço para a cápsula. O mapa anterior é liberado e o jogador aparece no retorno do mesmo gate. Isso evita que a colisão antiga contamine a checagem do mapa novo.

As bases são niveladas, os módulos ficam presos ao mesmo root de rotação e as vias reservam a largura de passagem. As ruas também chegam aos lotes. O teto das casas se oculta quando o jogador entra. A câmara de masmorra possui vão normalizado para a cápsula e montagem curta de inspeção com teto aberto.

Rios macro viram canais locais com altura compartilhada por par de regiões e junção local consistente. A travessia de estradas usa aterro/galeria sob a via. Não é simulação de água, natação ou erosão. Paletas de fronteira misturam texturas reais até 50/50 no touchdown, numa faixa de 48 m. Não foi integrado o autotiling MSC4 completo do acervo.

## Testes automatizados finais

| Suíte | Execução / resultado |
|---|---|
| `plan_stress.gd` | Seeds 0–2047; 180.224 descritores macro planejados, 2.048 descritores regionais sintetizados, 32 mundos/regiões repetidos. Zero falhas. Exatamente 88; cotas/subtipos, seis ou mais biomas sem monopólio, clima finito, conectividade, laços, grau ≤4, spawn seguro, serviços em até quatro saltos, masmorras afastadas, gates bilaterais, paletas compartilhadas e drenagem descendente. Geração regional valida três linhas por estrada, pads, plantas e heights de gate. |
| `contracts.gd`, dois processos | Atlas 101 e 816204: 176 regiões; 452 acessos com três linhas cada; 62 pontas de rio. Zero falhas. Digest de 14 regiões preservado ao executar em processo novo. |
| `atlas_io.gd` | Seeds 101, 9007199254740993 e 9223372036854775807; gravação atômica, leitura, 264 seeds regionais preservadas e digest regional antes/depois. Zero falhas. |
| `physics_surfaces.gd` | Sete cenas instanciadas, 36.377 raycasts de terreno e 80 pontos de apoio de fundação. Zero falhas. Maior desvio amostrado entre consulta física e superfície analítica: 0.000135 m. |
| `playable.gd`, sob demanda | 6.278 km por `move_and_slide`; 12 transições usando ação E, todas as sete regiões, volta à vila e mesmo digest. Caminhada até casas, cruzamento de portas e entrada/saída da câmara 61. Zero falhas. Maior diferença chão/pés amostrada: 0.021 m. |
| `playable.gd -- preload` | Mesmo roteiro completo e 12 transições preparadas, sem falhas. Não houve teleporte para abreviar a caminhada: apenas transferência entre regiões. |
| Renderização | Sete cenas e 21 PNGs reais: câmera de jogo, visão geral e detalhe de asset por região. As capturas usam carregamento direto/câmera de inspeção, e não são evidência independente de caminhada. |
| Benchmark | Dois modos em sequência, sete mapas por modo, sem outra suíte concorrente. 14 linhas brutas em JSON/CSV. Sem FPS fixo ou gravação. |

Os raycasts distantes amostram vértices a cada 8 m; perto das vias incluem pontos interpolados da malha fina. Não são uma prova de todos os pontos contínuos do terreno. Nenhum teste automatizado substitui uma caminhada humana.

## Falhas encontradas e correções

`evidence/fixed-seeds.csv` registra 12 casos com seed/região. Os logs anteriores permanecem em `evidence/history/`.

- Nove casos nativos de fundação: seeds 40, 159, 183, 305, 462, 754, 994, 1066 e 1697. A suavização de um pad alcançava o plateau de outro. A reserva considera footprint e faixa de suavização; o corredor de acesso também evita outros lotes.
- Três casos nas faixas laterais, não na linha central: seed 101, regiões 66 e 82; seed 816204, região 87. A reserva de estrada foi ampliada para considerar o footprint e as laterais da via. A bateria completa dos dois atlas passou depois.
- Atlas 101 contém uint64 acima do máximo int64, embora o contrato diga 63 bits. Os números originais permanecem strings decimais; o seed do noise é obtido por módulo decimal seguro, sem cast que estoure ou arredonde.
- IDs numéricos lidos como float do JSON não passavam na busca estrita do array de regiões abertas. Conversão explícita dos IDs para int.
- Na chegada 86→52, a consulta podia usar o terreno antigo e deixar o jogador acima do chão novo. O destino agora é validado em espaço separado antes do commit.
- Correções de apresentação/colisão: altura fundação/parede/telhado, origem de props, dimensão real das paredes da câmara, largura/altura da entrada e união de LODs. Colisões sólidas usam layer 4, terreno layer 1; a máscara original 1|4 foi mantida.
- Erros de compilação e de harness ocorridos durante desenvolvimento foram corrigidos; só logs finais sem `SCRIPT ERROR`/`ERROR:` contam como aprovados. Comparação após reabertura usa IDs normalizados, sem confundir `32` e `32.0`.

## Desempenho e memória

Consulte a tabela no LEIA-ME e as 14 linhas de `evidence/metrics.csv`. Planejamento e construção lógica foram medidos na engine; cena/carga e FPS foram medidos em processo renderizado separado. O pico RSS, obtido pelo uso de recursos do processo Godot filho, foi **344.5 MiB**. O valor não inclui o Xvfb, que é processo irmão. Memória estática da engine não equivale a RSS ou VRAM.

A troca antecipada fica em 118.6 ms em média contra 1311.5 ms sob demanda; preparar custa 1224.5 ms antes disso. Os FPS estáveis excluem essas pausas e variam entre 41.9 e 46.7. O host é compartilhado e renderiza por CPU. Não extrapolar esses números para o PC do proprietário, GPU, Android ou câmera panorâmica.

**Pendência de performance:** construção incremental/assíncrona para eliminar a pausa de preparação; medir caminhada, câmera ampla, GPU e perfis gráficos. A antecipação é funcional, porém desloca um bloqueio de CPU em vez de eliminá-lo.

## Validação visual feita e pendências

Foram inspecionados PNGs da vila, montanha, masmorra/câmara, cidade, ruínas, bosque e vale: os assets reais aparecem, o terreno e os corredores são distintos, materiais importam e a montagem é visível. Isso não é aprovação artística. A cidade é uma composição maior de módulos de teste, não uma cidade final com serviços e população.

Permanecem pendentes: sessão humana no piloto; arte e level design final (incluindo suavizar cortes excessivos do relevo); cenário e colisão completos das outras 81 regiões; navegação de NPCs; interiores/dungeons completos fora da contagem; persistência de alterações de gameplay; integração do carregador à campanha; simulação de água; autotiling MSC4 completo; Windows/exportação/Android/GPU; multiplayer. O avatar e o combate aprovados foram preservados, não revalidados como novo produto completo.

## Suítes herdadas da campanha

A exigência de `AGENTS.md` foi seguida: `tools/run_checks.py --prologue` foi executado. A sequência encontrou falhas e timeout inicial em `assets_qa`; as suítes restantes foram executadas separadamente. Resultado atual: **5 suítes sem erros e 8 com falhas**, não “tudo aprovado”. Os logs 09.x anteriores do pacote são históricos.

Passaram discovery, fidelity, consolidation, ruins_martial e quality09. Falharam tests, release, assets, stabilization, martial, procedural, legacy_audio e war. Foram observados metadado `carry_sheath` ausente, expectativas antigas de edifícios/roupas, testes de armas e técnicas. `release_qa` foi repetido numa cópia intacta da base e apresentou os mesmos **27 passes / 10 falhas** em arco/besta. Não foi feita auditoria causal completa de todas as outras falhas.

Esses resultados impedem aprovar a campanha inteira; não ocorreram no loop isolado de geração/carregamento do piloto. O hash comprova que os 105 scripts/cenas herdados não foram alterados. Não reconstruí os sistemas de personagem ou combate para fazer suites antigas ficarem verdes.

## Conferência da entrega

`MANIFEST-GENESIS-03.json` enumera SHA-256 dos arquivos do ZIP. `input_integrity.json` registra os três arquivos de entrada e a preservação de código. Importação e boot de extração limpa são registrados em `evidence/fresh-*.log`. O runner novo aborta em erro de script/engine e não aceita só contagem de asserts.
