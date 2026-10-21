# Roteiro de validação real — Mode Work / Godot 4.7.2

## Premissas

O projeto nesta entrega é **separado**. Não atualizar, sobrescrever nem incorporar no World Genesis/EXO-Murim até o QA passar. Testar sobre uma pasta temporária com permissão de escrita. Se usar Godot sem janela, confirmar que o renderizador Compatibility e o driver OpenGL estão disponíveis para gerar capturas.

## Execução mínima (registrar comandos, logs e falhas)

1. Abrir o ZIP e inventariar arquivos; verificar `docs/MANIFEST-FONTE-HERDADA.json`.
2. `python qa/check_package.py` e `python qa/check_geometry.py` — ambos devem terminar em 0. Os relatórios devem refletir arquivos e tamanhos reais.
3. `godot --headless --path . --editor --import --quit` — verificar parse GDScript/importação GLB sem erros. Se exit code !=0, localizar o erro no log.
4. `godot --headless --path . --script res://qa/run_headless.gd` — gravar o `FORJA_QA_FINAL` e `qa/last_headless_result.json`. **Qualquer falha bloqueia a integração**. Contagem esperada, quando efetivamente executada: 8.000 lotes individuais planejados duas vezes cada, cerca de 24.000 assertivas e 4 casas efetivamente instanciadas.
5. Abrir projeto interativamente: F5, alternar 1 (5 casas) / 2 (8 casas) / R (outra seed). A quantidade apresentada deve corresponder à de lotes. Confirmar fisicamente câmera, telhados, paletas, portas, colisões e ausência de deformações.
6. **Capturas reais**: `godot --path . -- --capture`, produzindo `qa/captures/forja_aldeia.png` e `forja_cidade.png`; verificar arquivos/cores/geometria antes de publicar.
7. Caminhada do personagem de teste na cena do EXO, em branch temporária: aproximar-se da entrada, abrir porta, atravessar soleira, sair e confirmar que a porta fechada bloqueia. Não usar a geometria de segundo andar para alegar escada interna pronta.
8. Testar 100 lotes com amplitude de altitude de 0.3m (devem ser rejeitados), 100 com altura plana e entrada desimpedida, sobreposições e lotes estreitos. Conferir que não há casas cortadas nem entradas impossíveis.
9. Coletar criação de nós, consumo de memória, draw calls e FPS para 5, 8, 16 e 32 casas; somente decidir estratégia de otimização após medir.
10. Relatar erros de parse/importação, testes passados/reprovados, tempos reais de frame, 2 capturas e alterações feitas, preservando código original dos assets.

## Critérios de aceite

- **G0**: sem erros de compilação/parsing na Godot 4.7.2.
- **G1**: mesmo seed+id = mesma variante, independentemente de ordem.
- **G2**: lote reprovado não gera construção; loteamento atômico não produz casas parciais.
- **G3**: 4 lotes válidos geram 4 casas, 8 geram 8. Nenhuma interpenetração visível.
- **G4**: porta e rota frontal acessíveis; sem obstáculos no eixo da entrada, após verificação no jogo.
- **G5**: preservação visual dos assets aprovados; sem recoloração substituindo geometria.
- **G6**: dados de desempenho reais antes de decidir uso em regiões densas.

O modo Work deve devolver os logs e resultados **executados**, não preencher métricas por estimativa. Se não conseguir rodar a Godot, registrar bloqueio sem alegar validação concluída.
