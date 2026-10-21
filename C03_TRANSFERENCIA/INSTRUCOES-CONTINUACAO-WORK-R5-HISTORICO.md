# CONTINUAÇÃO OFICIAL — EXO-MURIM C03 ALFA R5

## Ponto de partida obrigatório
**Último ZIP integral:** `EXO-MURIM-CONVERGENCIA-03-ALFA-R5.zip`. Não usar a R4 como novo ponto de partida, não reiniciar a convergência e não chamar Convergência 04. Preservar o ZIP R4 e qualquer save pessoal sem alterações.

Confirmar hash no `MANIFESTO-R5.json`/TXT e ler `C03_TRANSFERENCIA/RELATORIO-C03-ALFA-R5.md`, `QA-C03-ALFA-R5.json`, `ESTADO-INTEGRACAO-C03.json`.

## Importação/testes nativos — ainda não executados
1. Na Godot **4.6.2 Standard/Compatibility**, importar as cenas GLB primeiro: `godot --headless --editor --import --path <ROOT> --rendering-method gl_compatibility > R5-import.log 2>&1`; corrigir erros de GDScript/shader/import, guardar logs e exit codes.
2. Executar `godot --headless --path <ROOT> --script res://exo_creature_harmonizacao02/tests/qa_c03_r5_visual_runtime.gd > R5-models.log 2>&1` e registrar PASS/FAIL reais. Reexecutar `res://exo_bestiary/tests/qa_c03_r4_regional_fauna.gd`, `res://exo_core/tests/qa_core_integrations_r3.gd` e testes Core 01-P.
3. F5 nas 13 espécies com GLB: orientação -Z, escala única, pés no chão, transparência, walk/run/attack/hit, animações não provocam dano; sem duplicação de colisão/ator. Para wild_ox/wild_buffalo/qi_serpent confirmar fallback voxel sem ressaltar visual de outra espécie.
4. Com `exo_murim/r5/harmonized_creatures_enabled=false`, comparar a R4 de mesmo seed, região, câmera; reativar e repetir. Região 78 seed 101, regiões de floresta, deserto e montanha, noite/dia.
5. Combate, esquiva, HP, loot `hide/fang`, inventário 23/24 slots, crash/save recusado/reload, rollback sem duplicação, oito inimigos ativos máximo, rios/entradas/saves originais; FPS p50/1% low e memória **medidos em hardware real**, sem usar números inferidos.
6. Registrar visual e performance reais da Godot com capturas e logs; não utilizar imagens conceituais como evidências de gameplay.

## Próxima integração
Priorizar resolução Dungeon/Itens R3 atomicidade e host real, ou Forja reservada após QA nativo. Guardar rollback código+save pareado. Não ligar múltiplas autoridades para evento, loot ou relação social.

## Reproduzir QA estático (exige ZIP R4 de origem)

`python C03_TRANSFERENCIA/scripts_de_auditoria/r5_static_qa.py . /caminho/EXO-MURIM-CONVERGENCIA-03-ALFA-R4.zip`

O QA cria `C03_TRANSFERENCIA/QA-C03-ALFA-R5.json`. Não substitui execução nativa.
