# EXO-Murim — V4 Pré-WorldGenesis / Compatibility Checkpoint 01

**Candidato parcial de compatibilidade. Não é V4 final nem build de distribuição.**

A autorização do usuário em 20/10/2026, às 11h07 de Brasília, antecipou o início e substituiu a janela das 11h20. O lembrete foi desativado. O inventário foi congelado nas entregas disponíveis nessa autorização, incluindo Jornada Dinâmica 02 e VFX Forge 03. Audio/VFX Bridge continuou pendente: o TXT disponível é um prompt.

Base exclusiva: `EXO-MURIM-CONVERGENCIA-03-WORK-CANDIDATO-01.zip`, 248.199.526 bytes, 5.266 entradas, SHA-256 `abe7b5736140d91153e0e6f9343ef443d9ca526f78b636361355b2d895cb69f9`. ZIP e árvore original preservados; trabalho feito em cópia. Nenhum ZIP derivado City/Terrain substituiu a base. WorldGenesis V4 não foi desenvolvido ou integrado.

## Código aplicado

- Registro estrutural dos módulos opcionais, providers retidos pelo Core e versões de serviços alinhadas. Crowd 1.0.4 e Biblioteca 0.4.0 agora anunciam a versão correspondente ao manifesto. O binding privilegiado de VFX saiu da lista pública de métodos.
- Compilação: corrigida indentação mista do patch Jornada 02, função `signal` (palavra reservada) na Economy e tipo explícito do vetor `origin` no renderer Crowd.
- Skill Forge: validação aceita inteiros JSON representados como float somente quando finitos, integrais e limitados; frações continuam inválidas. O problema impedia carregar o catálogo inteiro na Godot real.
- City R4: metadados sobre os lotes C3, usando perfil adequado à escala. Planta, lotes, orientação, ruas e materialização existentes permanecem autoritativos. Conflitos com rio/monumento rejeitam a proposta e preservam o plano C3. Metadados City não concedem permissão física ao Crowd.
- Crowd R4: adaptador do materializador C3 consulta chão e cápsulas em todo o envelope de faixas retas conservadoras, depois do commit de viagem e da sincronização física. Somente faixas aprovadas recebem revisão da cena e recibo efêmero. Máximo quatro faixas de 12 m / 24 figurantes; na cidade 78 houve 16. Distância e horário continuam controlados pelo diretor Crowd. Figurantes não recebem UID Living World ou save.
- Viagem: `region_exited` é um evento preparado antes da gravação. O Crowd deixou de se desfazer nesse evento: sua remoção ocorre no host após sucesso da viagem. A falha de save preserva o mesmo container anterior.
- Economy: novo adaptador usa moradores Living World presentes, papel/função oficiais, horário 7h–20h, chão, distância de até 3 m e linha de visão. A interação existente E pode abrir opções de comprar/vender. O inventário oficial possui somente um callback privado de staging; não grava separadamente. Carteira única: `living_world.balances.bronze`. Moedas do legado não são alteradas.
- Economy: reseed exclusivo do criador, recusando apagar recibos/estoques/eventos; fronteira numérica de `next_item` compatível com JSON; estoque existente é clonado antes do staging. Isso corrige a segunda compra e impede mutação antecipada da loja. Preços/estoque/item/carteira/recibo passam juntos pelo SaveCoordinator.
- Biblioteca e NPC03: seleção autoral read-only e uma proposta de agenda são consultadas e guardadas como metadados por região. Não mudam identidade, narrativa ou movimento NPC02. Sem carregar a biblioteca por ator/quadro.
- Jornada 02: extensão aditiva no manager existente. Preserva os sete tipos legados, limites e autoridade única. Novas histórias permanecem propostas; aceitar/escolher/premiar exige host narrativo ainda ausente.
- Interior R2: biblioteca, builder e serviço de tickets instalados; 52 cenas instanciadas nativamente. **Portas novas e seleção persistida/transição de Interior Forge continuam bloqueadas.** Não houve escalonamento para forçar encaixes, reparent de jogador ou interiores falsos. Interiores institucionais/dungeons C3 continuam no host existente.
- Terrain R3: resolvedor e manifesto isolados, expostos como preview. **Materiais/shaders/texturas R3 não substituíram os aprovados na C3.** A troca física permanece pendente, inclusive revisão de proveniência herdada. Malha, UV e geração C3 preservados.
- VFX03: 10 receitas e serviço visual opcionais carregados; entrada não autorizada é recusada. Sem Bridge executável/autoridade de fases, não se habilitam efeitos ou áudios novos em habilidades.

## Verificação executada

Godot Standard `4.6.2.stable.official.71f334935`, Compatibility. Ambiente gráfico Mesa llvmpipe / LLVM 20.1.2, renderização por CPU. `user://` isolado para cada bateria; nenhum save pessoal usado.

| Verificação | Resultado final | Limite da evidência |
|---|---|---|
| Baseline C3 | 12 execuções PASS | Antes do merge |
| Regressão C3 após integração | 12 execuções PASS | Campanha, reabertura, loot, persistência, dungeon, Jade, estradas e atlas |
| Suítes legadas tools/run_checks.py | 12 suítes PASS | Testes herdados; controle/combate/inventário/assets/áudio/procedural |
| Parser nativo | 595 scripts, zero falhas | Compilação não executa cada ramo |
| Host V4 físico | 36 verificações PASS | Campanha nova, comerciante/UI, compra/venda e bloqueios |
| Host V4 reaberto | 35 verificações PASS | Segundo processo, recibos e novas transações |
| Save C3 anterior ao merge | 5 verificações PASS | Reabertura, região, população e serviço marcial |
| Economy R5 | 1.068 verificações PASS | Suíte nativa de domínio; complementada pelo comerciante físico |
| City/Crowd/Skill/Biblioteca/NPC03/VFX/Jornada02 | Suítes nativas PASS | Incluem harnesses/mocks de contrato; não equivalem a gameplay novo |
| Jornada 01 preservada | 4.053 verificações PASS | Ofertas/alcance/determinismo em duas seeds |
| Interior R2 | 52/52 layouts instanciados, sem falhas | Geometria; nenhuma porta nova homologada |
| Mundo | 352 regiões de dados validadas | Seeds 101, 816204, 707 e 18026; sem caminhada integral. Atlas 101/816204: 12 aldeias, 7 vilas, 4 cidades |
| Corredores C3 | Suíte física PASS | Regiões problemáticas selecionadas |
| Capturas | Cinco PNGs reais, novas | Viewport Godot, não mockups; áudio Dummy |

Os testes adversos do comércio cobrem duplicação, colisão de recibos, cotação vencida, segunda transação na loja salva, falta de saldo, inventário 24/24, falha real de caminho de gravação, recuperação após falha, distância e preservação das moedas legadas. A fixture recebe **10.000 Wen somente no QA** para testar compras; isso não foi adicionado à campanha do jogador.

Os testes do mestre/dungeon herdados usam fixtures automatizadas específicas. O teste Jade acelerado a 5 Hz não é benchmark. Desligamento abrupto durante commit, ciclo completo de NPCs, Android e audição estética permanecem NOT_RUN.

Tentativas falhas foram mantidas nos logs: primeiro merge, diagnóstico de parser/registry, caminho incorreto de um teste e tentativa gráfica sem driver de áudio. As execuções finais corrigidas estão identificadas em `QA-V4-PRE-WORLDGEN-01.json`. Não se usa uma linha PASS para ignorar erro de engine.

A medição gráfica final de 240 frames está em `evidence/benchmark-v4.json`: câmera ortográfica 15, cidade 78, seed 101, entrada automatizada e sem FPS fixo. É uma única amostra llvmpipe, sem comparação A/B ou extrapolação para Vega 8/Android. Memória estática Godot não equivale a RSS do processo inteiro.

## Uso e continuidade

Extraia o checkpoint completo em pasta nova e abra `project.godot` na Godot 4.6.2 Standard. Aguarde a importação e use F5. Compatibility permanece configurado. Comércio aparece por E junto a morador autorizado durante o expediente, com proximidade e piso válidos. Apenas ferro, poção de cura e espada comum possuem mapeamento; nove produtos são bloqueados.

Flags: City `authored_modular` acrescenta metadados; Crowd `enable=true` exige aprovação física em cada cena. Ambas podem ser desligadas para comparação. Skills autorais, novas transições Interior e VFX sem Bridge continuam bloqueados. Os saves e namespace da C3 permanecem os mesmos; faça backup ao alternar versões.

O checkpoint intermediário STAGE1 foi diagnóstico e apresentou falhas; **não é a versão recomendada**. STAGE2 conservou o primeiro host físico aprovado. O ZIP `...COMPAT-01-CHECKPOINT.zip` é a entrega integral vigente e inclui código, matrizes, logs e capturas. SHA-256 final e hashes de entrada acompanham o arquivo externo de hashes, evitando hash circular dentro do próprio ZIP.

Próximo passo: consumir as pendências e o contrato de interface anexo para desenvolver WorldGenesis V4 em etapa própria; depois executar outra integração completa. Este trabalho não declara beta final, export Windows/Android ou aprovação comercial dos assets herdados.

Medição final llvmpipe: 14.27 FPS médios; 1% low 8.47 FPS; P95 92.648 ms; P99 110.528 ms; 689 draw calls P95; 65 NPCs reais e 16 figurantes. Percurso automatizado acumulado: 59.97 m. Não é meta de desempenho aprovada.

A sequência gráfica legada `playable_validation.gd` passou em 14 verificações (combate, áudio acionado, exploração, save/reload e menu), com fixture declarada no log; isso não homologa todos os fluxos equivalentes da C3.
