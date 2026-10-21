# Fortificações 02 R2 — integração da passagem fluvial

Data: 19/10/2026. Base: EXO-Murim-EXO-Core-01-CANDIDATO-CORRIGIDO.zip, preservada sem alterações em river_sources. Checkpoint Git local anterior às alterações: cc87e34.

## Resultado

PASS para a integração fluvial no escopo testado. As cidades reais 14 e 26, seed 101 do atlas canônico, constroem o perímetro com uma passagem fluvial cada. A água permanece sob a estrutura; a estrada recebe um tabuleiro independente. Não se usaram rios inventados ou uma cena isolada para aprovar esse fluxo. As imagens são capturas do viewport da Godot executando o projeto.

A aprovação integral da Convergência 02 como versão oficial continua NOT_RUN nesta revisão: esta entrega valida a correção fluvial e as regressões relacionadas, sem repetir toda a aceitação de gameplay, todas as variantes visuais e todos os benchmarks pedidos no escopo original.

## Correções implementadas

1. O planejador v4 reúne aberturas sobrepostas de estrada e rio no mesmo segmento reto. Um único responsável constrói o vão combinado. Não há dois portões ocupando o mesmo espaço. Curvas do perímetro, outros rios incompatíveis e fundações inseguras continuam sujeitos à rejeição.
2. A passagem fluvial v2 mantém apoios secos, vão oco, colisores separados das guarnições visuais, ameias e encaixes com as paredes existentes. A altura livre também considera estradas atravessando o vão. Os modelos Forja existentes continuam em uso nas conexões e torres.
3. O terraço cívico não preenche mais o canal físico. A malha visível e sua colisão usam a mesma superfície do leito. As estradas mantêm a cota aprovada em pontes com colisão no layer 1; a água continua por baixo, sem aterro sólido.
4. RegionalData passa de 5 para 6 devido à alteração semântica do terreno. O estado aceita versões regionais 4, 5 e 6 e rejeita 7. A raiz do save permanece v4; IDs, inventário, aparência e narrativa são preservados. O módulo architecture passa para 1.2.0.
5. As seeds 101 e 816204 usam os atlas canônicos fornecidos também nas suítes de fortificação. As versões anteriores dessas suítes regeneravam os atlas dessas seeds e não testavam o cenário efetivamente carregado no jogo.

O teste de fachada foi atualizado para aceitar a versão regional 6 e rejeitar a 7. No novo teste fluvial, a seleção do caminho rodoviário usa sua interseção com o vão da muralha: uma estrada pode acompanhar o rio sem cruzar a linha central da água. Nenhuma asserção de passagem ou suporte foi removida para ocultar uma colisão.

## Validação executada nesta revisão

| Verificação | Resultado | Evidência |
|---|---|---|
| Importação e compilação GDScript na 4.6.2 | PASS | final-import.log |
| Portões fluviais nativos | PASS | 52 verificações; cinco cidades com rio, quatro seeds; nenhuma bloqueada nessa amostra |
| Planejador de fortificações | PASS | 37.754 verificações, cinco seeds; zero planos parciais/pulados nessa amostra |
| EXO Core | PASS | 20 verificações |
| Assentamentos | PASS | 55 seeds; 1.265 assentamentos e 20.910 lotes |
| Integração física das cidades 14 e 26 | PASS | 18 verificações agrupadas; 78 sondagens no canal e 50 posições com cápsula real do jogador; suporte das pontes |
| Cidade 78 e portões existentes | PASS | 8 verificações de integração; passagem por todos os portões e piso |
| Física de terreno | PASS | 36.513 raycasts em sete regiões; 216 pontos de fundação; erro máximo 0,000528 m |
| Fachadas, acessos e identidade dos NPCs | PASS | 34 verificações |
| Processo interrompido durante save e recuperação | PASS | kill real antes da substituição; recuperação em outro processo, 8 verificações |
| Save/reload de cidade fluvial em novo processo | PASS | 14 verificações; terreno, NPCs, inventário, aparência, narrativa e XP preservados |
| Saves com versões regionais 4 e 5 | PASS | carregamento e dados do jogador preservados; raiz v4 mantida |
| Preservação de assets binários | PASS | 1.303 arquivos comparados ao ZIP original, zero modificações |
| Projeto extraído novamente do ZIP, importado sem cache e cidade fluvial reaberta | PASS | zip_import, zip_river_native e zip_runtime_reload |
| Sessão humana de navegação/combate | NOT_RUN | testes automatizados não são sessão humana |
| Benchmark de FPS/memória e regressão completa de combate/Jornada/Skin | NOT_RUN | não declarar aprovação global por estes testes focados |
| Todas as seeds possíveis / variante monumental em cidade física | NOT_RUN | monumental testada somente como unidade geométrica |

Logs e JSON atuais ficam em fortifications/validation_r2 e validation_r3/results. Resultados anteriores em outras pastas são históricos. As capturas atuais são exo_core/evidence/fluvial_integrated/01-passagem-fluvial-e-muralha.png e 02-muralha-cidade-escala-ampla.png: mesma cidade e região, em duas escalas.

## Ambiente e limites

Godot 4.6.2 Standard oficial, Compatibility/OpenGL, Linux x86_64, Mesa llvmpipe em display virtual X11; áudio Dummy. A captura e os testes usam fixed-fps 60 para execução reproduzível, sem alegar FPS medido ou previsão para o PC do proprietário. O aviso de V-Sync indisponível é uma limitação desse display; as execuções finais não contêm erros de script ou recursos ausentes.

Não foi alterado nenhum atlas, seed, grafo de 88 regiões, trajeto macro de rio, parcelamento, GLB, skin, controlador, arma ou animação. O relevo muda somente para preservar canais nos assentamentos; não se deslocam edifícios para fabricar uma travessia.

As proteções de banco seco, ângulo mínimo, vão máximo de 94 m e passagem por esquina permanecem. Um caso novo que não cumpra esses contratos continua explicitamente bloqueado; estes testes não garantem todas as seeds possíveis. A água mantém a apresentação existente e o cenário não recebeu polimento artístico geral.

## Uso e reprodução

Extraia o projeto completo, abra project.godot na Godot 4.6.2 Standard e aguarde a importação. A cena principal continua convergence/game.tscn. O PATCH é incremental sobre o candidato corrigido usado como base, não é um projeto independente.

Com a Godot no PATH, no diretório do projeto:

```sh
godot --headless --path . --script res://fortifications/qa_river_gate.gd
godot --headless --path . --script res://fortifications/qa_native.gd
godot --path . --audio-driver Dummy --fixed-fps 60 --script res://exo_core/tests/qa_fluvial_integration.gd
godot --headless --path . --audio-driver Dummy --fixed-fps 60 --script res://exo_core/tests/qa_fluvial_reload.gd
```

O terceiro comando exige renderização disponível, entra nas cidades reais e produz as capturas e um save exclusivo de QA. O quarto comando deve ser iniciado depois de o terceiro encerrar, em novo processo.
