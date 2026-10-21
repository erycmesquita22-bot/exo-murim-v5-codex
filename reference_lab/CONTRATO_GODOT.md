# Contrato de integração com Godot (a implementar)

Este laboratório é Python e não é executável no Godot, tampouco um runtime de streaming. O JSON do atlas é o contrato de entrada, com IDs estáveis e sementes positivas de 63 bits.

## Mundo ao criar jornada
1. Atlas lógico com 88 regiões, IDs 0..87 e categorias com cotas exatas.
2. Arestas de `portals` têm ID estável e são a fonte única das coordenadas, alturas e paletas de fronteira para ambos os mapas.
3. As categorias `settlement` incluem `settlement_scale` de city/town/village; os locais de ruína e entrada de masmorra têm `site_variant`.
4. `biome_weights` apenas descreve o ecótono para o futuro shader/autotiling; o runtime precisa aplicá-lo fisicamente.
5. A rede hidrográfica `hydrology_macro` é um modelo agregado de drenagem, não água renderizada.

## Ao visitar uma região
1. Carregar os descritores do atlas e a seed de região, sem sorteios globais mutáveis.
2. Gerar grade lógica local de relevo e rios, corredores das passagens, lotes e materiais.
3. Validar grau de inclinação, acesso e área de colisão dos lotes; corrigir deterministicamente qualquer falha.
4. Construir chunks de malha e colisão com LOD; não usar a malha grossa de 112 x 112 como colisão do jogador.
5. Aplicar os módulos GLB licenciados e normalizados; instanciar NPCs, recursos e eventos por regras, não por coordenadas fixas.
6. Pré-carregar setores próximos e manter só regiões necessárias ativas; mudança de região em duas fases, com commit quando a próxima estiver pronta.
7. Gravar alterações permanentes separadas dos dados regeneráveis (baús, portas, NPCs persistentes etc.).

## Invariantes que o runtime deve testar
- Nenhum portal pode apresentar altura diferente do destino no contrato de fronteira.
- Saídas para outra região têm área segura e não terminam em vazio.
- O jogador não nasce dentro de paredes, rochas nem fora do navmesh.
- Edifícios jamais são construídos em cima de estrada ou uns sobre os outros.
- Arquitetura não se desprende em rotação; módulos possuem sistema de snapping validado.
- Efeitos de biome blending contínuos até as fronteiras.

## Engenharia de desempenho
O atlas é pequeno. Uma região quadrada de 512m, com malha local grossa de 112 pontos por eixo, tem amostra de aproximadamente 4,6m, insuficiente para colisão. Setores de 32m ou 64m podem usar malha refinada 1m ou 0,5m perto do jogador e LOD mais grosso ao longe. Validar CPU, GPU, memória e armazenamento nas opções de gráfico antes de fixar dimensões.
