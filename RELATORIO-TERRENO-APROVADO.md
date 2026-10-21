# EXO-Murim — Convergência 01.2 / Terreno Aprovado

## Natureza da atualização

Patch visual sobre a Convergência 01.2, sem trocar a versão-base e sem reconstruir
Genesis, Forja, Living World, controles, combate ou salvamento. A aprovação dos
outros sistemas permanece provisória, conforme decisão do proprietário.

## Alterações reais

1. `genesis/region_scene.gd`: os oito biomas agora usam os derivados de alta
   fidelidade do atlas aprovado (`textures/terrain_approved/`), com trilhas em
   `trilha_terra.png` (em vez das texturas simples de 128x128 da coleção).
2. `genesis/terrain.gdshader`: reduz a forte multiplicação da cor de base e
   introduz irregularidade determinística apenas na transição material da trilha.
   A malha, UVs, colisões e valores de seed do terreno foram preservados.
3. `textures/terrain_approved/`: nove texturas PNG derivadas das texturas de
   `textures/tiles/`, com correção suave das bordas para repetição. Os pixels
   do centro (60% de largura/altura) foram preservados, e as bordas opostas
   coincidem pixel a pixel. Os arquivos aprovados originais não foram alterados.
4. `build_roadside_grass`: tufos esparsos ao longo das margens de trilhas,
   até 160 instâncias em **um MultiMesh** por região, com zero colisores,
   sem interferir em ruas, lotes, rios ou na lógica de persistência.

## Verificações locais

- `python tools/prepare_approved_terrain.py`: 9/9 texturas geradas e aferidas.
- `python tools/check_approved_terrain.py`: 85 testes offline PASS, 0 FAIL.
- Comparação SHA-256 com a Convergência 01.2: **somente dois arquivos antigos
  foram modificados** (`genesis/region_scene.gd` e
  `genesis/terrain.gdshader`). Todos os demais originais permaneceram iguais.
- Os novos materiais e utilitários são acréscimos, não substituições dos
  arquivos detalhados previamente aprovados.

## O que ainda NÃO foi testado

**Godot 4.6.2: NOT_RUN.** Este ambiente não possui o executável Godot nem
acesso de rede para obtê-lo. As verificações offline **não comprovam** a
compilação do shader, a estética final renderizada ou o custo de geração,
principalmente da vegetação de borda.

**QA obrigatório no modo Work ou PC antes de promoção:**

1. Abrir `project.godot` no Godot 4.6.2 Standard / Compatibility e importar assets.
2. Verificar o shader e os scripts sem erros de importação.
3. Capturar antes/depois da mesma seed e região 78, câmera e iluminação.
4. Conferir 8 biomas (inclusive transições nas bordas regionais) e repetição
   sem marcas de grade, trilhas com solo detalhado, variação de borda e
   vegetação sem atravessar casas ou ficar suspensa.
5. Rodar regressão de portais, casas, NPCs, combate, salvamento e recarga.
6. Medir tempo de montagem, P95 de quadro, FPS/RSS e contagem de draw calls
   em aldeia e cidade antes/depois da troca de textura.
7. Se o custo visual for excessivo, reduzir densidade de `build_roadside_grass`
   ou desabilitá-la temporariamente antes de alterar texturas aprovadas.

**Resultado:** PATCH FONTE IMPLEMENTADO; QA OFFLINE PASS; VALIDAÇÃO GODOT PENDENTE.

## Instalação

**ZIP completo:** extrair em diretório independente e abrir `project.godot`.
**ZIP PATCH:** extrair por cima de uma cópia intacta da C01.2, respeitando os
caminhos internos relativos à raiz do projeto. Fazer backup de saves antes
 do teste; o diretório de saves configurado no projeto não foi alterado.
