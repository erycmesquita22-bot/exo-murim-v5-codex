# EXO Skin 3D Hybrid 01 — módulo implementado, validação pendente na Godot

**Alvo:** EXO-Murim Mundo Vivo 02 R2, Godot 4.6.2 Standard, Compatibility (OpenGL 3).
**Status:** Implementação candidata. Auditoria offline aprovada. NÃO foi executada nesta entrega com a engine; precisa do Work ou Godot local para validação funcional.

## Arquitetura (sem substituir o rig)

- `uv_layout.gd`: seis faces por parte, atlas Minecraft 64×64 e EXO 256×256, classic e slim, metade superior/inferior dos membros.
- `skin_importer.gd`: valida PNG 64×64 e copia **bytes inalterados**, guardando o arquivo em `user://exo_skins/skin_<md5>.png`.
- `overlay_builder.gd`: 1 shell para cabeça e tronco, 2 shells para cada braço/perna, transparência ALPHA_SCISSOR com nearest-filter, culling desligado, respeitando os pivôs Minecraft.
- `appearance_adapter.gd`: integra o sistema a qualquer `Rig`, troca APENAS os meshes básicos dos braços no modo slim; restaura os meshes clássicos originais ao retornar. Cotovelos, joelhos, sockets e hierarquia original são mantidos. Associa aparência procedural estável de NPCs e adversários.
- `attachment_slots.gd`: 12 slots semânticos e peças modulares voxel isoladas dos stats, hitboxes e armas.
- `equipment_visuals.gd`: equipamentos visuais independentes com ocultação seletiva das camadas correspondentes. Não modifica inventário.
- `skin_preview.gd`: aplica alterações no mesmo Rig usado no jogo e oferece poses de demonstração.
- `profile_codec.gd`: normalização, whitelist e validação do `skin3d` cosmético opcional.

## Pontos de integração no projeto

`wardrobe.gd` chama o adaptador nos três caminhos de saída existentes (skin importada, cabelo raspado, aparência EXO normal), após Arsenal/Anatomy. `ui/character_creation.gd` permite escolher classic/slim, ligar/desligar as seis layers, escolher acessórios e armaduras COSMÉTICAS e importar PNGs sem recompressão. `journey_save.gd` valida a extensão opcional, sem alterar o `version:4`. Novas identidades em `living_world/people.gd` carregam cosméticos determinísticos por seed, ocupação, facção e id. `convergence/resident.gd` preserva NPCs antigos sem o bloco. `enemy.gd` aplica recursos visuais em chefes sem substituição de BossArt. `murim_flow.gd` personaliza os demais inimigos.

A expansão é intencionalmente **cosmética**. Se houver conflito, efeitos de equipamento, dano, progressão, IA, save mundo e funcionamento do combate continuam de responsabilidade do código aprovado existente.

## Teste real exigido (Godot Work)

1. Faça uma cópia do projeto e extraia `EXO-Skin3D-Hybrid-01-PROJETO.zip` (ou aplique `EXO-Skin3D-Hybrid-01-PATCH.zip` à base R2 exata).
2. Confirme que é o **Godot 4.6.2 Standard**, rendering method **gl_compatibility**.
3. Execute uma importação do projeto no editor e registre integralmente erros de parse e import.
4. Execute `godot --headless --path <PROJETO> --script res://exo_skin3d/qa_skin3d.gd`; em uma máquina com ambiente gráfico, execute também usando display OpenGL Compatibility; quando disponível, `xvfb-run -a godot --path <PROJETO> --rendering-method gl_compatibility --script res://exo_skin3d/qa_skin3d.gd`.
5. Inspecione `user://exo_skin3d_qa/result.json` e **sete PNGs capturados da viewport real**. Compare `00_baseline_sem_overlay.png` com `01_classic_front.png`, depois as vistas frontal, lateral, traseira e poses em classic/slim. Imagens pretas, duplicadas, incompatíveis ou com UV erradas invalidam a etapa.
6. Faça QA manual dos menus e de PNGs externos 64×64 com alpha e classic/slim. Alterne layers durante a preview sem quebrar o socket da arma. Teste 256×256 EXO.
7. Execute a suíte de combate e regressão da base: técnicas, knockback, rolagem, armas, animações, acertar/ser atingido, matar inimigos, ganhar XP, loot, redução de XP, save/fechar/reabrir, persistência de mortes e renovação; compare com a R2 antes da modificação.
8. Teste pelo menos 30 moradores ativos e 30 inimigos, com repetição de 75 aplicações cosméticas, load/unload regional e movimento de cotovelos/joelhos. Compare picos de memória, FPS, draw calls, material count, triângulos e 1% low com a R2. Sem benchmarks, NÃO aprovar desempenho.
9. Use races com orelhas/caudas, roupa Murim, longas mangas, cortes de cabelo e armaduras que ocultem overlays.
10. Não sobrescreva saves reais do jogador: execute `qa_skin3d.gd` em uma cópia com diretório de usuário separado e use save isolado de QA.

## Critérios / condições de bloqueio

- Falha de parse Godot, mesh sem UV, alpha que produz buracos indevidos, animação de articulações desalinhada, PNG alterado, dados `skin3d` perdidos ou save legado rejeitado: **bloquear**.
- Regressão dos sistemas de combate, armas, NPCs, IA ou FPS abaixo do critério aceito pelo projeto: **bloquear**.
- A aprovação do teste offline não representa aprovação da engine. Não enviar capturas gráficas sintéticas como se fossem evidência do runtime.

## Testes disponíveis

- Offline: `python exo_skin3d/qa/offline_checks.py` — auditoria estrutural/UV, 30 mil casos determinísticos, PNGs 64/256, hashes do código aprovado; gera JSON.
- Godot: `exo_skin3d/qa_skin3d.gd` — UVs, importação, transparência, classic/slim, ocultação, pose, 75 reaplicações, socket, save/reload, NPC determinístico, exportação de 7 screenshots reais. Requer execução da engine.

## Limites e pendências

- Nenhuma captura real do Godot foi produzida no ambiente de criação deste patch, por falta do executável Godot.
- O módulo ainda requer validação do parser GDScript, mesh faces visíveis em OpenGL Compatibility e draw calls numa cidade populosa.
- As armaduras adicionadas no criador são apenas visuais; a associação automática entre os itens equipados e estes módulos deve ser feita na camada de apresentação do inventário em uma futura etapa aprovada, sem alterar atributos.
- Esta integração parte precisamente da R2 validada presente na biblioteca. Não aplicar cegamente sobre outra branch mais nova: comparar os arquivos modificados antes de mesclar.
