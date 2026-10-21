# QA nativo Godot 4.6.2 — plano obrigatório

- `qa_all_scripts.gd`: parser e preload de 35 scripts GDScript, incluir compat legado.
- `qa_bestiary.gd`: catálogo, perfis, variação e decisões em estados representativos.
- `qa_massive.gd`: 25.000 cenários lógicos GDScript.
- `laboratory.tscn`: iniciar sete atores voxel, gravidade, linha de visão, direção, fleeing, chase e ataques sinalizados (não aplica dano).
- Core integrado: registrar manifesto, exercer serviço via `invoke`, matar um inimigo autorizado e validar recibos antes/depois de save/reload.
- Stress: 1/4/8 atores (respeitando MAX_ACTIVE=8), quadros, RAM, P95, física e detecção. Perfis remotos não podem instanciar Node3D.
- Adversarial: alvo desaparece; região descarrega; barreira interposta; quedas/rios; líder morre; HP zera durante windup; inventário cheio; duplicação de recompensa; save interrompido.
- Evidência requerida: logs de versão Godot, capturas reais, resultado PASS/FAIL/BLOCKED/NOT_RUN, seed, cena, hardware, tempo de teste.
