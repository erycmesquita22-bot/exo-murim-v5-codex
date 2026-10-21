# EXO-Murim 09.4.5 — Level design e caminhos conectados

## Base e objetivo

Base: ZIP **09.4.4 — Solo da Aventura**. Alterações concentradas no mundo, composição de vilas, trilhas e QA. Esta versão é uma **candidata para testes**, não está aprovada visualmente ou em execução na Godot.

## Mudanças implementadas

- `world/level_design.gd` (novo): superfície de ruas contínua sob as pedras; praça central com pavimentação; conexão de caminhos com **cada** edifício do layout V2; demarcação de lotes e superfícies com variação leve; áreas de cultivo, pequenos mercados, bosques e zonas de descanso em lotes vagos; itens culturais próximos à Guilda, pousada e treino; diferenças de cenografia entre vilas empobrecidas, comuns, prósperas e especiais.
- `world/village_v2.gd`: substituição do sistema antigo de pintar pedras desconectadas pela composição de level design. Guilda, pousada, treino e casas seguem exatamente os locais do plano procedimental; serviços e missões continuam consultando os mesmos anchors. Decoração não cria paredes físicas nem bloqueia corredores.
- `world/landscape.gd`: três trilhas externas agora seguem a **superfície real triangulada** do terreno e geram colisor para apoiar os passos; rota do bambuzal, das montanhas e das ruínas; cenas de chegada com vegetação, afloramentos de pedra e vestígios do Panteão. Não há streaming, navegação inteligente ou biomas novos nesta entrega.
- `region.gd`: reinicia o indicador do módulo de level design ao reconstruir a região.
- `qa0945.gd` (novo): testes Godot de 160 seeds, âncoras da vila, trilhas, seus colisores, altura do chão e movimento por WASD numa instância real do jogo.

## Compatibilidade

- O esquema **landscape_version=2** foi preservado; nenhum layout de construção, âncora de missão, item ou save foi mudado. Vilas V2 de partidas existentes recebem a nova **apresentação visual**, mas preservam seu desenho salvo. Layout legado V1 permanece disponível.
- As posições da Guilda, pousada, meditação, NPC e ponto de nascimento são preservadas.
- Personagens, personalização, armas, combate, áudio, habilidades, inventário e loot não foram modificados.
- As melhorias de solo não corrigem por si sós bugs de animação ou estados travados fora das trilhas. Necessária validação real.

## Validação realizada nesta entrega

- Inspeção de código e referências a recursos, caminhos GDScript, JSONs e integridade do ZIP.
- Comparação hash dos scripts congelados (rig, guarda-roupa, arsenal, combate, inventário, save, missões e áudio) com a versão base.
- Inspeção das regras de pavimentação, coordenadas dos lotes e direção das faces trianguladas das novas trilhas.
- **Não executado:** testes e importação no editor Godot, colisões físicas em runtime, avaliação visual ou medição de FPS em PC/Android. Nenhuma alegação de aprovação visual.

## Roteiro de teste humano prioritário

1. Abrir nova jornada com seeds `101` e `202` e observar diferença de arranjo, praças, acessos, terrenos cultivados e fundos dos edifícios.
2. Abrir um save V2 anterior: conferir que a Guilda, pousada e missões continuam nos mesmos pontos, porém com ruas redesenhadas.
3. Testar WASD e rolagem na praça, na frente de cada serviço e nas três saídas de bioma; conferir se não afunda nem atravessa o chão.
4. Percorrer caminho do bambuzal, passagem das montanhas e ruínas, verificando inclinações, colisão, pedras flutuantes e alcance dos marcos de exploração.
5. Conferir performance em médio/baixo, especialmente em aldeia próspera.
6. Executar `godot --headless --path . --script res://qa0945.gd` e enviar o primeiro erro vermelho se falhar.

## Não implementado neste recorte

Não houve reconstrução de interiores, comércio ou economia, NPCs procedurais completos, novas missões, navegação por IA, diferentes modelos de telhados ou correção da física fora das áreas tratadas. A expansão de quantidade de construções por perfil também não mudou.
