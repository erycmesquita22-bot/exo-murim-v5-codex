# EXO-MURIM — DUNGEON GENESIS 01 — POLIMENTO 0.2.0

**Código modular GDScript de candidato de integração — NÃO APROVADO NATIVAMENTE.**

- **36.000/36.000 cenários PASS** em modelo **Python independente** (6.000 por família); **245/245 casos adversariais rejeitados**. Não equivale a execução nativa do motor Godot.
- **26/26 verificações estáticas** aprovadas; Core original mantido sem alteração.
- Mecânicas aprimoradas: bloqueadores físicos de fechaduras, chaves coletáveis, verificação de proximidade, trilhos laterais, portais por interação explícita sem bounce, proteção contra atalhos sem chave, detecção de chaves inválidas, variação probabilística de salas secretas, persistência de portões/chaves via delta.
- `exo_dungeon/module/manifest.json` — módulo opcional, versão `0.2.0`.
- `exo_dungeon/runtime/dungeon_instance.gd` — materialização, sinais de interação e transições.
- `exo_dungeon/tests/stress_reference.py` — repetir QA Python não nativo.
- `exo_dungeon/tests/run_qa.gd` — 7.200 casos **preparados**.
- `exo_dungeon/tests/run_mechanics_qa.gd` — 144 cenários mecânicos nativos **preparados**.
- `exo_dungeon/tests/run_render_smoke.gd` — smoke 3D **preparado**.
- `evidence/QA-REFERENCIA-MASSIVO.json` e `evidence/QA-ESTATICO.json` — saídas concretas desta sessão.
- `RELATORIO-DUNGEON-GENESIS-01.md` — defeitos, correções, resultados e limites.
- `INTEGRACAO-DUNGEON-GENESIS-01.md` — procedimentos e responsabilidades do integrador EXO.

O `project.godot` incluído é APENAS do laboratório separado. **Não sobrescreva o project.godot central ou scripts do EXO Core.** O Core de ~192 MB não é redistribuído no ZIP; peças visuais do projeto são opcionais através do adaptador Forja.

## Executar no PC com Godot 4.6.2 instalado

```bash
godot --headless --path . --script res://exo_dungeon/tests/run_qa.gd
godot --headless --path . --script res://exo_dungeon/tests/run_mechanics_qa.gd
godot --headless --path . --script res://exo_dungeon/tests/run_render_smoke.gd
```

O projeto isolado também abre a cena `exo_dungeon/lab/main.tscn`, com seleção de família (1–6), seed (R) e andar (Q/E). Valide os scripts na Godot antes de promover qualquer build para produção.
