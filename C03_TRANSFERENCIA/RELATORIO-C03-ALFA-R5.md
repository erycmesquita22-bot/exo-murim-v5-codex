# EXO-MURIM — CONVERGÊNCIA 03 ALFA R5 — NOVA INTEGRAÇÃO VISUAL

**Data:** 19/10/2026. **Base imutável:** `EXO-MURIM-CONVERGENCIA-03-ALFA-R4.zip` SHA-256 `08e2f49e6e9ed87cc08d1e25fc5d31808b17171fc3a3a282cc8a50f1efca28e6`.
**Estado:** código integrado em cópia da R4; candidato para QA real. **Godot 4.6.2 não executado** neste ambiente (nenhum binário disponível e sem rede). **Não homologado para comercialização.**

## Escopo efetivamente implementado nesta rodada

Nova integração **Creature Harmonização 02 → fauna regional do Bestiário 02**, já conectada ao gameplay na R4:

1. Criado `exo_creature_harmonizacao02/integration/runtime_visual_binding.gd`: monta o `PackedScene` recomendado, encontra o `AnimationPlayer`, usa clips `idle/walk/run/attack/hit`, preserva os pivôs de direção do ator existente e evita escala dupla (wrapper + tamanho da espécie). Ao trocar a apresentação, a geometria voxel procedural fica invisível mas recuperável.
2. `exo_bestiary/integration/regional_fauna_actor.gd`: consulta o serviço `creatures.visuals` do EXO Core **apenas depois de `configure()`**; chama o novo adaptador visual sem tocar nos contratos de dano/IA/recompensas. Atualiza locomoção e animações, com lock curto para ataque/hit, sem dano causado pela animação.
3. `exo_core/integrations/creature_visuals.gd` e `exo_core/modules.json`: versão do serviço `creatures.visuals` sobe a `1.1.0`; mantém o catálogo/proveniência como fonte e sinaliza ponte de apresentação ativa para a fauna regional. Os **17 módulos do Core permanecem**. Nenhum novo barramento/spawn/loot/inventário/save foi criado.
4. `project.godot`: namespace de saves específico R5; `exo_murim/r5/harmonized_creatures_enabled=true` como chave de opt-out. Desligando, a fauna R4 usa **somente** seu visual voxel anterior.
5. `qa_c03_r5_visual_runtime.gd` novo para Godot: checa cenas por espécie, animações, escala única, fallback e a ligação com o ator regional.

## Limites explícitos

- O catálogo oferece 17 identidades artísticas e 20 modelos GLB, mas **somente 13** IDs canônicos com modelos também constam do conjunto jogável do Bestiário 02. `wild_ox`, `wild_buffalo`, `qi_serpent` continuam com **fallback voxel**, sem substituir indevidamente suas aparências por espécies alheias. Outros quatro GLBs artísticos (`desert_monitor`, `desert_scorpion`, `demon_boar`, `kitsune`) **não criam novas criaturas/espécies** no jogo.
- A ponte só adiciona **visuais à fauna regional da R4**. Chefes, elites, humanoides e outras instâncias da fauna fora dessa ponte não são dados como integrados. A colisão física continua sendo a cápsula R4; o perfil de hitbox do GLB é **apenas descritivo**. Confirmar no F5 o encaixe e a altura dos pés de cada espécie.
- O GLB não é autoridade de ataque: o host verifica `can_hit`, alcance, esquiva e dano antes do efeito; visual serve para representar a ação. Clips de morte não são garantidos: o fluxo atual remove/oculta o ator assim que ocorre derrota; não foi refeito nesta rodada.
- O parser/editor da Godot precisa importar os GLBs. Se `ResourceLoader.exists`/`load` falhar, o ator preserva a visualização voxel antiga; não há promessa de FPS por análise estática.
- Direitos comerciais: `exo_creature_harmonizacao02/docs/PROVENIENCIA-COMERCIAL.md` atribui recursos às próprias entregas Creature Forge/Art. A titularidade final/cadeia comercial continua exigindo confirmação humana. Não liberar assets de terceiros ou skins em quarentena.

## Evidência de QA realmente executada

- **117 PASS / 0 FAIL** de checagens locais estáticas de código, preservação da R4, catálogo, integridade de 20 GLBs (`glTF`/`JSON`/malhas/animações), cenas, recursos, JSON e exclusividade da autoridade de gameplay.
- **9 NOT_RUN** para grupos Godot nativos; não reportar os 117 checks como compilação GDScript ou gameplay comprovado.
- Duas referências históricas de preload sem arquivo encontradas na árvore geral, fora do escopo R5, permanecem documentadas em `QA-C03-ALFA-R5.json`.
- ZIP integral verificado por CRC ao término do empacotamento; hashes sob `MANIFESTO-R5.json` e TXT externo.

## Bloqueios mantidos

- Dungeon: spawn/encounter/loot/saída/recovery e contrato Item R3 ainda precisam de integração e QA real.
- Forja: footprints reservados/materialização/rotas/interiores ainda não concluídos.
- Mestres: interface narrativa presente; provas trusted/Qi/stamina/técnicas ainda incompletas.
- Humanoides R2: visual runtime e direitos das skins legadas pendentes.
- Bestiário: fauna R4/R5 conectada no código, **não testada na Godot**; humanoides/elites/chefes não ativados nesta ponte.
- Regressões gerais: fluxo de criação, braços 8 direções, mapa TAB, NPCs, voo, missão das ruínas, saves, FPS Ryzen 3200GE/Vega8.

**Conclusão:** R5 executou **nova integração de runtime de apresentação** sobre a fauna da R4, sem reiniciar o merge. É checkpoint técnico completo e rastreável, não candidata estável do jogo.
