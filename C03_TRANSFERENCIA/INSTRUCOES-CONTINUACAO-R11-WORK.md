# Continuação — EXO-Murim Convergência 03 Alfa R11 / Work

**Base exclusiva:** último ZIP `EXO-MURIM-CONVERGENCIA-03-ALFA-R10.zip`, conferir o SHA do arquivo fornecido. Preservar R9 + seus saves de QA, não reiniciar merge, não abrir C04 e manter Terrain Forge 01 em ramo separado.

**Godot 4.6.2 Standard Compatibility é obrigatório para homologar.** Copie o ZIP para pasta de QA e execute:

```bash
GODOT=/caminho/Godot_v4.6.2-stable_linux.x86_64
ROOT=/caminho/EXO-C03-ALFA-R10-COPIA
"$GODOT" --headless --editor --path "$ROOT" --import --rendering-method gl_compatibility > qa-r10-import.log 2>&1
"$GODOT" --headless --path "$ROOT" --script res://convergence/tests/qa_c03_r10_native.gd > qa-r10-actor.log 2>&1
"$GODOT" --headless --path "$ROOT" --script res://exo_humanoids03_r2/tests/qa_native.gd > qa-r10-humanoid.log 2>&1
"$GODOT" --headless --path "$ROOT" --script res://exo_skin3d/qa_skin3d.gd > qa-r10-skin.log 2>&1
"$GODOT" --headless --path "$ROOT" --script res://convergence/tests/qa_c03_r9_native.gd > qa-r9-regression.log 2>&1
"$GODOT" --headless --path "$ROOT" --script res://exo_martial/tests/qa_r2_native.gd > qa-martial.log 2>&1
"$GODOT" --headless --path "$ROOT" --script res://exo_monumental/tests/qa_c03_r7_native.gd > qa-r7.log 2>&1
"$GODOT" --headless --path "$ROOT" --script res://exo_dungeon/tests/qa_c03_r6_native.gd > qa-r6.log 2>&1
```

Check all `exit_code`, parser errors, shader import failures, corrupt textures and warnings; zero exit alone is not enough. In a **new test campaign**, test no/previous `visual_r2`, classic/slim, PNG import, all five R2 garments, roll/attack/crouch/2M, weapon stowed/drawn, outfit change and player save/reopen. Test 30 NPC + 30 hostile actors on Ryzen 3200GE/Vega 8 and gather real screenshots, FPS, draw calls, p50/p95/p99. Independently test R9 interrupted Jade training then quit/reopen for conservation of Qi/stamina; inject save I/O failure; prove same committed lesson and meter. Run seeds 101,816204,707,18026, regions 14,26,78 and master stations/doors. Validate area accessibility beyond raycasting via real NavigationServer path or physical traversal. Continue only with reproducible FAILs; do not mock NPC/skills or spawn eight unused Bestiary entities.

**Pending R11:** finish missing eight humanoid Bestiary actor bindings when combat/ecology authorizes them; validate `visual_r2` on every load path; fix poses/hand sockets with real screenshots; confirm rights of all pre-existing assets. Separate Terrain Forge selective integration.
