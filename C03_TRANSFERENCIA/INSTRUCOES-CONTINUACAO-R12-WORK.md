# Continuação Work — Convergência 03 ALFA R11 → R12

Base EXCLUSIVA: ZIP completo `EXO-MURIM-CONVERGENCIA-03-ALFA-R11.zip`, depois de validar seu SHA. Não voltar à R10, R6 ou Terrain Forge ramificação como base. Descompactar em uma cópia isolada, `project.godot` na raiz. Preservar os ZIPs R10 e R11 e os saves pessoais.

1. Ler `RELATORIO-C03-ALFA-R11.md`, `CONFLITOS-TERRAIN-FORGE-R11.json`, `QA-C03-ALFA-R11-MATRIZ.json`, `COMPARATIVO-FORGE-ON-OFF-R11.md` e este documento.
2. Godot 4.6.2 Standard Compatibility em ambiente funcional:
   ```bash
   GODOT=/caminho/Godot_v4.6.2-stable_linux.x86_64
   ROOT=/caminho/EXO-MURIM-C03-R11-ISOLADO
   "$GODOT" --headless --editor --path "$ROOT" --import --rendering-method gl_compatibility > qa-r11-import.log 2>&1
   "$GODOT" --headless --path "$ROOT" --script res://convergence/tests/qa_c03_r11_native.gd > qa-r11-contract.log 2>&1
   "$GODOT" --headless --path "$ROOT" --script res://convergence/tests/qa_c03_r10_native.gd > qa-r10.log 2>&1
   ```
   Executar também provas R9, R8, R7, R6, Visual e Core. Inspecionar stderr/erros, não apenas exit=0.
3. Validar cenas por F5 em 101, 816204, 707, 18026; cidade 78, fluviais 14/26, montanhas/florestas/vilas. Capturar imagens REAIS com mesmo enquadramento Forge OFF/ON e filtros 0/1/2.
4. Com mesma câmera/seed/região, medir renderer (Compatibility), FPS/frametime p50/p95/p99, RAM/drawcalls; usar PC Ryzen 3200GE/Vega 8 se possível. Se falhar, não promover.
5. Testar o menu original e reinício gráfico; garantir retornos a R10 no modo OFF, sem modificar saves/monumentos.
6. Prosseguir para correção de bugs reais e QA final antes de introduzir mais conteúdo. Não iniciar Convergência 04.
