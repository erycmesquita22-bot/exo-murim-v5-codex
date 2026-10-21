# EXO-MURIM — CONVERGÊNCIA 03 ALFA R4 — ATIVAÇÃO DO BESTIÁRIO 02

**Data:** 19/10/2026. **Base imutável:** `EXO-MURIM-CONVERGENCIA-03-ALFA-R3.zip` (SHA-256 `f96f5104bcdf69b19ec26c8eb8f59eaf19d1096c43922d39943f4a23928283b7`).
**Status:** CANDIDATO DE CÓDIGO, NÃO HOMOLOGADO. Godot 4.6.2 NOT_RUN.

## Escopo realizado

A R4 trabalha diretamente sobre a árvore integral da R3 sem refazer o merge. **Um sistema recebeu uma ponte real de gameplay em código: fauna do Bestiário 02.** Não altera a fonte do WorldGenesis nem cria outro gerador, salvamento, inventário, ecologia ou dono de combate.

### Arquitetura funcional implementada (requer teste real)

- `exo_bestiary/module/entrypoint.gd` publica serviço `bestiary.combat` com ataque validado pelo catálogo; EXO Core registra o serviço, mantendo 17 módulos e ownership. Não força inicialização caso Bestiário opcional falhe.
- `regional_ecology/territories.gd` deriva de seed+região 0 a 2 locais de fauna estáveis, respeitando bioma, estradas, rios, declives e lotes. IDs `eco/rXX/fXX` convivem com territórios hostis `eco/rXX/tXX`. Não modifica geração dos 88 mapas.
- `regional_ecology/director.gd`, o dono já existente do spawn/registros geracionais/expurgo, consulta o catálogo e adiciona fauna ao **mesmo** orçamento global de **oito inimigos ativos**. Nascentes não visíveis e entre 19 e 85 m, conforme lógica preexistente. Não há segundo diretor.
- `exo_bestiary/integration/regional_fauna_actor.gd`: ponte física que herda `CreatureActor` voxel do Bestiário, mantém IA/locomoção, adapta HP/UID/`hurt`/`step` à interface do combate existente. Player target, HUD e ataque passam por alcance/linha de visão e `world.damage_player` com esquiva/defesa/escudo do jogo. Animais de presa fogem; predadores/territoriais reagem.
- `regional_ecology/rewards.gd` escolhe `hide`/`fang` para drops de fauna, registrados sob a autoridade de `inventory.gd`. A morte utiliza **`convergence/game.gd::enemy_defeated`**, `WorldState.mark_pending`, `Reward.territory_state` e `JourneySave` existentes; geração por território controla repetição. **Ambas** as rotas de rollback restauram o ator físico caso um commit não se conclua.
- `project.godot` tem `exo_murim/r4/fauna_enabled=true` para testar a ativação e desativar com segurança, além de namespace de saves QA R4 isolado.
- **Arte:** fauna usa geometria voxel procedural própria do módulo Bestiário, sem introduzir arquivos de terceiros. GLBs do Creature Harmonização ainda são previews, não foram acoplados nesta rodada.

## QA executado

- **41 PASS / 0 FAIL** em auditoria estática local: hash base, contratos do Core, uniqueness de serviços, preservação de R3, catálogo, spawn determinístico na fonte, limites de população, comportamento, combate, loot, rollback, JSON e integridade de caminhos literais.
- **8 grupos NOT_RUN**: Godot 4.6.2 não disponível aqui, compilação de GDScript, render/física, spawn real, combate, dano, morte, salvamento/reopen e FPS não foram executados. Isso **não prova** que fauna já funciona em execução.
- `res://exo_bestiary/tests/qa_c03_r4_regional_fauna.gd` foi criado para ser executado NATIVE; checa seed e geração das 88 regiões, exclusões e itens. Não confundir existência do teste com sua execução.

## Bloqueios / escopo ainda não concluído

1. Bestiário: nenhum teste real de câmera, performance, ecologia no gameplay ou respawn temporal. 16 perfis disponíveis, mas certos biomas/espécies raras não têm ambiente equivalente mapeado; não declarar todas as espécies materializadas. Humanoides/elites/chefes ainda não entram por esta ponte.
2. Dungeon: host/combat/pickup e transição real não homologados; prova atômica loot ainda pendente.
3. Itens R3: preview e estágio atômico gated; não está totalmente ativo.
4. Forja Monumental: reserva/materialização de grandes complexos ainda não realizada.
5. Mestres: proof de admissão, treino, Qi, stamina e técnicas não integrado.
6. Harmonização de Criaturas e Humanoides R2: GLB/rig runtime ainda não ligado; skins legadas 480 PNGs permanecem em quarentena comercial.
7. Performance/Vega8, pacote comercial, mapa TAB, armas/poses e regressões abrangentes pendentes.

## Próximo ciclo sem reiniciar merge

1. Copiar o ZIP R4 em novo diretório com namespace de QA. Revalidar SHA-256 e abrir com **Godot 4.6.2 Standard Compatibility**.
2. Importar no editor `--headless --editor --path $ROOT --import --rendering-method gl_compatibility`. Procurar erros GDScript e corrigir antes do gameplay.
3. Executar teste nativo `--headless --path $ROOT --script res://exo_bestiary/tests/qa_c03_r4_regional_fauna.gd` e o QA R3 do Core.
4. F5 em seeds 101 e outras três: floresta, campo, vale, montanha, regiões de ruínas; confirmar animals fora de vista, colisão, animação, reação, ataque, hitbox, loot E, salvar/reabrir, respawn sem duplicação e regressão dos inimigos humanos.
5. Testar inventário 23/24 slots, pendência cheia, falha de publicação do evento, falha de escrita, rollback físico, desconexão e retomada. Comparar FPS com R3 no mesmo hardware/seed/câmera.
6. Somente depois promover Bestiário para aprovado; manter R3 ZIP e save do checkpoint intactos.

**Conclusão:** R4 implementa no código a ligação de fauna do Bestiário com ecologia/combate/inventário/saves existentes. **NÃO declara implementação integral de Bestiário (humanoides/elites/chefes) nem QA nativo.**
