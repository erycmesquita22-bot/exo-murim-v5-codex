# R10 — Wardrobe / Humanoides 03 R2

O adaptador `convergence/visual_actor_r10.gd` não gera atores. Em `Resident.setup` e `Flow.apply_character`, executa depois do Wardrobe + Skin3D oficiais; no `Enemy.setup`, após Skin3D, apenas para hostis não-chefes.

As seleções são determinísticas por seed, UID, papel e paleta. Para mestre do `exo_martial.school.mosteiro_jade` uma associação de escola oficial válida seleciona a paleta Jade. Para facção desconhecida, o catálogo neutro é usado; nenhum campo de facção Narrativo é reescrito.

**Cobertura de catálogo:** 15 presets, cinco roupas `short_split/sect_split/master_formal/trader_layers/guard_tunic`, 8 paletas presentes e três tonalidades em catálogo. Isso não equivale a teste de todas as combinações no jogo.

A sobreposição oculta a geometria 3D das roupas EXO originais, mas preserva o atlas base, UV, outer layer real, Skin3D e armadura do sistema oficial. Remove os nós do frame anterior da árvore imediatamente antes de enfileirar sua liberação. Esta solução requer QA visual de rolagem e queda e avaliação de orçamento de draw calls.

**Limitação:** eight Bestiário humanoid IDs still require an actual spawn/actor pipeline. R10 does not fabricate 8 entities to claim coverage.
