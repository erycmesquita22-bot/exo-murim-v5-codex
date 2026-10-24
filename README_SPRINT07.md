# EXO — SPRINT 7 / Estrada do Vau (ROAD-02-01)

Base integral: **EXO Haneul V1.0 Sprint 6**. Projeto de desenvolvimento distinto do antigo EXO-Murim. Godot 4.7.2 Compatibility.

## Escopo executado
- Região externa autoral de 128 x 720 metros: gramados, relevo suave, estrada desenhada diretamente na textura contínua, florestas, bambus e marcos.
- Portal de Haneul (próximo a x=-13, z=-101) para a ROAD-02-01, acessado com **F**. Retorno por F no portão de origem da estrada.
- Portão e muralhas parciais de chegada aos **arredores de Yunseong**. A cidade completa HWA-01 **não foi criada neste sprint**. F registra chegada, sem abrir uma cidade falsa.
- Marco da vila, santuário de caminho, duas paradas de viajantes, marcos de pedra e vegetação. No extremo de Yunseong foram reusados o portão, a casa de chá e o armazém do kit autoral Sprint 2.
- Identificadores fixos do Atlas HWA V0.1; mapeamento local isolado em (1200, 0, -1200). O trajeto 720m é uma **representação autoral jogável**, não uma equivalência geográfica exata dos 777m do atlas de planejamento.
- Mesmos 15 interiores, mesmo Character V3, mesmas variantes familiares. Nenhuma modificação no módulo de animação, skills, NPC ou clima.
- Correção visual encontrada em QA: autossombra do mesh denso gerava padrão de curvas de nível/anéis. Desativada apenas a projeção de sombra do terreno distante. Sombras dos props continuam ativadas.

## Operação
1. **Substitua integralmente** a versão ativa. Nunca instale por cima da V1.0. Abra `project.godot` na Godot 4.7.2.
2. Em Haneul vá à saída norte da vila, perto de `(-13,-101)` no eixo X/Z e pressione **F** quando aparecer o texto.
3. Caminhe até o portão no extremo norte da rota (Yunseong). F registra a chegada, mas HWA-01 permanece pendente.
4. Volte até o portão inicial e pressione F para retornar a Haneul. Dentro das 15 casas, F continua alternando interiores, sem conflito.
5. E saca/guarda arma. Os demais controles do Character V3 foram preservados.

## Garantias e limitações
- QA Godot 4.7.2 real: importação, nove amostras de colisão da estrada em cada família; fluxo tecla F de entrada/retorno; apoio físico do personagem no extremo distante; chegada ao portão e preservação do conteúdo anterior. Testes automatizados de duas famílias.
- Capturas Godot REAL em `world_sprint07/previews/`. Fonte de malha/atlas editável `world_sprint07/source/build_route.py`.
- Ainda não há cidade completa, NPCs, eventos, encontros, comércio de caravanas ou travessia física perfeita contínua sem transição. A cena da rota é carregada quando o jogador entra.
- **Pendente:** exploração manual de 720 metros, qualidade final de vegetação/composição, navegação NPC, benchmark e integração com módulo de clima/céu/shaders.
- O cenário contém apenas modelos/cores produzidos neste pacote ou reutilizados dos sprints originais anteriores, não contém bibliotecas externas novas. Conferir direitos comerciais antes de lançamento.
