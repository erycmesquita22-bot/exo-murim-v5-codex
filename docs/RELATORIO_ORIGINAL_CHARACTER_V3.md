# EXO-MURIM — V3: relatório de movimento e controle

## O problema da V2 e o que foi substituído

A V2 era um laboratório de clipes e estados discretos: velocidade aplicada imediatamente, câmera ortográfica fixa, bloqueio de locomoção durante ações e retorno a repouso entre golpes. Ter dez nomes de animação e transformações finitas não demonstrava continuidade de um personagem jogável.

A V3 substitui esse controle por movimento em terceira pessoa e refaz a autoria das ações, preservando o GLB V4 como fonte da geometria. A versão anterior permanece separada. Isto é um protótipo independente de movimento e combate com alvo estático; não é o jogo principal EXO finalizado.

## Implementação

- **Controle:** direção relativa à câmera, aceleração/frenagem, giro limitado por segundo, corrida e postura de combate. O ritmo considera a velocidade realmente obtida após colisão.
- **Câmera:** perspectiva atrás do personagem, mouse, zoom, acompanhamento suavizado, SpringArm com exclusão da colisão do próprio corpo, foco opcional no alvo. Arrasto de toque e botões estão preparados, mas não testados em Android.
- **Locomoção:** ciclos de autoria própria com apoio e retorno dos pés, flexão de joelhos, oscilação de quadril, contramovimento do tronco e braços. Caminhada/corrida são misturadas com fase compartilhada. Mistura de direção, corrida e cadência no combate também é suavizada, inclusive ao encontrar o alvo/obstáculo.
- **Ações:** preparação, fase ativa e recuperação; avanço físico sincronizado à fase de golpe, esquiva direcional, resposta a impacto. As ações se misturam através de duas ramificações de AnimationTree; não há reset obrigatório à pose neutra entre dois golpes.
- **Comandos:** buffer de ataque de 0,28 s, encadeamento 01→02 a partir de 62% do primeiro golpe, cancelamento por esquiva depois de 55% da ação. Um ataque sem arma prepara o cabo e conserva o comando para o primeiro golpe.
- **Contato:** o alvo testa distância/cone durante a janela do golpe; recebe 20/30 de dano de teste, muda de cor, oscila e aplica hit-stop de 45 ms. É um teste de curta distância com alvo estático; não é um sistema completo de hitboxes, espada ou inimigos.
- **Equipamento:** mão esquerda busca o cabo original na cintura, encontro das mãos e transferência à direita; devolução pelo percurso inverso. Encaixe recalculado após as misturas por transformação completa. A bainha permanece excluída. Nenhuma lâmina foi inventada.
- **Renderização:** Compatibility, um atlas do personagem e um material. Sombras dinâmicas de múltiplas passagens foram substituídas por sombras simples de contato do cenário, mantendo a iluminação do personagem. Nenhuma redução artística do rosto ou roupa foi feita para obter o ganho de desempenho.

São 15 clipes no GLB: dez contratos originais e cinco variações de locomoção armada/direcional. Os ossos e peças mantêm os contratos documentados em `HIERARQUIA.md` / `bone_contract.json`. As malhas continuam rígidas por segmento, sem deformação orgânica. Os pés são resolvidos na autoria e exportados em keyframes; não há IK adaptativa em runtime ou simulação de tecido/cabelo.

## Execução real validada

Ambiente: Godot **4.6.3-stable (official) Standard**, **gl_compatibility**, Linux/Xorg virtual, **llvmpipe (LLVM 19.1.7, 256 bits)**. Blender 4.3.2 disponível e utilizado. Importação final sem erros no log. Teste headless separado para lógica e execução gráfica real para vídeo/capturas.

A sequência automática usa os mesmos comandos de InputMap do jogador: caminhar, acelerar para corrida, frear, virar, foco, preparar equipamento, aproximar do alvo, golpe 01, novo comando para encadear 02, esquiva lateral, reação a impacto, deslocamento de combate, desbloqueio de foco, nova corrida, inversão de direção, guardar equipamento e inspeção neutra. A órbita de câmera recebe eventos de mouse na inspeção final. Não há montagem de slides no vídeo.

| Medida da sequência | Resultado |
|---|---:|
| Ticks físicos | 1030 |
| Tempo de simulação | 17.167 s |
| Combos encadeados | 1 |
| Contatos registrados no alvo | 2 |
| Vida final do alvo | 50 / 100 |
| Maior velocidade de locomoção amostrada sem ação | 4.400 m/s |
| Maior velocidade incluindo esquiva | 6.291 m/s |
| Maior erro de posição do encaixe do cabo | 2.67e-07 m |
| Maior mudança de direção visual por tick | 0.183 rad |
| Maior mudança de orientação global de osso por tick | 0.388 rad |
| Erros dos testes finais | 0 |

O último limite é uma verificação de descontinuidade, não uma certificação estética: mede ossos exceto o osso de equipamento, excluindo a restauração explícita da inspeção neutra e os dez primeiros ticks. O teste rejeita mudança acima de 0,55 rad em um tick. A qualidade do movimento ainda deve ser julgada jogando e vendo o vídeo; esse número sozinho não define uma boa animação. O log registra eventos de entrada/saída de ação, dano, câmera e amostras de velocidade, pose, encaixe e trajeto.

Durante a preparação foram detectados e corrigidos: orientação instável de braços nos ataques, configuração de transferência do cabo, transições de postura durante colisão e descontinuidade na passagem apoio/retorno dos pés. O diagnóstico inicial está separado do resultado final. As duas ações de ataque usam arcos de articulação autorais, evitando singularidades do solver de braço nessa trajetória.

## Preservação artística

O GLB original tem SHA-256 `5037091e4b7aa3e1c765e55a40100f6c93fedd6d839fccab2f637e9aad0d4b4c`. O arquivo original e o ZIP recebido permanecem em `original/`, sem alteração. A V4 usa 214 triângulos; a versão articulada usa **374 triângulos, 23 malhas, 25 ossos e 1 material**. O aumento de triângulos decorre de divisões e tampas nas articulações; não foram recriados rosto, cabelo ou roupas.

Pixels RGBA da textura embutida idênticos aos do original; PNG externo preservado byte a byte. Vértices/UVs das dez peças não subdivididas auditados com tolerância de 1e-6, todos preservados. UVs finais finitos e em [0,1]. Oito triângulos de bainha foram removidos conforme autorização; restam os 32 triângulos originais de cabo/guarda/pomo.

Comparação em postura neutra, mesma câmera/escala/iluminação por par, usando a referência original com somente a bainha removida:

| Vista | Pixels diferentes — Godot, 960×540 | Pixels diferentes — Blender, 480×600 |
|---|---:|---:|
| 000° | 0 | 109 |
| 090° | 0 | 5 |
| 180° | 0 | 2430 |
| 035° | 2 | 116 |

A comparação Godot usa ambiente uniforme para auditar textura/silhueta; o original não fornece normais explícitas, e o GLB exportado fornece. Blender usa Cycles com amostragem baixa e superfícies de roupa/cabelo coplanares do original, produzindo diferenças de rasterização principalmente na vista traseira; seus valores completos estão no JSON. Não se afirma identidade de pixels no Blender ou sob toda iluminação direcional.

## Desempenho medido fora do modo de gravação

Após aquecimento, **180 quadros** em **2.342 s**, média de relógio **76.85 FPS**, delta médio de processo **13.014 ms**, **37.0 draw calls** na cena inteira. Driver: **llvmpipe (LLVM 19.1.7, 256 bits)**, renderização por CPU/software. Não houve outro teste gráfico ou codificação de vídeo concorrente durante essa medição. O monitoramento anterior, com sombras dinâmicas, está em `benchmark_before_shadow_optimization.json` para comparação.

Esses números pertencem a este ambiente e a este ensaio, sem representar previsão de FPS em PCs comerciais ou Android. O vídeo MP4 tem 60 quadros/s por gravação determinística do motor, independentemente da velocidade de renderização; não é o benchmark. O AVI original pode ser reproduzido pelo comando documentado e permanece localmente; foi excluído do ZIP para evitar duplicar dezenas de MB.

## Não testado ou incompleto

- **Godot 4.7.2 / Android / Windows nativo:** não disponíveis para testes; não há alegação de validação nem APK/EXE exportado. O projeto roda pela Godot; foi testado no Linux com a versão informada.
- **Arma completa:** original sem lâmina. O cabo é preservado e transferido entre mãos; o teste de alvo não prova alcance/colisão de uma espada completa.
- **Jogabilidade final:** sem inimigos, IA, multiplayer, progressão, mundo final ou integração ao projeto EXO principal. O alvo não ataca; H é um comando de teste de reação.
- **Contato físico:** teste de distância/cone, não sweep de lâmina ou hitboxes de cada membro. Sem física de tecido/cabelo, IK de terreno, sistema completo de pé plantado em runtime ou correção de autointerseções em qualquer combinação. Não foi validada ausência de todo cruzamento de malhas nas poses extremas.
- **Modularidade:** contratos e slots preservados; sem editor, novos corpos/rostos/roupas, LODs ou testes de altura. A API experimental de escala não é exposta ao jogador.
- **Direção de animação:** ações criadas localmente, sem animações comerciais externas. A intenção é uma base mais contínua e responsiva; não se declara o nível final de uma produção Murim aprovado pelo usuário.

## Evidências

- `captures/EXO_MURIM_V3_GAMEPLAY.mp4`: execução contínua; somente conversão de AVI para H.264 e encerramento antes dos quadros técnicos de auditoria, sem cortes internos da sequência jogável.
- `captures/sequence_*.png`: quadros reais da sequência.
- `captures/compare_godot_*.png`, `compare_blender_*.png`: comparação neutra.
- `logs/gameplay_graphics.log`, `gameplay_validation.json`: execução gráfica e resultados.
- `logs/render_benchmark.json`: medição em tempo real, sem passo fixo.
- `logs/godot_import.log`, `blender_prepare.log`, `final_asset_audit.json`: importação, fonte e auditoria.

Texturas e geometria: pacote original do usuário, com sua declaração de proveniência preservada. Movimento, cenário e efeitos de treino produzidos localmente; nenhum asset de terceiros foi acrescentado.
