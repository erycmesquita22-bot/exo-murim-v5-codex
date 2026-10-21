# EXO Visual 01 — Roteiro de QA nativo

Projeto: Godot 4.6.2 Standard; primeiro Compatibility; depois Forward+ separadamente.

## Pré-condições
- Copiar o projeto para uma pasta gravável; preservar a cópia de entrada.
- Não executar duas suítes ao mesmo tempo nem utilizar FPS gravado/fixo para benchmark.
- Iniciar importação limpa com a mesma versão alvo, verificar stderr, warnings e crashes.

## Entradas reais do projeto
```
godot --headless --path . --editor --quit
godot --headless --path . --script res://exo_visual/tests/qa_visual.gd
godot --path . --script res://exo_visual/tests/benchmark_visual.gd
godot --path . --script res://exo_visual/tests/capture_pilot.gd
```

Rodar também as suítes legadas (consultar `tools/`, `validation_r3/` e `exo_core/tests/`), especialmente Core, save v4, regiões, Fortificações 02/R2, Quest/Journey/Narrative, NPCs, Skin 3D e combate. A câmera real do piloto não substitui comparativo humano em regiões variadas.

## Gates
- Um erro de parse, recurso ausente, shader inválido ou falha de serviço invalida PASS.
- Capturas somente via viewport com seed/região/câmera registradas; nunca imagem desenhada externamente como 'captura'.
- Medir Floresta e Rio além dos cenários inicialmente instrumentados (cidade e vila), com preset mínimo, médio, alto e ultra, mantendo mesma seed/câmera/resolução.
- Para testar Forward+, iniciar com o parâmetro de renderização adequado e reiniciar processo. Não presumir alternância hot-swap. Verificar fallback e fidelidade entre backends.
- Ajustes gráficos não podem mudar `journey.data`, IDs, seed, geração, colisão ou navegação.
- Todos os testes ainda não executados constam `NOT_RUN` no relatório entregue.
