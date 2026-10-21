# EXO-Murim — Mundo Vivo 02 R2 | Polimento de IA e campanha longa

**Estado: CANDIDATO TÉCNICO. Godot 4.6.2 NÃO EXECUTADA neste ambiente.**

## Base
`EXO-Murim-Mundo-Vivo-02-CANDIDATO.zip` (baseada em Assentamentos e NPCs 03). Não reconstrói World Genesis, Forja, textures, personagem, classes, movimento, menus nem saves herdados.

## Correções efetivamente implementadas
1. `regional_ecology/director.gd`: cada inimigo é testado no ponto final de spawn (distância de 19 a 85 m e câmera examinando corpo inteiro em três alturas), não apenas no centro do acampamento. Remoção controlada de inimigos inativos além de 105 m e limpeza de referências inválidas para manter orçamento ativo; suspende spawn em laboratório, prova ou fora de aventura.
2. `enemy.gd`: patrulhas regionais recusam ponto alvo com desnível acima de 0,65 m ou muito próximo de rio, mantendo o limite territorial. Ser atingido atualiza memória de agressão por seis segundos, inclusive de costas.
3. `regional_ecology/rewards.gd`: a fila recusa inserir recompensas além de 210 saques pendentes ou do máximo de 2048 eventos. Compacta somente recibos ecológicos **já coletados** antes de exceder o limite; preserva saques pendentes e eventos legados. Valida armas procedurais antes de incrementar IDs e registrar evento.
4. `convergence/game.gd`: impede marcar uma morte como recompensada sem o registro de saque; se o registro estiver bloqueado por save inválido ou saturado, restaura o adversário com 1 PV e informa ao jogador que deve coletar recompensas. É um guardrail raro, a revalidar fisicamente na Godot.
5. `convergence/state.gd`: adiciona verificação de contadores de XP, duplicação e limites de membros mortos persistidos. Preserva o esquema anterior.
6. `regional_ecology/qa_massive.gd`: amplia a suíte nativa preparada com compactação, preservação de saques pendentes, limites de respawn e idempotência do relógio.
7. `tools/qa_mundo_vivo_round2.py`: QA sintético adicional reproduzível, com cenários planos, montanhosos, rochosos e estreitos; gera relatório JSON.

## Massivo: o que REALMENTE foi executado
`python tools/qa_mundo_vivo_round2.py`: **1.585.084 assertivas, 0 falhas** em modelo offline Python independente:
- 32.000 planos de ecologia em terrenos artificiais variados, 88.000 territórios;
- 183.040 identificadores determinísticos de loot;
- 86.400 eventos simulados de XP;
- 52.800 gerações simuladas de grupos inimigos;
- 40.000 verificações de membros de spawn;
- 15.320 instantes de relógio e seis casos de compactação do log.

Os testes usam um espelho algorítmico e checagens textuais. **Não demonstram execução do GDScript, colisão, navegação, renderização, desempenho nem validação real de arquivo salvo pela Godot.** O número grande não constitui probabilidade de ausência de bugs.

## Status de validação
| Sistema | Resultado |
|---|---|
| Modelo offline / contratos e IDs | PASS |
| Integridade ZIP / escopo das alterações | PASS se a conferência de pacote anexada estiver íntegra |
| Testes nativos `regional_ecology/qa_massive.gd` | NOT_RUN |
| Físicas de spawn / navmesh / patrulha real | NOT_RUN |
| Persistência em dois processos Godot | NOT_RUN |
| Combate dos inimigos em relevos e magia | NOT_RUN |
| Regressões do personagem / construção / NPCs | NOT_RUN |
| Desempenho no ambiente do Work ou PC | NOT_RUN |

## Limitações conhecidas e recomendações
- Spawn e patrulha continuam um protótipo de IA de campo: obstáculos complexos, escaladas e navegação regional precisam de testes de física e talvez de um serviço de pathfinding dedicado.
- XP ecológica persiste em banco próprio e ainda **não aumenta o nível do personagem**. Isso é intencional e precisa ser integrado à progressão aprovada, evitando níveis concorrentes.
- Guardas não respondem ainda a invasões, produção econômica não foi implementada, e atividades de NPCs são ciclos visuais/lógicos, não profissões completas.
- Eventos únicos de chefes e conflitos de facções continuam fora desta entrega. Balanceamento de dano, itens e tempo de cooldown requer sessões humanas.
- Geração de novos mapas: nenhum dado do Genesis foi modificado. O planejamento do encontro ainda rejeita pontos fisicamente incompatíveis, o que pode resultar em menos territórios do que o orçamento máximo.

## Próxima rodada no Work
1. Use Godot 4.6.2 Standard e renderizador Compatibility. Importe numa cópia nova, corrija qualquer erro de parser/typing; `godot --headless --editor --import --quit`.
2. `godot --headless --path . --script res://regional_ecology/qa_massive.gd`, depois execute as suítes históricas e `tools/run_convergence012_checks.py`.
3. Verifique spawn atrás da câmera e atrás de construções, combate, patrulha, dano, reações ao ser atacado e retorno após desistência, em 3+ seeds de cada bioma perigoso.
4. Teste 1 e 2 membros por território, morte parcial, save/load, morte final, 540s de relógio e renovação — sem XP/saque duplicado. Teste inventário cheio e fila perto de 210 saques.
5. Execute 1 dia do jogo com moradores, testes de sono, trabalho, treino e mudança de região; compare o resultado com Assentamentos/NPCs 03.
6. Registre logs, FPS/P95, picos de memória, número de nós, erros, capturas reais e status PASS/FAIL/NOT_RUN. Corrija e reexecute; não anuncie aprovação sem execução nativa.
