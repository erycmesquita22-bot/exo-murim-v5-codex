# EXO-Murim 09.4 — O Mundo Desperta

Base: EXO-Murim-09.3.3-Encaixes-Sem-Esticar-Bracos.zip.

## Alterações reais no código

- `world/biome_plan.gd`: layout determinístico de vila, quatro condições de nascimento, lotes de casas não essenciais, perfis de decoração, distribuição por seed.
- `world/landscape.gd`: malha contínua com relevo FastNoiseLite, colisão trimesh, passagem entre vila, bambuzal oriental, montanhas ocidentais e ruínas do norte. Acesso por trilhas, sem os muros retangulares originais. Deslocamento ambiental por seed.
- `region.gd`: mantém imóveis principais, mestre/guilda/pousada/descanso/pátio, missão e arena originais; cria bairros variáveis e estética de cada tipo de vila, sem mover serviços obrigatórios. Adapta caminhos e vegetação.
- `world/village_composition.gd`: remove bambus de posições ocupáveis por casas variáveis.
- `main.gd`: gerenciamento de geometria regional própria que permite reconstrução limpa ao alterar a seed; pontos de exploração; recompensa com item procedural e evento coletado persistido.
- `murim_flow.gd`: personagem inicia na vila correspondente à seed escolhida; condições modestas de nascimento (empobrecida 2 poções, comum 3, próspera 4, especial 3 poções e 2 ferros). Recompensas exploratórias integradas ao E, sem mudar a campanha base.
- `map_view.gd`, `exo_menu.gd`: mapa expandido e origem do jogador na página de mapa, marcos exploráveis, rota de ligação e loteamentos gerados.
- `qa094.gd`, `qa094_playable.gd`, `tools/check_094_static.py`: validações de dados, mundo real e preservação.

## Perfis de nascimento por sorteio

| Tipo | Probabilidade | Construções secundárias | Recursos iniciais |
|---|---:|---:|---|
| Empobrecida | 20% | 2 | 2 poções |
| Comum | 50% | 4 | 3 poções |
| Próspera | 25% | 7 | 4 poções |
| Especial | 5% | 5 | 3 poções, 2 fragmentos de ferro |

O arquétipo do protagonista, suas armas e o progresso da campanha não são restringidos pelo tipo de vila. Todos têm acesso ao contrato, descanso e meditação.

## Persistência

`world.landscape_version=1` fixa a versão do layout, separada de `world.generation_version=1` para os itens. Para mundos antigos o gerador cria uma geografia compatível com a seed já existente mantendo o corredor principal e suas coordenadas de missão. O mesmo algoritmo e seed reconstroem o mesmo cenário. Os marcos são recompensas com `world.events["loot/explore_*"].status="collected"`; a recompensa é o item gerado com `instance_id`, UID e propriedades persistentes já aceitas em 09.2. Ao recarregar, marcos já explorados não entregam novamente.

## Validação realizada aqui

**Executada:** `python tools/check_094_static.py` — 22 verificações estáticas passaram, inclusive 400 seeds comparadas por uma implementação independente do PRNG, presença das 4 categorias, JSONs e SHA-256 dos arquivos de corpo, animação, armas, criador aprovados. A amostra de 400 seeds apresentou 84 empobrecidas, 200 comuns, 91 prósperas, 25 especiais. O fluxo da entrada de seed foi revisado em código.

**Não executada:** compilação real GDScript ou startup Godot 4.6.2, jogo interativo, importação de GLB, visualização do terreno, frames, FPS ou testes Android. **O ambiente atual não possui o executável Godot.** Os scripts `qa094.gd` e `qa094_playable.gd` foram entregues para execução na engine, mas **não são resultado já aprovado**.

Os logs `logs-validacao` herdados são de entregas anteriores, **não** evidências da 09.4.

## Limites reais

Não há streaming infinito, biomas com clima próprio, lojas econômicas procedurais, cidades inteiras simuladas, missões procedurais completas, NPCs totalmente gerados ou multiplayer. Esta é a primeira região contínua procedural com vila variável, três arredores e marcos de exploração reais. A qualidade visual e possíveis ajustes de navegação ainda dependem de testes Godot.

## Teste recomendado

1. Faça backup do save em `user://journey.json`. Extraia em nova pasta.
2. Rode `godot --headless --path . --script res://qa094.gd` e `godot --headless --path . --script res://qa094_playable.gd`.
3. Na criação de personagem escolha uma seed, entre no mundo e abra Tab. Repita com seeds diferentes em **jornadas separadas**.
4. Visite uma região a oeste, a floresta a leste e as ruínas ao norte. Examine os três marcos com E; salve e carregue para testar recompensas únicas.
5. Confirme missão de patrulha, guilda, pousada, meditação, combate com armas e customização EXO preservados.

