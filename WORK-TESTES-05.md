# WORK — EXECUTAR TESTES REAIS WORLD GENESIS 05

1. **Não confiar em resultados Python como certificação Godot.** O planejador foi alterado para a versão 2 e seus logs sintéticos estão em `evidence/settlement_v05_synthetic/`.
2. Abrir o ZIP completo em cópia, registrar versão exata da Godot e SHA-256 do ZIP.
3. Executar `python tools/check_settlement_static_05.py` e depois `python tools/run_settlement_qa.py /caminho/godot 10000`. Se o parser falhar, corrigir somente o problema reproduzido e rerodar. O runner para na primeira falha; guardar stdout/stderr.
4. Se todas as suítes executarem, examinar **explicitamente** as inclinações reportadas em `SETTLEMENT_GRADES_RESULT`. O teste de inclinação é diagnóstico e pode emitir graus perigosos sem retornar código de erro.
5. Validar colisão/entrada/porta/poço/ruas/rios em cenas reais de aldeia, vila e cidade. Executar o piloto das 7 regiões e benchmarks comparativos 03↔05 no mesmo ambiente, sem modificar UI/saves/combate.
6. Guardar para cada erro: seed, região, escala, screenshot/captura real se útil, stacktrace, arquivos alterados, motivos, tempo e resultado de reteste.
7. Devolver o ZIP Godot corrigido com relatório PASS/FAIL/NOT_RUN. Sem alegar 99,999999% de sucesso com base na amostra Python.
