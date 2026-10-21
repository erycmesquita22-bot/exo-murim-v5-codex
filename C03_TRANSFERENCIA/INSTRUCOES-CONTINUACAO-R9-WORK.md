# EXO-MURIM — INSTRUÇÕES PARA R9 / WORK

Base exclusiva: `EXO-MURIM-CONVERGENCIA-03-ALFA-R8.zip`, confirmar SHA listado em `EXO-MURIM-C03-ALFA-R8-SHA256.txt`. Não voltar à Cidade Viva, R6 ou R7 para refazer o merge. Não iniciar Convergência 04. Preservar R7 integral e saves.

Leia `RELATORIO-C03-ALFA-R8.md`, `ESTADO-INTEGRACAO-C03-R8.json`, `QA-C03-ALFA-R8-MATRIZ.json`, `DIFF-C03-R7-R8.patch`. Prioridade **nativa**: Godot 4.6.2 Standard Compatibility, import completo e F5. Nunca transformar testes estáticos em QA funcional.

Com Godot presente:
```
godot --headless --editor --path <root> --import --rendering-method gl_compatibility > qa-import.log 2>&1
godot --headless --path <root> --script res://convergence/tests/qa_c03_r8_native.gd > qa-r8-native.log 2>&1
godot --headless --path <root> --script res://exo_martial/tests/qa_r2_native.gd > qa-martial-r2.log 2>&1
```
Testar jogadores e NPCs nas regiões 78, 14, 26 e seeds 101/816204/707/18026: física, modelo, disponibilidade, anúncio de matrícula, requisitos, rejeição/aceite, rollback em write-fail, duplicidade de receipt, mesmo save para Narrative e Martial, reabertura em processo novo. Validar sempre escola física e NPC acessível; não deslocar NPC por teleporte para criar testes PASS.

O vínculo da matrícula existe agora sob Core.atomic + Narrative.stage + Engine.confirm. Aulas/skills ainda BLOQUEADAS até eventos verdadeiros e custos Qi/stamina do runtime; implementar eventos de combate, esquiva, meditação e demonstração com identificação persistente/replay, depois usar `cultivation.reveal/learn` do dono Core. Não adicionar outra autoridade.

Terrain Forge é candidato separado da R6 e não está na base R8. Não sobrepor region_data.gd/region_scene.gd/project.godot. A segurança do rollback inclui pares código+save; não mudar layout de campanhas antigas silenciosamente.

Ao avançar para R9, entregar ZIP completo atualizado, SHA, manifesto, diff, logs/capturas reais, falhas e NOT_RUN detalhados. No Work partir unicamente do ZIP R8 (ou checkpoint posterior deste chat), não refazer merge.
