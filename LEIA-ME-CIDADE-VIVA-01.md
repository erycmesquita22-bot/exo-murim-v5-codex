# EXO-Murim — Cidade Viva 01 (candidato para QA)

**Estado: CANDIDATO NÃO VALIDADO NA GODOT — NÃO APROVADO.**

Base: `EXO-Murim-Fortificacoes-02-R2-PROJETO.zip`. Este patch introduz uma camada de urbanismo **visual e não persistida**, associada aos lotes atuais, sem substituir World Genesis, Forja Arquitetônica, Living World, sistema de salvamento ou fortificações.

## Integração

- `cidade_viva/planner.gd`: seleção determinística dos distritos funcionais e objetos contextualizados, reserva de segurança das entradas, dos eixos viários, dos rios e do perímetro amuralhado.
- `cidade_viva/renderer.gd`: instanciamento controlado de assets existentes da Forja 03, metadados `cidade_viva` e `cidade_viva_pois`, colisores simplificados para poucos objetos grandes.
- `convergence/region.gd`: após `integrate_perimeter()`, chama a apresentação urbana. Desligamento temporário via `urban_enabled=false`; não afeta save.

Os NPCs continuam sob `convergence/occupancy.gd`, `convergence/region.gd` e `living_world/*`. O planner adiciona pontos de referência de atividade nos metadados, **não** um segundo gerenciador de atores. Distritos mistos são inferidos de lotes próximos; não alteram funções de lotes persistidos.

Não foram implementados: novo traçado de ruas, comércio transacional, comportamentos novos de NPCs, novos edifícios de serviço, interiores, horário específico de props ou novos sistemas de salvamento. A densidade adicional vem de fachadas e anexos, não de casas/identidades novas.

## Como validar na Godot 4.6.2 Standard / Compatibility

```bash
godot --headless --path . --editor --import --quit
godot --headless --path . --script res://cidade_viva/tests/qa_cidade_viva.gd
godot --headless --path . --script res://exo_core/tests/qa_fluvial_integration.gd
godot --headless --path . --script res://exo_core/tests/qa_fluvial_reload.gd
godot --headless --path . --script res://convergence/qa.gd
```

Para **capturas reais**, executar com renderização gráfica habilitada (não `--headless`):

```bash
godot --path . --script res://cidade_viva/tests/capture_cidade_viva.gd
```

O script prevê dez vistas (antes/depois, portão, comércio, residências, marcial, periferia, rio e panorama), na pasta retornada pelo caminho `user://`. São capturas geométricas sem NPCs. Para validar vida urbana, executar o jogo em `res://convergence/game.tscn`, percorrer as ruas e avançar 24 horas de relógio, comparando identidade/rotina de moradores, saves e carregamento. Verificar com pessoas reais a legibilidade isométrica das fachadas.

Compare FPS/P95/memória/nós somente se o motor for executado nas mesmas condições, com `urban_enabled=false` versus `urban_enabled=true`; o código não fornece métricas sintéticas fingindo ser frame time.

## Critério de reprovação

Qualquer erro de importação, `SCRIPT ERROR`, portão/rua obstruído, colisão incorreta, rio tamponado, save incompatível, NPC incapaz de chegar à rotina ou regressão mensurável de FPS impede aprovação. A ausência de sprites/capturas reais ou de medição também impede aprovação.
