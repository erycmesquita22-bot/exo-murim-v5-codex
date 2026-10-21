# EXO-Murim — Convergência 01.2 / Refinamento Visual 02

## Objetivo e limite do patch

Continuação incremental do pacote **EXO-Murim-Convergencia-01.2-Terreno-Aprovado.zip**. Corrigir o mato grande, borrado/compactado, a passagem da grama à terra e a sobreposição física/visual dos moradores. **A estrada de terra e pedras está preservada**, assim como os sistemas aprovados provisoriamente: 88 regiões, sementes, geração de lotes, arquitetura, combate, HUD, inventário e dados de save.

## Mudanças no projeto

1. **Shader do terreno (`genesis/terrain.gdshader`):** terreno vegetado com UV independente 2,45× menor em escala aparente; todas as texturas vegetais e blends seguem essa escala. A estrada continua usando a textura `trilha_terra.png` e os UVs `UV=p/6.0` originais. Solo irregular adicional ocorre somente na faixa de mistura das bordas, não no interior da estrada (peso de terra=1).
2. **Tufos (`genesis/region_scene.gd`):** diminuídos e definidos; cinco pequenas lâminas por tufo, altura máxima aproximada 0,3 m antes de escala, variações de cor e tamanho, ocupação probabilística progressiva em três faixas de distância da estrada. Foram evitados lotes, rios e declives abruptos. Amostragem determinística do mapa inteiro sem interromper a varredura numa ponta; máximo de 520 instâncias em um único MultiMesh por região. Sem colisão adicional.
3. **Separação por moradia (`convergence/region.gd`):** moradores compartilhando casa/trabalho usam lugares diferentes, com distância nominal de 1,55 m entre filas e 1,70 m lateral, reposicionados à altura real do terreno; praça distribui os moradores em mais posições ao longo das ruas.
4. **Movimento (`convergence/resident.gd`):** leve separação local atualizada a cada 0,24 s para evitar personagens atravessando visualmente uns aos outros, mantendo o sistema original de recuperação de bloqueios e rotas. A máscara de colisão, a identidade e os saves foram preservados.
5. **Nomes (`convergence/resident.gd` e `game.gd`):** etiquetas mostram o nome próprio curto e legível, sem acrescentar a atividade em uma segunda linha. Tipografia com contorno e bom contraste. Nomes visíveis a até 8 m, com prioridade para NPCs próximos quando projeções de etiquetas se sobrepõem. A identidade completa e o cargo continuam visíveis nos diálogos, que seguem ativáveis por E; labels ocultas não anulam NPCs.

## Verificações realizadas

- `python tools/check_approved_terrain.py`: **85/85 PASS**, sem falhas.
- `python tools/check_visual_refinement.py`: **60/60 PASS**, sem falhas. Verifica texturas/caminhos, separação de UV, preservação de estrada, limites de decoração, código de espaçamento, legibilidade de nomes, imports existentes, preservação dos comandos de salvamento e das regras estruturais.
- Comparação completa dos arquivos com SHA-256 do pacote anterior: **exatamente cinco arquivos existentes modificados**; todas as demais entradas originais permaneceram byte a byte iguais. Dois arquivos novos de QA foram adicionados.
- Integridade e estrutura dos ZIPs: verificação de leitura e caminho de `project.godot`.

**Cuidado:** resultados offline não representam testes físicos, visuais ou de desempenho na engine. Godot 4.6.2 Standard/Compatibility: **NOT_RUN**, pois o binário não está instalado e não existe acesso de rede no ambiente. O resultado é uma **versão-fonte candidata a validação**, não uma captura real do jogo corrigido.

## Como validar no Work / PC

1. Abra uma cópia extraída em Godot 4.6.2 Standard (Compatibility); importe os GLBs e rode F5. Se houver erros de shader/GDScript, registre linhas, corrija e repita.
2. Compare capturas das mesmas regiões/seeds do pacote anterior (especialmente seed 101, região 78), mesma câmera e iluminação. Fotografias conceituais não valem como evidência de Godot.
3. Inspecione os oito biomas: escala do mato, nitidez, margens das trilhas, textura aprovada da estrada, continuidade entre chunks, tufo repetido, grama suspensa ou invadindo casas, rios e lotes.
4. Teste NPCs na rua e junto à residência em região 78; nomes de dois moradores próximos não devem se sobrepor, e os NPCs devem ser interativos, mesmo se a etiqueta estiver temporariamente oculta. Teste rotas, noite, deslocamentos e reabertura após salvar.
5. Execute `convergence/qa.gd`, `convergence/routine_qa.gd`, `convergence/architecture_qa.gd` e outras suítes de regressão já usadas na 01.2. Documente PASS/FAIL/NOT_RUN.
6. Compare tempo de geração, p95 do quadro, memória e quantidade de nós em cidade e aldeia. Se o novo trabalho por região for elevado, reduza o número máximo de tufos ou a frequência da grade **sem mexer no chão aprovado**.

## Instalação

**ZIP completo:** extrair em diretório novo e abrir `project.godot`.
**PATCH:** extrair sobre uma **cópia** do pacote `EXO-Murim-Convergencia-01.2-Terreno-Aprovado.zip`, dentro da pasta que contém `project.godot`. Não aplique o patch sobre a Convergência 01.2 original sem os materiais aprovados. Faça backup de saves de usuário antes do teste.
