# INSTRUÇÕES DE CONTINUAÇÃO — WORK / Convergência 03 ALFA R2

## Comece aqui
**Fonte exclusiva:** `EXO-MURIM-CONVERGENCIA-03-ALFA-R2.zip` (último ZIP deste chat). Descompacte numa **cópia de trabalho**, com `project.godot` na raiz. NÃO começar da Alfa R1, Cidade Viva R2 ou outro projeto antigo. NÃO criar uma Convergência 04. Confirme o SHA-256 e leia `C03_TRANSFERENCIA/RELATORIO-C03-ALFA-R2.md`, `ESTADO-INTEGRACAO-C03.json` e `MANIFESTO-CORRECOES-R2.json`.

## Estados
Convergência 03 ainda **parcial**: HUD, Terreno R1, Core 01-P, NPC R2, Flow e RIG estão integrados no código, mas exigem compilação, gameplay e QA nativos. Dungeon, Itens R3, Forja, Marcial, Bestiário, Harmonização, Humanoides R2 estão nas pastas do projeto como **staging**, sem ativação de runtime; seus bloqueios permanecem.

## Primeiro, audite o que o Chat corrigiu na R2
O erro RIG01 de duplo override dos cotovelos foi removido; agora `animation_library.gd` é dono final de braço livre. Criação direciona ao atlas procedural sem reconstruir a vila no ramo moderno. Falha de publicação de chegada não congela a simulação; isso não prova save transacional. Esses são patches de código ainda não comprovados por execução.

## Testes nativos obrigatórios
Use Godot **4.6.2 Standard / Compatibility**; preserve o `project.godot` original em outra cópia. No Linux:
```
GODOT=/caminho/Godot_v4.6.2-stable_linux.x86_64
ROOT=/caminho/EXO-C03-ALFA-R2-COPIA
"$GODOT" --headless --editor --path "$ROOT" --import --rendering-method gl_compatibility > qa-import.log 2>&1
"$GODOT" --headless --path "$ROOT" --script res://convergence/tests/qa_rig01_eight_directions.gd > qa-rig01.log 2>&1
"$GODOT" --headless --path "$ROOT" --script res://exo_core/tests/qa_core.gd > qa-core.log 2>&1
"$GODOT" --headless --path "$ROOT" --script res://exo_core/tests/qa_persistence01p.gd > qa-persistence.log 2>&1
```
Inspecione logs de erros/asserções; `exit=0` sozinho NÃO basta. Execute os 23 testes Cidade Viva históricos e cenários de gameplay. Complemente com 8 direções na viewport real, nova campanha→região procedural, saves, NPC, terreno R1, rios, cidades e FPS no PC Ryzen 3200GE/Vega 8. Releia `auditoria_pre_c03/PLANO-QA-NATIVO-03.md` para a matriz completa.

## Bloqueios de contratos
Dungeon×Itens exigem atomicidade com recibo e claim num único commit; não devolver true artificialmente. Mestres precisam API pública do Narrativo e provas trusted. Forja requer reservas e interiores verdadeiros. NPCs precisam estações aprovadas; skins herdadas de terceiros em quarentena comercial. Nunca registrar um módulo bloqueado no exo_core só para dizer que foi integrado.

## Preservação e entrega
Isolar diretório `user://` por build, preservar saves originais e backup .bak/.tmp; checkpoints com SHA do código e saves de teste pareados. Durante QA, documentar cada FAIL, correção e novo PASS, incluindo logs e screenshots da Godot; não gerar imagens conceituais como evidência. Entregar **ZIP integral atualizado** + relatório + manifestos/hash + pendências, mantendo a Alfa R2 recuperável.
