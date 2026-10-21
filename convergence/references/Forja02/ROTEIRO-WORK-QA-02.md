# EXO Forja 02 — instrução executável de QA para Work

O trabalho consiste em **executar, medir, fotografar e corrigir falhas**, não produzir apenas um relatório descritivo. Usar o arquivo `EXO-Forja-Arquitetonica-02.zip`. Não modificar World Genesis nem EXO principal enquanto não houver autorização específica.

## Gates sequenciais

**G0 · import / sintaxe** — Godot 4.7.2: abrir `project.godot`, importar GLBs, registrar engine version e **todos os erros de parser/import**. Exigir 34 modelos `models/forja_v2` importados, total 121. `godot --headless --path . --editor --import --quit`. Falha => corrigir antes de G1.

**G1 · invariantes do plano** — Executar `godot --headless --path . --script res://qa/run_headless.gd`. Registrar `qa/last_headless_result_v2.json`, console integral e status da execução. Exigir **zero falhas**. Negativos incluem terreno inclinado, solo sem amostras, área pequena, ID repetido, sobreposição, contaminação de plano, orçamento de detalhe e hospedaria de 2 pisos.

**G2 · visual** — Rodar `forja/laboratorio.tscn` nos modos 1,2,3,4, com ao menos duas seeds por modo. Obter capturas reais em resolução estável, incluindo portas das quatro orientações. Avaliar escadas, telhados, paredes, pátios, toldos, estandes comerciais, entradas e terraço. Rodar `forja/galeria.tscn`: checar os 34 novos GLBs. Rodar `forja/praca_laboratorio.tscn`: testar visualmente mobiliário público. Registrar imagens **reais do renderer**, não usar a prévia PNG offline como substituto.

**G3 · física e acesso** — Em cena de teste 3D, colocar controlador `CharacterBody3D` com cápsula de raio ~0,35m/altura ~1,8m; percorrer `AnchorApproach -> AnchorGate -> AnchorEntrance` nos casos de pátio e `AnchorApproach -> AnchorEntrance` nas outras casas; verificar entrada sem atravessar colisores e obstáculos sólidos. Validar NavMesh somente se gerada explicitamente; nunca presumir.

**G4 · estabilidade** — Criar, descartar e recriar lotes com as mesmas seeds e comparar IDs/posições/assinaturas. Inverter a lista de lotes não sobrepostos. Alterar `detail_profile` e confirmar que assinatura e estrutura não são corrompidas, e que o visual tem diferença perceptível entre baixo/médio/alto. Testar reload numa cena nova e observar nós vazados.

**G5 · desempenho mensurado** — Executar `godot --headless --path . --script res://qa/benchmark_runtime.gd` e guardar `qa/benchmark_last_run.json`. Medir 4/8/16/32 casas, custo de importação, tempo de montagem, memória e quantidade de nós. Em execução gráfica, medir FPS e número de draw calls em câmera idêntica, sem afirmar otimização por mero baixo número de polígonos. Capturas de profiler e logs são obrigatórios.

**G6 · integração opcional** — Só após G0–G5 aprovados e contrato do Genesis existir, adaptar uma região de teste em branch separada. O Genesis emite lotes aprovados e ids estáveis; a Forja consome, recusando terrenos não comprovados. Testar rota para cada porta e persistência sem quebrar geração/regiões existentes. Não mergear se alguma falha crítica persistir.

## Entregáveis esperados do Work

1. ZIP corrigido da Forja 02 (ou 02.1, se necessário), com projeto Godot jogável e seu teste de import concluído.
2. Capturas reais **antes/depois** por modelo/distrito, apontando falhas de interseção, iluminação ou espessura. Anexar evidências de 3 níveis de detalhe e cena de pátio.
3. Arquivos de resultados GDScript, console e benchmark (incluindo o que não rodou e por quê).
4. Relatório de regressões e status por gate **APROVADO / REPROVADO / NÃO EXECUTADO**.

**Regra:** testes offline fornecidos são auxiliares. Nenhum número offline transforma código não importado em implementação aprovada na Godot.
