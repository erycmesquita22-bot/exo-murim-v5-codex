# R13 — Inicialização e gameplay

**Estado: NOT_RUN na Godot 4.6.2.** `res://convergence/game.tscn` continua sendo a cena inicial; fluxo `murim_flow.gd → _begin_new_procedural_campaign() → change_region()` preservado. Nenhuma partida foi aberta nesta sessão.

Foi criado o smoke `res://convergence/tests/qa_c03_r13_bootstrap_native.gd` para instanciar o host com a engine real e conferir o Core, personagem, criação e JourneySave, sem fingir que ele verifica F5, movimento ou a primeira região.

A ordem para testes manuais permanece: menu → criação → novo mundo procedural → região → jogador/câmera → deslocamento → NPCs/combatentes → dungeons → salvar → reabrir → trocar região. Não há logs, capturas ou FPS reais deste ciclo.
