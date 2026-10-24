# EXO-MURIM — HWA-02 HANEUL — SPRINT 02 · ARQUITETURA BASE

Versão de ambiente: **V0.6** | Engine testada: **Godot 4.7.2 Stable / Compatibility** | Estado: **implementado e testado funcionalmente na Godot; arte sujeita à aprovação**.

## Missão e limites

Atualizar somente as construções da vila, sem reestruturar o Sprint 1 do terreno e sem modificar o rig, as 15 animações, a câmera ou o controlador do personagem V3. Testes e arquivos Android não foram solicitados.

## O que foi substituído

- Casas e solar antigos retirados completamente do GLB ativo de natureza: `model/HWA02_Nature_And_TerrainCollision_S02.glb` não contém `Houses`, `Main_Family_Estate` nem `Roads`.
- Arquitetura ativa: `architecture_sprint02/HWA02_Architecture_Sprint02.glb` com **15 construções em seus lotes originais e 2 elementos do solar** (muro/cerca e portão).
- As partes antigas da arquitetura não são desenhadas nem usadas como colisão. O terreno pintado do Sprint 1 permanece, e sua colisão continua vindo da malha de terreno original invisível.
- Não há alteração física da geografia, do rio nem da distribuição dos pontos de interesse.

## Assets originais Sprint 02

**Kit de 8 peças em GLB:** HOUSE_RURAL, HOUSE_FISHERMAN, TEAHOUSE, HEALER_CLINIC, STOREHOUSE, MANOR_HALL, SHRINE, COURTYARD_GATE.

**Textura:** `architecture_sprint02/textures/EXO_Murim_Architecture_InkAtlas_1536.png`. Atlas em 1536 × 1536 px. Contém 31 paletas/áreas ilustradas: cinco rebocos, madeiras, telhas, papel das janelas, pedra, bronze e sinais ornamentais originais.

A forma dos edifícios segue uma linguagem de casas chinesas rurais estilizadas para EXO-Murim: madeira aparente, fachadas rebocadas, telhas cinzentas com contornos e beirais em espessura real. O projeto não usa malhas ou texturas copiadas de terceiros. A autoria das partes pré-existentes do jogo e sua auditoria comercial continuam responsabilidade geral do projeto.

**Telhados não flutuantes:** superfície superior e inferior têm volume, empenas fecham o encontro do telhado com a fachada e peças de madeira ligam beirais, vergas e pilares. Cada modelo foi renderizado individualmente e dentro da Godot. Os interiores completos ainda NÃO foram modelados.

## Abrir

1. Extraia este pacote completo em **pasta nova** (não faça merge da V0.5).
2. Abra `project.godot` na Godot 4.7.2 Stable, selecionando renderização Compatibility.
3. F5 abre a vila com o Character Motion V3 preservado.
4. Abra `godot/HWA02_Haneul_Inspection.tscn` para explorar a arquitetura sem personagem (mouse direito: câmera, WASD: mover, scroll: zoom, teclas 1/2: famílias).
5. Os GLBs originais e o script reprodutível estão dentro de `architecture_sprint02/` e `source/`.

## Testes existentes nesta entrega

- Importação limpa da Godot 4.7.2: `qa/sprint02/04_fresh_import.log` — importação completada.
- QA nativo da Godot: `qa/sprint02/06_architecture_runtime_QA.log` — WONG/WUDONG; 17 grupos de geometria; 19 grupos de colisões totais; ausência de arquiteturas antigas na cena; 15 animações / 25 ossos, personagem apoiado no piso. 0 falhas.
- Execução da cena principal: `qa/sprint02/08_main_scene_boot.log` — concluída, sem erros de script registrados.
- Renderização OpenGL/Mesa llvmpipe: `qa/sprint02/07_graphical_fresh_capture.log` e `architecture_sprint02/previews/0[1-4]*godot*.png`.
- Teste de movimento original `qa/sprint02/02_regression_motion.log` completou antes da limpeza de ativos; execução mais longa `qa/sprint02/05_fresh_motion_regression.log` foi interrompida por timeout durante a segunda variante — não contar como segundo PASS final. A verificação final de movimento completo é uma pendência, separada do QA de arquitetura.

## Não homologado ainda

- Aprovação estética humana das edificações, todos os interiores, teste manual de colisões em todas as portas e passagens, inventário de todas as possibilidades de modificação das casas, desempenho real em PC de referência.
- As paredes/portas são fachadas fechadas, não possuem sistema para entrar nas casas. Isso pertence aos futuros interiores.
- As fontes de iluminação/fog atuais são provisórias. O terreno mantém imperfeições próprias do Sprint 1; esta entrega NÃO promete resolvê-las.

**Estado:** arquitetura implementada, importada e capturada na Godot; requer aprovação estética antes do Sprint 3.
