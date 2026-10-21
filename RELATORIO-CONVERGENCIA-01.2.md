# EXO-MURIM — CONVERGÊNCIA 01.2

18/10/2026 • Godot 4.6.2 Standard • Compatibility

## Resultado e base

Continuação direta de **EXO-Murim-Convergencia-01.zip**, sem reiniciar a integração. Projeto-fonte completo para abrir na Godot e executar com F5. Não é um executável Windows exportado.

**Resultado dos gates executados: 43/43 PASS.** A extração limpa está registrada separadamente abaixo. A amostra física aprovou **315 construções de 315 planejadas**, em 11 assentamentos; com os cinco exteriores sem assentamento, foram 16 regiões físicas em cinco seeds. A população máxima materializada foi **72 NPCs simultâneos**, respeitando o teto. Estes números descrevem a amostra, não todas as regiões ou seeds possíveis.

O jogo preserva o recinto inicial e o fluxo dos 12 heróis, prólogo e criação. A passagem do recinto conecta o jogador às 88 regiões externas. O grafo, os atlas LAB2 e os IDs dos lotes não foram substituídos.

Base e SHA-256: `convergence/preservation012.json`. Referências de engenharia consultadas: implementações de Genesis 05, Forja 02 e Living World incorporadas à C01, seus contratos, relatórios e testes. Não houve uma segunda integração a partir dos ZIPs anteriores.

## Alterações implementadas

### Arquitetura e mundo físico

- Adaptador `convergence/architecture.gd` identifica funções explicitamente. Função desconhecida é rejeitada; não cai silenciosamente em residência.
- Residências e fazendas usam a base residencial; ferraria usa a montagem de forja; curandeiro usa a loja de ervas; mercado usa a montagem comercial; hospedaria usa o modelo de dois pisos. Administração, santuário, depósito e escola recebem composições próprias com peças existentes, identificadas por `semantic_function` e `composition`.
- Escola marcial tem espaço de treino, poste de madeira, estandarte e identificação; santuário recebe incensário e lanterna; administração recebe balcão e estandartes; depósito recebe provisões e carro de mão; fazenda recebe canteiro e cultivos.
- Perfis médios de detalhe, cinco paletas, larguras de 4/6/8 m e variações de fachada/telhado continuam determinados pela seed. As composições ficam no sistema modular aprovado.
- A restrição de 10,8 × 10,8 m foi investigada. Escola/santuário podem reservar **10,9 × 19,2 m**, deslocados para trás da fachada, quando o terreno existente é plano e a reserva respeita ruas, rios, lotes, infraestrutura e acessos. Se a reserva não cabe, a composição compacta é registrada explicitamente.
- O planejador Genesis, o terreno e as ruas não foram reescritos. As reservas adicionais são conferidas antes de consumir a geometria. O teste adicional aprovou 40 reservas de pátio em 115 assentamentos planejados, sem interseção entre os envelopes construídos em 25.802 pares verificados. Isso é planejamento geométrico, separado da amostra física.
- Corrigida a ocultação do telhado das casas deslocadas: o jogador agora é medido no espaço local da própria casa. A cobertura abre para visualizar o piso acessível e reaparece ao sair.
- Portas, materiais, batching estático e orientação arbitrária do Genesis permanecem ativos. Mapeamento semântico, posição, orientação e peça da profissão foram conferidos fisicamente nos 43 edifícios da cidade 78.

| Função Genesis | Apresentação integrada |
|---|---|
| residence / dwelling | Residência com variação modular |
| farmstead | Moradia com canteiro e cultivos |
| smithy | Ferraria com fornalha, bigorna e ferramentas |
| herbalist | Casa de medicina com ervas e recipientes |
| market | Comércio com cobertura e balcão |
| inn | Hospedaria de dois pisos visuais |
| martial_school | Escola com treino, estandarte e pátio quando reservado |
| administration | Administração com atendimento e estandartes |
| shrine | Santuário com incensário e lanterna |
| warehouse | Depósito com provisões e carro de mão |

**Limite arquitetônico:** os módulos de administração/escola/santuário/depósito reaproveitam o casco modular da Forja, com composição especializada. Não são quatro GLBs monumentais novos. A escola com pátio tem montagem real; não foi entregue uma biblioteca completa de plantas L/U. A malha viária ainda usa o desenho regular do Genesis e os terraços cívicos existentes. Não houve promessa de redesenhar toda a cidade.

### Ocupação e rotinas dos NPCs

- Capacidade residencial depende da finalidade, largura e número de pisos. Residências têm 2–4 vagas; hospedarias fornecem vagas; estabelecimentos especiais não recebem moradores automaticamente como se fossem casas.
- Os IDs originais são mantidos. Novos moradores usam slots próprios e estáveis. A população cresce no máximo cerca de 50% sobre os lotes, limitada a 72 personagens ativos.
- Moradia e trabalho podem ser distintos. Oficinas, comércio e cultivo recebem trabalhadores ligados às residências. Serviço/profissão e pontos físicos são registrados junto à identidade.
- Um grafo compartilhado de ruas é montado por região, incluindo interseções e conexões das fachadas. As rotas entre moradia, trabalho e convivência seguem esse grafo, em vez de atravessar quarteirões em linha reta.
- O NPC termina um deslocamento antes de assumir o próximo destino da agenda. Ao encontrar bloqueio, recua fisicamente e tenta novamente; não há teleporte de recuperação.
- Pontos pessoais de permanência distribuem moradores pelas fachadas e pelo espaço comunitário. Os nomes aparecem por proximidade. O olhar varia e o NPC se volta ao jogador ao conversar.
- A animação usa o rig Minecraft existente e a velocidade física efetiva. Moradores trabalhando usam pequenos movimentos de braços/tronco. Não foi criado outro rig.
- À noite, o morador retorna à entrada e registra um **proxy de abrigo**: deixa de ser exibido, com entrada/saída persistida. Não há navegação interna de NPCs sendo simulada ou anunciada como pronta.
- Identidade, moradia, trabalho, visitas e contagem de conversas sobrevivem à saída da região e à recarga. Saves C01 migram apenas os vínculos de ocupação, mantendo nome, atributos, aparência, profissão-base, facção e inventário.

**Serviços:** os vínculos, títulos e pontos profissionais estão integrados. Não foi criada uma nova interface de compra/venda, reparo, contratos ou fabricação nesses moradores. Os serviços legados continuam no recinto. Plantio/treino são rotinas e apresentações físicas; não há produção econômica ou colheita de itens automática.

### Desempenho e recursos

A primeira comparação encontrou custo elevado: a cidade C01.2 chegou a 68,16 ms por quadro, com 65 NPCs. Foram corrigidos dois gastos: avaliação completa de poses fora da câmera e varreduras físicas redundantes de moradores imóveis sobre terreno estático. A navegação continua física; moradores em deslocamento continuam atualizando fora da câmera.

A pose volta a ser avaliada quando o personagem entra no campo de visão. Textos de atividade são atualizados quando mudam. A suíte de rotinas foi executada novamente depois da otimização: 27/27 PASS, incluindo os 45 deslocamentos de trabalho, convivência, abrigo e recuperação de bloqueio.

O cache de materiais da Forja também foi corrigido: vários materiais importados têm nomes iguais, como `box`. A chave antiga misturava cores de peças distintas. A chave usa agora o caminho estável do recurso, preservando as cores e evitando crescimento a cada revisita. A reprodução na C01 falhou com duas cores de estandarte; a versão corrigida preservou três cores e manteve o cache estável em oito recriações.

## Auditoria das falhas anteriores

| Ocorrência | Classificação | Correção e revalidação |
|---|---|---|
| Palma sem articulação do cotovelo | Bug real | Correção local em `combat/unarmed.gd`; martial_qa 41/41 |
| Teste exigindo parede antiga em x=25 | Teste obsoleto | Fixture de obstáculo sólido real; verificação de parada física mantida |
| stabilization_qa exigindo quatro casas/IDs antigos | Contrato obsoleto | Contagem pelo plano vigente, IDs únicos e aproximação física; 47/47 |
| assets_qa sem concluir headless | Limitação de execução do teste de projeção/oclusão sem renderização | Execução renderizada completa; 30/30 |
| Limite fixo de superfícies de roupa | Teste obsoleto | Verifica redução real por agrupamento nas articulações atuais |
| Poção esperando pilha final sempre igual a 2 | Fixture incompatível com suprimentos por nascimento | Confere consumo de uma unidade e +40 PV limitado ao máximo; discovery_qa 38/38 |
| Salto de áudio falhando | Fixture sem garantir técnica equipada/piso | Técnica configurada pelo executor existente e personagem no anchor atual; 8/8 |
| get_meta de bainha inexistente gerando ERROR | Problema de teste | Consulta opcional com has_meta; asserções de ausência mantidas |
| Recursos Ogg em uso no encerramento | Desmontagem assíncrona da fixture | Para simulação/vozes, aguarda drenagem real e libera a cena; suítes reexecutadas sem ERROR/leak |
| Materiais novos perdendo diferenciação | Bug real do cache | Identidade estável por recurso; reprodução C01 e teste de revisita |
| Telhado de pátio deslocado não ocultava corretamente | Bug introduzido pelo novo posicionamento | Consulta no espaço da casa; seis verificações de piso/ocultação/retorno |

Os logs de tentativas que falharam permanecem na entrega. A primeira tentativa de martial antes de terminar a importação gerou recursos ausentes: foi uma execução inválida de preparação, não um bug aprovado do jogo. O arquivo `current_summary012.json` distingue os resultados finais das tentativas antigas. Não se deve ler um FAIL histórico como se tivesse sido apagado, nem usar uma linha PASS anterior a um erro como aprovação.

## Preservação

Comparação SHA-256 com o ZIP principal confirmou **11/11 arquivos protegidos idênticos**: `main.gd`, `rig.gd`, `arsenal.gd`, `animation_library.gd`, `wardrobe.gd`, `combat/player_combat.gd`, `catalog.gd`, `inventory.gd`, `journey_save.gd`, `murim_flow.gd` e `techniques.gd`.

Movimento/câmera, corpo articulado, equipamentos, criação/skins, prólogo, interface, inventário, progressão, técnicas e salvamento continuam nos controladores aprovados. A única alteração de combate é a correção de cotovelo no módulo de pose desarmada. A integração continua em uma subclasse de `main.gd`.

Versões: raiz de save v4; convergência schema 1; Genesis regional_version 4; Settlement 3. A apresentação usa architecture_version 2, rotinas 2 e migração de vínculos de ocupação 3. Não alteramos a geração de itens.

## Testes executados e estados

| Grupo | Estado | Resultado e limite |
|---|---|---|
| Extração limpa, importação e cena principal renderizada | PASS | Log e captura de inicialização em `validation012` / `evidence012` |
| Regressão histórica executada | PASS | 21 suítes gerais, mais assets com renderização; resultados finais e tentativas preservados |
| Suíte principal | PASS | tests.gd 213/213, incluindo recompensa, descanso e backup |
| Corpo/combate desarmado | PASS | martial_qa 41/41; quality09 71/71 |
| Fluxo jogável renderizado | PASS | 14/14: movimento, corrida, salto, esquiva, dano, técnicas, ruínas, inventário, recarga e menu único |
| Grafo determinístico conectado | PASS | 2.048 mundos nativos; 180.224 descritores de região planejados, não cenas 3D |
| Assentamentos em larga escala | PASS | 55 seeds; 1.265 assentamentos; 20.910 lotes |
| Extremos sintéticos na Godot | PASS | 10.000 casos; 224.932 lotes; zero hard failures e zero planos incompletos |
| Forja original | PASS | 12.000 lotes; 104.502 verificações; dez montagens físicas |
| Living World lógico | PASS | 4.281 verificações |
| Integração física representativa | PASS | 13 exteriores, 171/171 construções e 259 NPCs nas oito amostras de assentamento |
| Cidades físicas extremas | PASS | Três cidades com 48/48 edifícios e 72 NPCs cada; 144/144 portas/acessos aprovados |
| Tipos/posição/orientação/profissão | PASS | 43/43 prédios da cidade 78 com metadados e peças correspondentes |
| Reservas arquitetônicas | PASS | 115 planos; 40 pátios reservados; 25.802 pares geométricos sem sobreposição |
| Superfície e fundação | PASS | Sete pilotos; 36.513 raios; 216 pontos de fundação; erro máximo ~0,000528 m |
| Inclinação das ruas | PASS | Diagnóstico complementar da seed nativa 101: 9.262 segmentos, zero acima de 65% |
| Caminhada entre regiões | PASS | 25 trajetos físicos, ida/volta dos pilotos 32/46/52/61/63/78/86 |
| Rotinas após otimização | PASS | 27 verificações; 3/3 trajetos de trabalho na aldeia e 42/42 na cidade; convivência e abrigo dos 71 moradores |
| Bloqueio temporário | PASS | Recuperação por movimento físico e retomada após remover o obstáculo |
| Reabertura das rotinas em outro processo | PASS | 65 IDs únicos, conversas preservadas e save válido |
| Migração de save C01 em processos separados | PASS | 43 identidades originais mantidas; população nova 65; atlas e itens preservados |
| Combate/saque regional após otimização | PASS | Executor real, ataque por entrada, derrota, saque, coleta e recarga |
| Desempenho antes/depois | PASS | Seis processos sequenciais equivalentes; amostras brutas e RSS máximo registrados |
| Todos os 88 exteriores físicos / todas as seeds | NOT_RUN | Amostra física explicitada; não constitui cobertura universal |
| Sessão humana, audição, Windows, Android e PC do proprietário | NOT_RUN | Nenhuma aprovação presumida ou FPS estimado para esses ambientes |
| Interiores navegáveis de NPCs, economia social e comércio novo | NOT_RUN | Não implementados nesta etapa; associação de serviço não equivale a economia pronta |

### Seeds e amostra física

- Atlas LAB2 101: regiões 32, 46, 52, 61, 63, 78 e 86.
- Nativa 707: regiões 2, 10 e 7 — aldeia, vila e cidade.
- Atlas LAB2 816204: regiões 6, 7 e 32.
- Nativa 9007199254740993: região 48, cidade de 48 edifícios.
- Nativa 9223372036854775807: regiões 35 e 63, ambas com 48 edifícios.

Os atlas importados 101/816204 continuam diferentes do planejador nativo com seed numericamente igual. Os testes registram qual rota foi usada. Os casos extremos de terreno/rios e os contraexemplos do Genesis continuam cobertos nas suítes de assentamento, superfícies e caminhada.

## Comparação de desempenho

Linux; AMD EPYC 9V74 apresentado pelo host, nove CPUs lógicas expostas; renderização **llvmpipe por software**. Host compartilhado. Godot 4.6.2 Standard, Compatibility, 1152×720, perfil Equilibrado, câmera ortográfica tamanho 36, 30 quadros de aquecimento e 120 amostras, sem fixed-fps. Inimigos suspensos no benchmark; moradores ativos. Mesma cena/seed por condição; executáveis sequenciais, sem testes concorrentes.

| Condição | Versão | NPCs | Edifícios | Quadro médio (ms) | P95 (ms) | Memória Godot (MiB) | RSS máximo (MiB) | Geração/troca (s) | Nós |
|---|---|---:|---:|---:|---:|---:|---:|---:|---:|
| Recinto | C01 | 0 | 0 | 67.24 | 79.56 | 70.2 | 444.0 | 0.000 | 2451 |
| Recinto | C012 | 0 | 0 | 67.87 | 75.13 | 70.4 | 447.6 | 0.000 | 2451 |
| Aldeia 86 | C01 | 4 | 4 | 49.14 | 54.19 | 123.5 | 478.5 | 2.003 | 5698 |
| Aldeia 86 | C012 | 6 | 4 | 51.70 | 58.06 | 127.0 | 497.5 | 1.914 | 6063 |
| Cidade 78 | C01 | 43 | 43 | 55.21 | 67.17 | 230.6 | 620.9 | 4.341 | 21559 |
| Cidade 78 | C012 | 65 | 43 | 54.09 | 65.48 | 262.1 | 672.0 | 5.020 | 26156 |

A cidade passou de 43 para 65 moradores com quadro médio comparável no ambiente Work. Uma medição não comprova ganho estável de FPS; a diferença entre 55,21 e 54,09 ms cabe na variabilidade do host. O aumento de memória estática e de geração é real e deve orientar as próximas otimizações. O RSS é o máximo do processo Godot medido pelo sistema operacional; não é a soma com o Xvfb. Memória estática Godot não equivale a toda a RAM usada.

| Cidade 78 | C01 | C01.2 |
|---|---:|---:|
| Física média monitorada (ms) | 7,60 | 6,49 |
| Draw calls observadas | 79 | 111 |
| Nós | 21.559 | 26.156 |
| Memória de vídeo monitorada (MiB) | 90,8 | 101,0 |

P95 foi recalculado por nearest-rank a partir dos 120 quadros reais de cada execução. O JSON comparativo mantém também o valor inicialmente impresso pelo harness, que usava um índice uma posição acima; os logs brutos foram preservados. O harness entregue já usa o índice correto.

Os monitores internos têm janela de atualização e não isolam custo de GPU. Não há tempo exclusivo de renderização por GPU confiável neste renderizador de software. Quadros são medidos diretamente; dados completos em `benchmark_comparison012.json` e nos seis logs de comparação. A medição inicial mais cara está preservada em `validation012/pre_optimization`.

Não extrapolamos estes números para o Ryzen/Windows do proprietário ou para mobile. O benchmark do teto de 72 NPCs com renderização permanece NOT_RUN; a materialização e os acessos das três cidades de 72 foram testados fisicamente.

## Evidências visuais reais

Capturas produzidas pela Godot, sem imagem conceitual ou composição gerada por IA:

- `convergence/evidence012/aldeia-jogador.png`, `vila-jogador.png`, `cidade-jogador.png`: câmera normal do jogador, tamanho 15.
- `cidade-martial_school.png`, `cidade-shrine.png`, `cidade-smithy.png`, `cidade-herbalist.png`, `cidade-market.png`, `cidade-administration.png`, `cidade-warehouse.png`: funções arquitetônicas.
- Imagens `*-moradores.png`: NPCs materializados e atividades.
- `relevo-jogador.png` e `relevo-panorama.png`: piloto de relevo.
- `*-panorama.png`: complementos para inspecionar composição e vias.
- `antes-C01-cidade-*.png`: capturas reais da base com o mesmo roteiro e câmera para comparação.
- `fresh-main-menu.png`: inicialização da extração sem cache.

Posicionamento direto do jogador e relógio controlado são fixtures de captura/QA, não uma sessão humana. Os testes de portas e pilotos usam deslocamento físico, registrados separadamente.

## Reproduzir

Abra `project.godot` na Godot 4.6.2 Standard, aguarde importar e pressione F5. Use a cena principal `convergence/game.tscn`; `genesis/demo.tscn` é laboratório histórico.

```sh
python3 tools/run_convergence012_checks.py /caminho/Godot
python3 tools/run_convergence012_checks.py /caminho/Godot --rendered
Godot --headless --fixed-fps 60 --path . --script res://convergence/qa.gd -- extreme
Godot --path . --script res://convergence/capture012.gd
Godot --path . --script res://convergence/benchmark.gd -- city
```

`--rendered` precisa de display real ou virtual; não converter sua ausência em PASS. O primeiro comando gera o save de integração e o reabre no processo seguinte; as rotinas fazem o mesmo em seus dois executores. Os testes usam nomes de save exclusivos, separados de `journey.json`.

Para repetir a comparação sem alterar o jogo-base: use a cópia do harness `convergence/benchmark.gd` desta entrega como argumento absoluto de `--script`, mudando apenas `--path` entre a C01 extraída e a C01.2. Modos: `home`, `village`, `city`. Execute um processo por vez, sem `--fixed-fps`.

Para migração: execute `tools/fixtures/migration012_seed.gd` com `--path` apontando para a C01 original e passe como argumento o caminho absoluto de `convergence/migration_fixture012.json` da C01.2; depois execute `convergence/migration012.gd` na C01.2. O gerador cria um save de QA exclusivo. Não use o save pessoal como fixture.

As matrizes JSON guardam seeds, regiões, verificações e medições. Os comandos completos do gate executado ficam em `validation012/final/summary.json`; correções e reexecuções estão vinculadas em `validation012/current_summary012.json`. Arquivos de C01/09.x fora desta pasta são históricos.

## Limites e próxima atualização

1. Fazer a sessão humana no PC do proprietário: vila → trabalho dos moradores → outra região → retorno → salvar/fechar/reabrir; conferir câmera, animações e leitura dos serviços.
2. Medir ali o custo das cidades de 65/72 NPCs. O próximo alvo técnico é reduzir os nós estáticos remanescentes e o tempo de montagem/troca, que ainda pausa o jogo por alguns segundos.
3. Refinar a composição urbana e a integração dos terraços com o relevo em uma etapa versionada, preservando conectividade e acesso. O traçado regular foi mantido nesta entrega.
4. Evoluir fachadas/pátios especiais com avaliação visual humana. Plantas L/U completas, escadas para o piso superior e interiores de NPCs ainda não foram entregues.
5. Ligar os provedores profissionais aos serviços jogáveis existentes em uma etapa própria. Não expandir agora famílias, política, caravanas ou economia complexa.

Não foi detectado bloqueio crítico nos gates finais executados. Permanecem limites de cobertura, apresentação e funcionalidades futuras descritos acima; o relatório não afirma aprovação comercial completa ou aprovação humana.
