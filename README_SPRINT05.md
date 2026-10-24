# EXO-Murim — Haneul V0.9 / Sprint 05 — Infraestrutura física

**Base:** Haneul V0.8 do Sprint 4, sem copiar arquivos por cima de uma instalação anterior. Projeto integral para Godot 4.7.2 Compatibility. As versões anteriores NÃO devem ser mescladas na pasta do jogo.

## Alterações reais nesta entrega

- **Travessia do Rio Hwa:** nova ponte de madeira (37 m de comprimento, 3,1 m de largura), rampas junto ao chão existente, guarda-corpos e pilares apoiados no canal. Tablado possui colisão real.
- **Margens e portos:** proteção de pedra, duas plataformas de embarque; ainda não há sistema de barco, navegação ou viagem de região.
- **Rostos do solo e acessos:** 15 soleiras leves e pintadas alinhadas às portas; o terreno mantém EXATAMENTE os vértices, faces e alturas do Sprint 4, com acabamento difuso revisado para criar aproximações ao novo tabuleiro.
- **Rio Hwa:** nova malha de água fina acompanhando o canal real, texturizada com material ilustrado de UV contínua; elimina as triangulações serrilhadas que eram visíveis no mapa V0.8. Este é um material estático, não o módulo futuro de climas.
- **Âncoras de interiores:** 15 `Area3D` com IDs estáveis, criadas nos acessos. Não há teleporte; a fachada permanece fechada e os interiores ainda não foram produzidos.
- **Separação de sistemas:** arquitetura Sprint 02, props Sprint 03, Wong/Wudong, Character Core V3 intactos; cenas anteriores de terreno e rio ficam ocultas. Não há scripts de NPC ou combate adicionais.

## Arquivos essenciais

- `project.godot` — execução inicial com personagem V3, Godot 4.7.2
- `godot/HWA02_Haneul_Inspection.tscn` — cena de inspeção visual sem personagem
- `infrastructure_sprint05/HWA02_Infraestrutura_S05.glb` — ponte e pisos
- `infrastructure_sprint05/HWA02_River_S05.glb` — rio estático corrigido
- `infrastructure_sprint05/HWA02_Terrain_S05.glb` — terreno apenas com nova textura
- `infrastructure_sprint05/EXO_Haneul_Infrastructure_PaintedAtlas_1024.png`
- `infrastructure_sprint05/EXO_Rio_Hwa_Watercolor_1024.png`
- `infrastructure_sprint05/data/HWA02_Routes_And_Entrances_S05.json`
- `infrastructure_sprint05/previews/` — imagens reais da engine e planta técnica.

## QA feito na Godot 4.7.2

1. Importação completa do projeto — executada.
2. 15 âncoras de interiores e quatro malhas de colisão — verificadas em runtime nas duas famílias.
3. 11 raios físicos ao longo do tablado em cada variante — 11/11 atingiram a superfície da ponte.
4. Corpo de teste em cápsula atravessou de x=57,3 a x=93,7 (152 passos), sem contatos laterais bloqueantes.
5. Regressão `qa/smoke_v04.gd` — passou nos dois perfis familiares, preservando as 15 animações V3.
6. Quatro capturas reais da Godot via Xvfb/OpenGL Compatibility.

**Limitações explícitas:** não foi feita inspeção manual completa por uma pessoa; NÃO há interiores, NPCs, travessia de balsa funcional, sistema de portais, navmesh, clima, nem testes no Android. Persistem avisos não bloqueantes do AnimationTree V3, herdados da versão anterior. Casas continuam visualmente fechadas; as âncoras apenas identificam futuras entradas.

## Como abrir

Extraia o projeto ZIP em **pasta vazia**. Use Godot 4.7.2 Standard, projeto `project.godot`, F5. Para vistoriar o mapa sem personagem, abra `godot/HWA02_Haneul_Inspection.tscn` e F6. Não misture arquivos da V0.8 com a V0.9.

## Proveniência

As novas malhas, atlas e texturas S05 foram gerados originalmente neste projeto, sem bibliotecas comerciais, modelos externos ou conteúdo copiado. Mantenha os arquivos fonte para auditoria.
