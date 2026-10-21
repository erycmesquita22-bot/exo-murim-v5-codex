# Reproduzir em cópia e saves isolados

Use Godot 4.6.2 Standard, Compatibility. Configure `XDG_DATA_HOME` para pasta exclusiva de QA no Linux; não apague saves pessoais.

1. Importação: `Godot --headless --editor --import --quit --path PROJETO --rendering-method gl_compatibility`.
2. Regressão C3: `python3 tools/run_work_checkpoint_checks.py CAMINHO_GODOT`.
3. Regressão legada: `python3 tools/run_checks.py CAMINHO_GODOT`.
4. Host real: `Godot --headless --path PROJETO --script convergence/tests/qa_v4_integration.gd`. Depois execute novamente com `-- --reopen`. A fixture concede 10.000 Wen só a si para validar compra e venda.
5. Interior: script `convergence/tests/qa_v4_interior.gd` instancia os 52 layouts. Não homologa portas novas.
6. Suítes: City `exo_city_forge/qa/qa_r4_work_contracts.gd`; Crowd `exo_crowd_illusion/tests/qa_native_r4.gd`; Economy `exo_economy/tests/qa_r5_native.gd`; Skill `exo_skill_forge/tests/qa_r3_native.gd`; Biblioteca `exo_world_library/tests/qa_native.gd`; NPC03 `npc_system03/tests/qa_native.gd`; VFX `exo_vfx_forge/tests/qa_native.gd`; Jornada02 `journey_dynamic/v4/qa_native_journey_v4.gd`; Jornada01 `journey_dynamic/qa_journey.gd`.
7. Com display gráfico, Compatibility e áudio Dummy: `convergence/tests/capture_v4.gd`, depois `convergence/tests/benchmark_v4.gd`. Benchmark em processo exclusivo, sem FPS fixo e sem outras suítes concorrentes.

Sucesso requer saída zero **e ausência de `ERROR:`/`SCRIPT ERROR`**. Harness com mocks valida protocolo, não execução física. Preserve tentativas falhas, registre limites e diferencie as capturas atuais das históricas.
