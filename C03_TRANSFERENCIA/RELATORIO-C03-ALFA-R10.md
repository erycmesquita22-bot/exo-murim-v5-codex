# EXO-MURIM — Convergência 03 ALFA R10 — relatório técnico

**Origem obrigatória exclusiva:** `EXO-MURIM-CONVERGENCIA-03-ALFA-R9.zip` (SHA-256 `0d49f0c0430c4ccd552d30bc94fc823135fc35879fbd7b88ec1a6c954fe39236`) — verificado em bytes e por CRC. R9 preservada intacta. Não houve Convergência 04, merge de Terrain Forge nem migração forçada.

**Status da entrega: candidato de código NÃO HOMOLOGADO NA GODOT.** Não foi possível localizar Godot 4.6.2 no ambiente; a tentativa de acessar o release remoto falhou por DNS. Nenhum parser GDScript Godot, F5, cena renderizada, FPS, draw calls, física, teste nativo de persistência, ou captura real executado.

## Integração nova efetuada no código

1. `convergence/visual_actor_r10.gd`: ponte efetiva da aparência opcional Humanoides 03 R2 no ciclo **existente** de atores. Reutiliza Rig/Skin3D/Wardrobe/Arsenal sem spawn ou sistema de equipamento paralelo. Recebe UID real, papel social, facção e escola oficial; seleciona entre **15 presets / cinco cortes Murim / oito paletas canônicas ou neutra**, guardando apenas a seleção JSON `visual_r2`.
2. `convergence/resident.gd` e `convergence/game.gd`: residentes da Living World recebem roupas após a aplicação da aparência original e usam a seed real. O mesmo registro LivingWorld é reutilizado nas reentradas; snapshot de atores incorpora seleção visual. Despawn limpa nós cosméticos.
3. `murim_flow.gd`: jogador em jornada ativa recebe o visual R2 após `Wardrobe.apply`; a escolha é guardada em `journey.data.character.visual_r2`. **Não** adiciona roupas automaticamente a skins 64×64 PNG pessoais importadas; respeita a renderização literal original.
4. `enemy.gd`: o ator hostil oficial (`Enemy`) ganha sobreposição visual R2 sem segundo spawn, dano ou recompensa. Chefes com apresentação especializada são preservados. A cobertura individual dos oito IDs humanoides do Bestiário **não está provada nem plenamente conectada**, pois não existe um adaptador autoritativo de spawn de todos eles na base R9.
5. `exo_humanoids03_r2/scripts/murim_wardrobe.gd`: evita dupla roupa antiga/R2 escondendo *apenas* geometria original de vestuário (nunca UV de skin, equipamento Skin3D ou malhas de arma); restaura ao limpar; evita nós duplicados no mesmo frame e duplicação de bainha quando Arsenal já fornece a sua.
6. `rig.gd` e `arsenal.gd`: sincronizam estados **roll** e **two_handed** com visibilidade cosmética por transição, sem reconstrução de malhas por frame. Cotovelos, joelhos, anatomia e âncoras do rig original permanecem autoridades.
7. `journey_save.gd`, `living_world/state.gd`, `convergence/state.gd`: validam a seleção `visual_r2` e campos adicionais de energia mantendo saves pré-R10 opcionais/compatíveis.
8. `exo_core/integrations/humanoid_presets.gd`: passa a anunciar integração de ciclo de vida no host (não mais preview puro); Core continua registrando os 18 módulos da R9. `project.godot` contém feature flag `humanoids_enabled` e namespace isolado de saves QA R10.

## Correções R9

- **Navegação:** substituída a consulta degenerada `navigator.route(road,road)` por caminho do grafo de ruas entre a estação de moradia e ponto viário, com checagem de extremos, segmentos físicos e travessias de obstáculos. Não representa certificação de navmesh nem prova de que alguma escola está ocupada em seeds reais.
- **Qi/stamina:** dados numéricos da autoridade `techniques.mana/stamina` são copiados para `journey.convergence.r10_energy` no salvamento e restaurados no boot/reentrada procedural, se válidos. `exo_martial/module.gd` agora usa `core.world.save_progress()` no lugar da gravação direta `journey.write()` nas transações marciais, para que débito e recibo usem o mesmo host save. **Crash, recuperação `.bak`, idempotência e recurso insuficiente precisam de testes em Godot**.

## Evidência e limitações

- Base integral: 4538 arquivos inalterados e 14 arquivos originais modificados cirurgicamente; **zero arquivo original apagado**.
- QA R10: 32 verificações estáticas PASS, 0 FAIL; 390 documentos JSON lidos pelo parser Python; três referências de lógica Python (Marcial, Dungeon, Itens) PASS. **Nada disso compila GDScript ou testa gameplay.**
- GODOT / cenas, shader, física, clássica/slim em viewport, batalha, medalhas, interior, recarga de saves, 30 NPC/30 inimigos, profiler Vega 8: **NOT_RUN**.
- Nenhum recurso de imagem, GLB ou áudio novo. As 480 PNGs herdadas seguem em quarentena, sem declaração de liberação comercial.
- Não conclui todo o escopo de poses de armas e oito bestiários: requer QA visual/manual e correções direcionadas com screenshots reais.

**Próximo checkpoint:** somente partir do ZIP integral Alfa R10. Não reiniciar o merge nem importar Terrain Forge R6 sobre WorldGenesis R9/R10.
