# EXO-MURIM — Convergência 03 Alfa R13 — relatório técnico

**Classificação:** CANDIDATO DE CÓDIGO; NÃO HOMOLOGADO; Godot 4.6.2 NÃO EXECUTADA.

## Procedência
- Base ÚNICA R12: `EXO-MURIM-CONVERGENCIA-03-ALFA-R12.zip`; SHA-256 `f785d24d6bde1c29ba74e7a47c9f5aad74b004de5c26991957fee061dbeeb796`, 4.706 arquivos, CRC íntegro.
- R11 foi mantida somente como referência histórica. Não houve re-merge, alteração dos 242 recuos corrigidos na R12, nem perda de arquivos da base.

## Correções cirúrgicas R13
1. Em `project.godot`, corrigi `config/custom_user_dir_name` que ainda apontava para R11 QA, e alterei o nome para R13 QA. Isso é isolamento, **não alteração do conteúdo dos saves**.
2. Em `convergence/game.gd::change_region()`, corrigida falsa indicação de sucesso quando `save_progress()` falhava. O método agora reporta `save_failed` e retorna `false`; não comunica a região como salva. A região ainda pode estar carregada em RAM: rollback físico permanece pendente de QA.
3. Teste nativo novo `qa_c03_r13_bootstrap_native.gd` tenta carregar a cena oficial e verificar inicialização do EXO Core e player; não gera uma campanha fake.
4. Executor Windows R13 completo, matriz QA com distinção entre PASS offline, falhas de fixtures históricos e NOT_RUN nativo.

## Resultados efetivos
- R12 SHA/CRC verificados. Script R12 offline (R11→R12) retornou **25 PASS, 0 FAIL**.
- Auditoria estática R13 retornou **13 PASS, 0 FAIL**.
- Suítes de referência Dungeon R2, Itens R3 e Marcial R2 PASS; suítes antigas NPC, Humanoides e Bestiário falham nas premissas de distribuição standalone e ausência de README, conforme logs anexos; NÃO foram ocultadas.
- Godot nativa: NOT_RUN por ausência de executável e falha DNS. Não há parser, F5, shaders GPU, benchmarking ou capturas reais desta revisão.

## Salvamento, mundo e segurança
- JourneySave, WorldState, Core 01-P, catálogo de NPCs, Dungeon, itens, fauna, Forja, Mestre, Humanoides e Terrain Forge mantidos sem intervenção em seus scripts de domínio.
- As 480 skins legadas continuam em quarentena; zero mídia nova adicionada.

## Evidência e limites
Veja `QA-C03-ALFA-R13-MATRIZ.json`, `RELATORIO-ERROS-PARSER-R13.md`, `RELATORIO-SALVAMENTO-RECUPERACAO-R13.md`, `LOG-AMBIENTE-GODOT-R13.txt` e `QA-R13-RODAR-WINDOWS.ps1`.

**Não afirmar jogo executável, jogável nem 0 erros de parser nesta rodada.**
