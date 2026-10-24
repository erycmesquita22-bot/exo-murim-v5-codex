# EXO-Murim — Vida da Vila 02

Aprimoramento incremental da Vida da Vila 01. A cena de entrada permanece `res://modules/village_npcs/VillageNPCs_V11.tscn`.

**Entregue:** 14 faces UV derivadas da arte V4, 14 pigmentos de cabelo, perfis jovens/adultos/idosos, três portes físicos e oito combinações de peças de cabelo utilizadas. As 29 pessoas recebem um perfil coerente com função/idade; os dois mestres deixam de ser visualmente idênticos. As texturas preservam olhos/traços ilustrados, atlas/UV e GLB originais. Os IDs, casas, rotas, vida e saves anteriores continuam iguais.

**Movimento:** nove novos loops (`LookAround`, `Stretch`, `Elder_Idle`, `Field_Work`, `Offer_Wares`, `Serve_Tea`, `Guard_Survey`, `Train_Form`, `Resident_Gesture`). São instalados somente os aplicáveis por pessoa, partindo da postura Idle V4 e com transição curta. `Cultivate` continua e foi corrigido para também partir dessa postura. Mestres em treino têm aura reforçada de acordo com o perfil.

**Interface:** Ji Wol, dois mestres, herborista e atendente recebem placa simples de nome/função/HP no mundo 3D; os moradores comuns mostram apenas o nome perto do jogador. A placa desaparece quando a câmera se aproxima demais para não cobrir a tela.

**Validação:** `qa/village_life_02/test_result.json` comprova 29 NPCs, 15 casas, 14 texturas de rosto carregadas, 14 cores de cabelo, amplitudes de altura de 0,26×, clipes de função, aura ativa em treino, placas instanciadas e continuidade do combate das feras. `import_final.log` não tem erro de importação/script. O ZIP completo e o patch aplicado sobre a Vida da Vila 01 foram reimportados e iniciados de diretórios limpos (`zip_import.log`, `zip_runtime.log`, `patch_import.log`, `patch_runtime.log`), também sem erro de script. As capturas `master_aged_aura_badge.png`, `master_silver_aura_badge.png`, `young_disciple_form.png`, `field_worker.png`, `ji_wol_badge.png` são renderizações reais do Godot Compatibility em 1280×800. O teste headless encerra com um aviso de recurso ainda referenciado, após completar as verificações; não apareceu erro em jogo. A captura em Mesa llvmpipe registrou 6–7 FPS, sem valor de benchmark para GPU.

**Preservação:** SHA-256 da GLB V4: `fc8af84dc28bd3c5e1a308df7a72efe702558824e924b52ac5d49ea75d11e557`. Nenhuma malha do personagem-base foi recriada. Nenhum asset externo novo entrou nesta atualização; as 14 faces são derivados pintados da textura entregue com o projeto.

**Pendente:** teste em Godot 4.7.2, medição com GPU e avaliação artística final das variações em movimento longo. A diferenciação corporal usa escala segura do rig existente; não substitui malhas de corpo ou vestimenta por modelos inteiramente distintos.
