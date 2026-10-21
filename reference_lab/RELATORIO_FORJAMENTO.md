# Forjamento do World Genesis — medição e decisões

Data: 18/10/2026 · Base auditada: WorldPlanner LAB 0.1 e Teste Regional 02.

## Referência original, antes de qualquer modificação

- `ANTES_seed_101_regiao.png`: render do gerador regional anterior, **seed 101**.
- `ANTES_seed_816204_atlas.png`: atlas lógico do planejador anterior, **seed 816204**.

## Erros revelados por testes progressivamente mais exigentes

1. **1.200 seeds na primeira versão reforçada: 871 reprovações**; os testes anteriores eram permissivos. Causas: excesso de um bioma, diversidade baixa, regiões longe de serviços e raros nós com mais de quatro saídas.
2. Biomas reequilibrados com custo ambiental, correções locais, limite de concentração e pelo menos seis tipos por mundo; é necessário revisar o resultado artístico para evitar nichos raros isolados.
3. Rede de serviços melhorada com cobertura por saltos no grafo; reparação de saída com grau >4.
4. Adicionados contratos de passagem com entradas pareadas, afastamento mínimo e alturas compartilhadas; quando saídas próximas exigiam elevações incompatíveis, os contratos foram agrupados e nivelados.
5. Na primeira bateria de 1.200 regiões, **1 falha** de inclinação foi causada por bifurcações com trilhas niveladas isoladamente. Corrigimos a rede de alturas. Montanhas grandes reintroduziram **46 falhas** na bateria seguinte; corrigimos com projeção do gradiente.
6. Com o nivelamento reforçado, apareceram **2 falhas**, ambas criadas depois da estrada pelo nivelamento das fundações. Passamos a reservar a faixa da estrada antes de colocar edifícios.
7. As coordenadas das seeds regionais foram limitadas ao intervalo positivo de 63 bits para melhor compatibilidade futura com os inteiros de Godot.

## Números do estágio final do laboratório

Consulte os JSONs de stress para os valores realmente registrados. Nesta entrega, 3.000 gerações de atlas passaram nos **19 testes lógicos**; 1.200 amostras de regiões (400 seeds, três categorias de região) passaram nos **10 testes numéricos regionais** após os reparos. Um teste completo adicional gerou as **88 regiões da seed 816204** sem reprovações nos critérios examinados.

**Confiabilidade estatística:** com zero falhas em 3.000 amostras independentes e representativas, o limite superior aproximado de taxa de falha em 95% de confiança é de **0,0998%** para o mesmo conjunto de invariantes, e não 0,000001%. A afirmação “99,999999%” exigiria cerca de **300 milhões** de casos sem falhas sob suposições estatísticas simplificadas; mesmo isso não provaria qualidade visual ou correção do motor.

## Melhorias arquiteturais demonstradas

- 88 regiões e cotas: 23 assentamentos (**4 cidades, 7 cidades menores, 12 vilas**), 12 ruínas, 10 regiões de entrada de masmorra e 43 regiões naturais.
- 113 arestas regionais e 26 ciclos no plano padrão, com máximo de quatro saídas por região.
- Categorias de clima e bioma relacionadas à elevação, latitude aproximada e umidade, incluindo efeito orográfico simplificado.
- Rios macro com direção descendente num grafo geográfico (não há ainda água renderizada).
- Fronteiras com dados bilaterais de posição, altura, largura, ecótono e distância de pré-carregamento.
- Síntese local do solo, transições simples grama/terra/pedra, rotas por custo de inclinação, terraços para casas e perímetro lógico seguro.
- Separação clara entre plano global, região física, representação 3D e runtime da Godot.

## Limitações de qualidade

As imagens 3D do estágio V2 foram produzidas em renderizador externo com quatro materiais originais, dez módulos GLB do acervo e algumas primitivas auxiliares. **A qualidade visual dessas imagens ainda não equivale à referência final** (Minecraft Dungeons/Murim). A geração de terreno em baixa resolução pode deixar bordas e passagens a serem refinadas com chunks detalhados. Isso não é uma atualização jogável do EXO-Murim e não possui colisores/streaming Godot validados.

## Próximo marco recomendado

Integrar o atlas exportado ao Godot em cena de teste isolada; substituir a malha grosseira pelo sistema de terrain chunks e colisões; carregar sete regiões com portais válidos; conectar casas, ruínas e biomas aos módulos GLB revisados. Só então iniciar a escala de 88 regiões jogáveis.
