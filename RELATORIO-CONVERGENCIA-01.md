# EXO-MURIM — CONVERGÊNCIA 01

Versão: C01.1 • Godot 4.6.2 Standard • Compatibility • validação de 18/10/2026.

**Resultado: versão-fonte integrada e jogável, candidata à validação humana.** A integração nova passou em 91 verificações; a regressão histórica completa ainda apresenta falhas. Não há aprovação irrestrita do jogo inteiro.

## O que foi entregue

O jogo inicia no fluxo original de seleção dos 12 heróis, prólogo e criação. O recinto inicial mantém personagem, serviços, inimigos, missões e coordenadas aprovadas. Uma passagem física em (0, 0, 43) conecta esse recinto às 88 regiões externas; o recinto fica fora dessa contagem. As passagens externas usam o grafo persistido. O sinal no centro de cada exterior permite voltar ao recinto.

`convergence/game.gd` estende o `main.gd` original, sem reescrever o controlador. Genesis decide terreno, lotes e ruas. Forja monta cada construção sobre o lote correspondente. Living World fornece as identidades, apresentadas por CharacterBody3D com rig Minecraft, animação, deslocamento físico e conversa por E. A população é de **um morador por edifício**, não uma população urbana completa.

Preservados byte a byte frente à base: main.gd, rig.gd, arsenal.gd, animation_library.gd, wardrobe.gd, combat/player_combat.gd e catalog.gd. Arquivos de integração alterados e hashes das quatro entradas estão em `convergence/validation/`. As entradas foram extraídas separadamente e permaneceram intactas.

## PASS / FAIL / NOT_RUN

| Sistema | Estado | Evidência e limite |
|---|---|---|
| Importação e início renderizado | PASS | Godot 4.6.2; cena principal integrada; seleção inicial capturada |
| Grafo das 88 regiões | PASS | 2.048 mundos nativos, 180.224 descritores planejados; não são 180.224 cenas 3D |
| Atlas e seeds herdados | PASS | Atlas LAB2 101 e 816204 preservados; seed textual sem conversão destrutiva para float/int64 |
| Planejamento de assentamentos | PASS | 55 seeds, 1.265 assentamentos, 20.910 lotes na Godot; 10.000 casos sintéticos GDScript, 224.932 lotes adicionais |
| Geração 3D integrada | PASS | 13 exteriores em três seeds, incluindo oito assentamentos; **171 casas de 171 previstas**, com 171 NPCs materializados |
| Forja 02 | PASS | 12.000 lotes, 104.502 verificações, dez montagens da suíte original; compatibilidade efetivamente executada em 4.6.2 |
| Portas e acesso ao terreno | PASS | Cápsula, raios de suporte e caminhada através de cada porta nos 171 edifícios testados |
| Sete pilotos | PASS | 32, 46, 52, 61, 63, 78 e 86; caminhada física entre centros e portais, ida/volta; erro anterior de seed uint64 corrigido |
| Superfície e fundações | PASS | 36.513 raios de terreno, 216 pontos de fundação; erro máximo de superfície ~0,00053 m no roteiro herdado |
| NPCs físicos e interação | PASS | Rigs e colisão contra terreno/estruturas; movimento observado nos oito assentamentos; conversa por E e vínculos estáveis |
| Identidades, região e recarga | PASS | JSON e novo processo Godot; região restaurada e 35 moradores físicos com identidades correspondentes no teste de reabertura |
| Combate, saque e inventário | PASS | Ataque por Input, dano, derrota, saque regional, coleta e recarga. Fixture declarada: adversário existente parado com 1 PV |
| Missão legada, menus e movimentação | PASS | 14 verificações em sequência renderizada: correr, saltar, esquivar, técnicas, dano, ruínas, inventário e menu único |
| Living World lógico | PASS | 4.281 verificações depois de corrigir números inteiros após JSON |
| Desempenho | PASS | Medições sequenciais reais abaixo; aprovação de orçamento no PC do proprietário ainda pendente |
| Regressão histórica completa | FAIL | Suítes antigas ainda têm asserções incompatíveis e alertas de encerramento; detalhes abaixo |
| Sessão humana / Windows / Android | NOT_RUN | Nenhum teste humano, exportação Windows/Android ou benchmark no PC do proprietário |
| Todas as 88 cenas, todas as seeds | NOT_RUN | Grafo inteiro validado; cenas 3D limitadas à amostra explicitada |
| Comércio, contratos Living na interface, interiores e escadas entre pisos | NOT_RUN | Não integrados nesta entrega; testes lógicos não os transformam em sistemas jogáveis |

## Cenas realmente montadas

“Objetos” nos locais sem assentamento são marcos/ruínas já existentes; não são casas faltantes.

| Seed | Região | Casas previstas | Construções / marcos instanciados | NPCs |
|---|---:|---:|---:|---:|
| 101 | 32 | — | 3 | 0 |
| 101 | 46 | — | 1 | 0 |
| 101 | 52 | — | 1 | 0 |
| 101 | 61 | — | 1 | 0 |
| 101 | 63 | — | 1 | 0 |
| 101 | 78 | 43 | 43 | 43 |
| 101 | 86 | 4 | 4 | 4 |
| 707 | 2 | 9 | 9 | 9 |
| 707 | 10 | 12 | 12 | 12 |
| 707 | 7 | 41 | 41 | 41 |
| 816204 | 6 | 6 | 6 | 6 |
| 816204 | 7 | 21 | 21 | 21 |
| 816204 | 32 | 35 | 35 | 35 |

## Correções verificadas

1. **Assentamentos incompletos no pacote de entrada:** quatro regiões falharam no teste real de cinco seeds, apesar do stress sintético passar. A busca e o terraceamento foram corrigidos e versionados. A reexecução ampliada passou.
2. **Ruas íngremes:** o diagnóstico inicial encontrou 381 amostras acima de 65% de inclinação, em cinco regiões da seed nativa 101. Terraços cívicos nivelam a área de assentamento; rampas conectam as saídas. O diagnóstico repetido retornou zero. Esse ajuste torna o relevo central mais plano e requer avaliação artística humana.
3. **Integração de parcelas:** envelope local de 10,8 × 10,8 m cabe no pad do Genesis. A rotação arbitrária é aplicada ao root consumidor; não arredondamos a direção da fachada. Regiões recusam planos/construções inválidos explicitamente, sem omitir casas.
4. **Limite de loteamento da Forja:** cidades excedem 32 prédios. Cada lote é validado e montado individualmente dentro de uma transação regional; a contagem final é comparada ao plano inteiro antes da troca de região.
5. **Seeds grandes:** o atlas LAB2 contém seeds regionais além de int64 com sinal. A Forja recebe `seed_mod`, preservando o texto original; int() direto foi removido.
6. **Persistência Living:** JSON transforma números em float. A extensão restaura inteiros exatos antes da validação; a carteira e os moradores agora sobrevivem à recarga. A raiz do save continua v4; a extensão de convergência é schema 1 / regional_version 4.
7. **Saque regional:** y e região são persistidos. Bolsas não ficam enterradas no terreno nem aparecem em outro exterior. Reutilizamos os mesmos seis adversários e fontes únicas de recompensa da campanha; não criamos novos tipos de inimigo.
8. **Preservação de atividades:** pátio de testes e revisão do prólogo exigem retorno ao recinto. Retomar um marco depois de uma derrota externa retorna ao terreno correto.
9. **Custo visual:** malhas estáticas da casa são combinadas preservando materiais, UVs e colisores. Cobertura/piso superior podem sumir perto do jogador para permitir enxergar o interior acessível; não há sombra dinâmica nova.
10. **Mapa e textos:** a mesma superfície de mapa recebe ruas, lotes, moradores e portais da região ativa. Não há novo menu aninhado. Conversas usam nomes e profissões em português.

Os testes antigos de empunhadura usavam o ponto de mão do braço anterior. A medição foi atualizada para a ponta do antebraço articulado; o desvio real observado ficou abaixo de 0,000001 m. A fixture de vestimenta passou a escolher explicitamente o traje com painéis. A mecânica de poção passou em teste isolado e no fluxo integrado; os testes mantêm o efeito real de +40 limitado pela vida máxima.

## Desempenho medido

Linux, CPU apresentada pelo host: AMD EPYC 9V74; GPU **llvmpipe por software**, OpenGL Compatibility. Resolução 1152×720, perfil Equilibrado, câmera com tamanho 36, 15 quadros de aquecimento e 40 amostras, sem fixed-fps. Processos e condições sequenciais. Inimigos desativados no benchmark; moradores externos ativos.

| Condição | Quadro médio (ms) | P95 (ms) | Memória estática Godot (MiB) | Draw calls observadas |
|---|---:|---:|---:|---:|
| Base 09.4.6 | 69.57 | 86.84 | 67.6 | 403 |
| Recinto integrado | 65.07 | 72.22 | 70.1 | 405 |
| Aldeia 86: 4 casas / 4 NPCs | 47.93 | 51.72 | 123.5 | 163 |
| Cidade 78: 43 casas / 43 NPCs | 50.79 | 66.05 | 230.6 | 84 |

A memória estática não representa toda a RAM/RSS do processo; memória de vídeo e contadores brutos constam nos JSONs. Os monitores de tempo interno têm janela de atualização e podem incluir efeitos da geração inicial; os tempos de quadro são medidos diretamente entre frames. A câmera pode mostrar quantidades distintas de objetos em cada local; draw calls não medem todo o custo da cidade.

Aldeia: 1.80 s de geração/troca; cidade: 4.31 s. Incluem construção, sincronização física e persistência do roteiro. O recinto integrado permanece próximo da base no custo de quadro e memória; a cidade mantém muito mais nós e recursos. Isso não prevê FPS em Ryzen/Windows e não constitui aprovação de desempenho mobile.

## Problemas que permanecem

- **Regressão histórica não limpa:** `tests.gd` inicialmente registrou 206 verificações aprovadas e sete falhas em cascata: a fixture usava a coordenada antiga da Guilda. Corrigida para a âncora física atual, a suíte executou **213/213**, incluindo recompensa, descanso e recuperação do backup. `martial_qa.gd` mantém 39 aprovadas e duas falhas (palma/limite). `stabilization_qa` ainda espera quatro edifícios e IDs de um layout anterior. Esses resultados não foram apagados nem convertidos em PASS.
- Algumas suítes antigas encerram com recursos ainda em uso mesmo imprimindo verificações aprovadas; procedural_qa executou 47/47, porém recebeu **FAIL de execução limpa** por esse motivo. O mesmo vale para testes históricos de terreno/prólogo com alertas de encerramento. A suíte assets_qa não concluiu na tentativa headless e continua **NOT_RUN completo**. Não há evidência de que todo esse conjunto histórico esteja adequado à base atual.
- Moradores seguem percursos externos curtos entre fachada e rua; à noite voltam ao ponto externo de moradia. Trabalho e moradia usam o mesmo edifício nesta versão. Não entram em casas, não cultivam itens de verdade e não formam famílias, comércio, caravanas ou combate social. NPCs não bloqueiam o jogador; colidem fisicamente com terreno e estruturas.
- Contratos, reputação e carteira Living mantêm seus testes lógicos, mas não há interface integrada de economia/entrega de contratos. A carteira legada e os seus invariantes foram preservados.
- Lotes de 11 m não comportam o pátio de 19 m da Forja. As formas L/pátio do descritor não recebem uma planta correspondente nesta integração; casas equivalentes mantêm a contagem e a função externa. Hospedarias podem ter dois pisos visuais, sem escada/interior navegável superior.
- Terraços e distribuição regular das casas ainda precisam de polimento artístico. Aldeia/cidade diferem em quantidade, funções e perfis das construções; não há muralha urbana nova nem edifícios monumentais.
- As passagens carregam uma região de cada vez e podem parar por alguns segundos. Não foi implementado streaming contínuo nem pré-carregamento automático.
- O ZIP é um **projeto-fonte jogável na Godot**, não um executável Windows exportado. Sessão humana, audição estética, animações em todos os ângulos e dispositivos reais permanecem pendentes.

## Reproduzir e conferir

Abra project.godot na Godot 4.6.2 Standard, aguarde a importação e use F5. Não abra a cena `genesis/demo.tscn` como se fosse a versão integrada: ela é um laboratório histórico.

Para um novo gate de engine:

```sh
python3 tools/run_convergence_checks.py /caminho/para/godot
```

A sequência renderizada preservada está em `convergence/legacy_playable.gd`; capturas em `convergence/capture.gd`. Benchmarks: `godot --path . --script res://convergence/benchmark.gd -- base` e modos home/village/city. Executar benchmarks sem outros processos de teste. As capturas de inspeção usam câmera afastada e posicionamento direto do jogador; não são prova de caminhada humana. A prova de caminhada automatizada está no log/JSON do piloto.

Logs completos de falhas iniciais, correções, regressão e medições estão em `convergence/validation`; JSONs de runtime e capturas reais estão em `convergence/`. Relatórios dos módulos de entrada são históricos e ficam preservados, incluindo os avisos originais de testes não executados.
