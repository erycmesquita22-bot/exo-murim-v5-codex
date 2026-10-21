# EXO-Murim — HUD 01 | implementação de interface

**Base:** EXO-Murim-EXO-Visual-01-CANDIDATO.zip, que já inclui as correções de Fortificações 02 R2.
**Engine pretendida:** Godot 4.6.2 Standard / Compatibility.
**Estado:** implementado em código e integrado à cópia do projeto; **ainda não passou por execução na Godot neste ambiente** (binário Godot indisponível). Não é validação de jogabilidade nem captura real.

## Como abrir

Execute o `project.godot` da raiz. O estilo `EXO Murim (oficial)` passa a usar `res://exo_ui/hud_murim.gd`, instanciado por `pause_ui.gd`. O HUD original `exo_hud.gd` continua funcionando para os outros nove estilos, para evitar regressão e preservar as opções salvas. O HUD é uma interface desenhada por `Control`, **não** uma foto do conceito colada sobre o jogo.

## Dados reais utilizados

- Retrato a partir da UV do rosto da skin 64×64 real;
- Vida `world.health` / `max_health`, Qi visualmente via `world.techniques.mana`, stamina;
- Nível e EXP do `journey_dynamic.progress` e fórmula real de `regional_ecology/rewards.gd`;
- Habilidades equipadas `techniques.DATA` e recargas `techniques.cooldowns`;
- Minimap da região ativa com estradas, lotes, passagens, residentes, posição do jogador;
- Contratos aceitos e progresso no `journey_dynamic.quests`; quando vazios, objetivo de `world.objective()`;
- Inventário, consumíveis e saldo reais; vida do alvo, canalização e avisos reais;
- Elementos dimensionados às bordas, escala via preferências `graphics.hud.scale`, opacidade e modo compacto.

**Controles reais preservados:** 1–6 para técnicas (conforme loadout atual), F para rolar, R para embainhar/alternar mãos, E para interação, P central, TAB mapa, I inventário. Os consumíveis permanecem utilizáveis pelo inventário; não introduzimos atalhos falsos apenas para imitar os ícones da arte de referência.

**Qi** substitui o texto “Mana” em todas as superfícies aqui modificadas. O campo técnico `techniques.mana` **não foi renomeado**, pois a alteração não deve quebrar contratos, saves ou sistemas existentes.

## Arquivos editados

- `exo_ui/hud_murim.gd` — nova apresentação.
- `pause_ui.gd` — instancia novo HUD, esconde tracker legado durante a aventura e abre inventário com I.
- `exo_hud.gd` — conserva 9 estilos legados e cede o estilo 0 ao HUD oficial.
- `exo_menu.gd` — rótulo Qi na central.
- `ui/pages/settings.gd` — documentação do atalho I.

A referência `exo_ui/hud_aprovado_referencia.png` é exclusivamente **arte conceitual aprovada**; a implementação visual real é o GDScript.

## QA na Godot (pendente)

```sh
godot --headless --path . --editor --import --quit
godot --headless --path . --script res://exo_ui/tests/qa_hud_01.gd
# Abrir projeto, iniciar aventura; confirmar em 1152×720, 1600×900 e 1920×1080.
# Verificar: I abre/fecha inventário; P abre central; Tab mapa; troca de estilo;
# HP/Qi/stamina/XP mudam com estado real; cooldown não excede slot;
# mapa e objetivos se atualizam na troca de região; HUD não persiste na pausa.
```

**Não ativar** o candidato Cidade Viva 01 automaticamente: é um patch não aprovado cuja base declarada é outra linha de desenvolvimento. Este pacote conserva a linhagem EXO Visual, já com passagem fluvial.
