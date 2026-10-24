# EXO-MURIM — HANEUL V0.7 — SPRINT 03 • PROPS E VEGETAÇÃO

**Escopo:** apenas adereços e vegetação da HWA-02. **Base:** Haneul V0.6 Sprint 2 completa, extraída/copied sem merge incremental de mods. Engine testada: **Godot 4.7.2 Stable, GL Compatibility**. Android fica fora do escopo conforme decisão do projeto.

## Entrega real

- **20 modelos GLB originais** em `props_sprint03/kit/`, incluindo poço, poste com lanterna, lanterna de pedra, barril, caixote, cesto de arroz, carroça, banca de comércio, banco, cerca, placa, bandeira, bambu, pinheiro, arbusto, capim, juncos, pedras, flores e ponte pedonal pequena.
- **263 instâncias físicas/visuais** no cenário, especificadas em `props_sprint03/manifest_sprint03.json`, com posições, altura local do terreno, rotação e escala reproduzíveis. A ponte pequena é um kit independente, não foi colocada no rio sem uma travessia física definida.
- **42 instâncias de props sólidos com colisão** individual. Vegetação baixa e folhas são decorativas e não geram centenas de colisores desnecessários.
- **49.434 triângulos adicionais** no GLB da vila; número inclui vegetação decorativa. A otimização de lotes de draw calls e vegetação dinâmica pertence a etapa posterior; não afirmamos metas de FPS.
- **Atlas de materiais próprio** (`EXO_Murim_Props_HandPainted_1536.png`, 1536×1280) com texturas pintadas programaticamente, variação discreta de madeira, pedra, tecido, folhas, bambu, papel e metais.
- Novo GLB da vila `props_sprint03/HWA02_Props_Vegetation_S03.glb`, importado adicionalmente à cena existente. *Não modifica o GLB do terreno, da arquitetura nem o GLB do personagem*.

## Arquitetura das cenas

- `godot/HWA02_Haneul_Inspection.tscn`: adiciona `PropsSprint03` para avaliação do ambiente sem personagem.
- `godot/HWA02_Motion_V3.gd`: adiciona `EXO_Sprint03_Props_Vegetation` na criação do mundo e colisões apenas nas malhas `PROP_COLLIDE_*`. O controlador V3 herdado permanece intacto.
- `data/HWA02_manifest.json`: permanece com os mesmos lotes e marcos físicos. `props_sprint03/manifest_sprint03.json` contém a nova camada de props, que pode ser desligada/substituída integralmente.
- `source/build_props_sprint03.py`: regenera todos os materiais, modelos e a distribuição com seed fixa. Instalar versões futuras significa **remover a pasta inteira `props_sprint03/` e substituir a versão**, não sobrescrever parcialmente seus GLBs.

## Testes reais executados na Godot 4.7.2

1. `qa/sprint03/01_import_godot.log`: importação concluída em modo editor headless.
2. `qa/sprint03/02_runtime_qa.log`: duas variantes familiares; 263 malhas, 42 props com colisão, total de 61 grupos de colisão (42 Sprint 3 + 17 arquitetura + 2 natureza), rig com 25 ossos, 15 animações, personagem sobre o piso. **0 falhas**.
3. `qa/sprint03/03_graphical_capture.log`: 6 imagens salvas pelo **renderizador real da Godot / OpenGL Compatibility (Mesa llvmpipe)**; ver `props_sprint03/previews/`.
4. `qa/sprint03/04_motion_regression.log`: caminhada, corrida, sacar/guardar espada, combo de 2 golpes, esquiva e reação ao dano verificados nas variantes Wong e Wudong. **0 falhas do script de regressão**.
5. `qa/sprint03/05_placement_check.json`: validação offline das posições de props sólidos versus footprints existentes dos 15 edifícios (nenhum dentro de lotes construídos + margem de 1,2 m). Isso não substitui um passeio humano pela vila.

## Limites e pendências

- **Não homologado artisticamente** até avaliação do usuário. Capturas da Godot são prova de renderização, não garantia de acabamento final.
- **A textura repetitiva em ondas/conchas do chão** permanece herdada do Sprint 1, visível em certas vistas amplas. Não está sendo apresentada como corrigida no Sprint 3.
- **A velocidade visual de corrida em relação à caminhada** não foi alterada (fora do escopo). O teste de regressão prova que ambas ocorrem, não que o balanceamento está aprovado.
- Ponte pequena disponível apenas como GLB de kit. As margens do rio, a altura da água e o encontro de colisões precisam ser definidos antes de implantá-la.
- Colisores das props maiores são gerados a partir das malhas para QA. Uma otimização futura deve separar os colliders funcionais simplificados para economizar custo físico.
- **Interatividade** (acender lanternas, comprar em bancas, coletar cestos, usar o poço, ocupar a carroça, vento em plantas) **não foi implementada**; Sprint 3 é arte e colocação ambiental.
- Não há benchmark de Android, nem teste humano explorando todas as portas, nem homologação das demais regiões do Atlas.
- Materiais/props novos desta entrega são originais (construídos pelo script incluso). Proveniência de toda a base herdada, inclusive Character Core V3, exige auditoria comercial própria antes de lançar o jogo.

## Como executar

1. Extraia o ZIP integral da V0.7 numa pasta nova. **Não copie por cima da V0.6**.
2. Importe `project.godot` na **Godot 4.7.2 Stable** (renderização Compatibility).
3. F5 inicia Haneul com Character Core V3; abra `godot/HWA02_Haneul_Inspection.tscn` para avaliar a vila sem personagem (teclas 1/2 alternam a família, 0 volta à seed; mouse direito gira a câmera).
4. Para confirmar o QA em Linux: `godot --headless --path . --script res://qa/sprint03/validate_props.gd`.

**Estado:** `IMPLEMENTADO + TESTADO AUTOMATICAMENTE EM GODOT`, não `HOMOLOGADO` para arte/gameplay final.
