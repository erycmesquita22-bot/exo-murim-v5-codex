# EXO-MURIM — EXO Visual 01 | Relatório técnico

**Status: candidato de integração para testes nativos; NÃO aprovado visual ou funcionalmente na Godot.**  
**Engine alvo:** Godot 4.6.2 Standard; Compatibility.  
**Base obrigatória:** `EXO-Murim-EXO-Core-01-CANDIDATO-CORRIGIDO.zip`.  
**Atualização adicional incorporada:** patch Fortificações 02 R2 oficial para preservar passagem fluvial mais recente.

## Resultado concreto de engenharia

O projeto Godot completo foi editado em cópia isolada. A `exo_core/modules.json` mantém os nove módulos originais e registra **visual 1.0.0** com `entrypoint` e serviço `exo_visual`. Nenhum domínio de persistência visual foi incluído no save raiz; o adaptador legado `graphics.gd` continua responsável por configurações de HUD e caminho `user://graphics.cfg`.

Há **33 arquivos criados/alterados pela camada EXO Visual**, **46 arquivos correspondentes somente à atualização Fortificações R2**, **3966 arquivos finais**, nenhum arquivo removido. O PATCH contém exatamente o diff necessário a partir do ZIP Core corrigido, incluindo o R2 oficial.

## Materiais e integração

- **Solo:** as texturas originais aprovadas `textures/terrain_approved/*.png` foram preservadas sem edição de conteúdo. Shader existente `genesis/terrain.gdshader` recebeu duas variáveis visuais; variantes nearest/mipmaps/linear usam o mesmo código de borda, UVs e máscaras. Metadados de importação de 9 texturas passaram a solicitar mipmaps.
- **Água:** `exo_visual/shaders/water.gdshader` conectado ao `genesis/region_scene.gd` lê `direction` do rio existente para animação e espuma estilizada. A malha e o fluxo da geração não foram alterados; materiais visuais independem das colisões e do EXO River Gate R2.
- **Capim:** shader de vento somente para capim decorativo MultiMesh, com base fixa. Densidade altera `visible_instance_count`, sem deletar colisores, árvores, animais ou NPCs.
- **Arquitetura:** o mesmo atlas de modelos da Forja 03 foi preservado; grupo visual dá controle de filtragem e sombras sem tocar encaixes arquitetônicos.
- **Personagens:** sombras opcionais dos rigs existentes; pós-imagem de esquiva é uma fotografia das malhas visíveis do rig e não clona scripts, controladores ou corpos de colisão.
- **Combate:** rastros básicos e partículas de impacto se conectam ao ataque real e respeitam desativação. Cálculo de dano, alcance, consumo e cooldown não foram alterados.
- **Iluminação:** exposição, cores, SSAO no backend com suporte, névoa, Glow, sombras ajustáveis e perfil diurno/noturno derivado do relógio já persistido. Não é gerado outro relógio nem novas seeds.
- **Configurações:** presets Mínimo, Baixo, Médio, Alto, Ultra e Personalizado; **27 controles individuais** no menu já existente. Exclusivos de Forward+ ficam desativados no Compatibility. Troca de renderizador em tempo real NÃO foi implementada.
- **Diagnóstico:** serviço expõe monitores nativos de FPS, quadro, memória, objetos e draw calls; benchmarks e capturas têm scripts reais, sem métricas inventadas.

## Limitações concretas

- Sem executável Godot disponível nesta sessão. Não foi possível validar parse/compilação nativa do GDScript, dos shaders, startup ou render do piloto. Não há screenshots novas.
- Mistura de transições foi refinada no shader existente; **não há solução completa de triplanar para declives**, nem sistema geral de decals/partículas dinâmicas em todas as habilidades.
- A água ainda não implementa profundidade geométrica real nem espuma derivada de cada margem. As faixas da superfície são estilizadas; qualidade artística depende de capturas reais.
- Vento do capim e sombramento da arquitetura têm pontos de integração explícitos. Não foi incluído balançar individual de cada GLB arbóreo, para evitar deformar troncos sem pesos dedicados.
- SSAO no Compatibility 4.6 é uma implementação reduzida; SSR e SSIL são gated para Forward+ e precisam de testes de renderer.
- Os perfis podem ser alternados no código, mas **não foram testados em tela real**; eventuais erros de parse, propriedade, shader ou importação devem ser tratados no Work antes de aprovação.

## QA e preservação

Executadas **23 verificações estáticas PASS, 0 FAIL**. Outros **19 gates nativos/humanos marcados NOT_RUN**. Ver `RESULTADOS-QA-EXO-VISUAL-01.json`, `exo_visual/docs/ROTEIRO-WORK-QA-01.md` e scripts em `exo_visual/tests/`.

Hashes individuais antes/depois e a separação de arquivos R2 versus Visual estão no manifesto. O inventário contém **1241 recursos visuais**, lista duplicatas idênticas e **não inventa evidência de utilização em runtime** quando o caminho é construído dinamicamente.

## Arquivos de implementação visual

- combat/player_combat.gd
- convergence/game.gd
- encounters.gd
- exo_core/modules.json
- exo_visual/afterimage.gd
- exo_visual/driver.gd
- exo_visual/module.gd
- exo_visual/shaders/grass_wind.gdshader
- exo_visual/shaders/terrain_linear.gdshader
- exo_visual/shaders/terrain_pixel.gdshader
- exo_visual/shaders/terrain_pixel_mips.gdshader
- exo_visual/shaders/water.gdshader
- exo_visual/spec.gd
- exo_visual/tests/benchmark_visual.gd
- exo_visual/tests/capture_pilot.gd
- exo_visual/tests/qa_visual.gd
- genesis/region_scene.gd
- genesis/terrain.gdshader
- graphics.gd
- techniques.gd
- textures/terrain_approved/grama_folhas_largas.png.import
- textures/terrain_approved/grama_montanha.png.import
- textures/terrain_approved/grama_prado.png.import
- textures/terrain_approved/grama_seca.png.import
- textures/terrain_approved/grama_umida.png.import
- textures/terrain_approved/rocha_cinza.png.import
- textures/terrain_approved/solo_bambuzal.png.import
- textures/terrain_approved/solo_floresta.png.import
- textures/terrain_approved/trilha_terra.png.import
- ui/pages/settings.gd
