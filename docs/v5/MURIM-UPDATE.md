# Mundo, fauna e combate Murim

## Correções de geometria e acesso

A muralha externa usava apenas lotes e pequenos objetos para calcular o perímetro. Os recintos monumentais ficavam fora desse cálculo, permitindo a muralha atravessar o pátio e fechar sua porta. Fortifications agora recebe os planos monumentais aprovados pelo WorldGenesis e inclui todos os cantos dos limites protegidos, com margem. As aberturas de estradas e rios continuam sob o planejamento e validação originais; a correção não remove a muralha nem abre passagens cegas em colisores.

O caminho físico de acesso aos mestres também tinha um defeito: o grafo aceitava o topo de paredes como piso, escolhia essa rota curta e a rejeitava depois pelo salto de altura. Agora os desníveis intransponíveis são excluídos antes da busca. A malha de aproximação usa resolução de 1m, envelope de 0,65m e prova final por varredura de cápsula. Personagens dinâmicos são excluídos da certificação da geometria permanente. O mesmo sistema continua dono das rotas; não há teleporte para simular acesso.

A validação inclui as cidades 101/14, 707/7 e 816204/32 e passa pelo acesso real da rua à entrada, além dos mestres que existem nos sítios gerados. O tipo de monumento pode variar com o contexto autoral do mundo; um forte não é contado como escola. O teste world_regions verifica a existência de rota física para cada recinto marcial da amostra.

## Fauna nos campos e arredores

Regional Ecology continua o único dono de spawn, respawn, identidade, derrota, experiência, loot e persistência. Bestiary fornece espécies, biomas, comportamento e visuais. Nenhum ator paralelo foi instalado.

- Até 8 territórios de fauna em região selvagem, 4 nos arredores de assentamentos e 3 em ruínas/aproximações de masmorra, conforme espaço permitido.
- Campos respeitam rios, lotes, estradas, terreno, outros territórios e o interior da muralha. Em assentamentos a procura alcança os arredores da região, sem ficar restrita ao centro urbano.
- Lobos e lobos corrompidos chegam em grupos novos de pelo menos três. Cervos, coelhos, cabras, bois e búfalos usam grupos de dois; espécies solitárias usam um.
- Todos os membros sobreviventes do grupo têm piso, distância, visibilidade e orçamento verificados antes de confirmar qualquer nascimento. Uma matilha nova não é cortada para um lobo por falta de espaço/orçamento. Membros mortos são preservados pelo estado existente, sem ressuscitar automaticamente para completar três.
- Limites separados de 16 animais e 8 hostis, limite de 24 atores físicos geridos pela ecologia na região ativa. Fauna tem prioridade de montagem e não perde todas as vagas para bandidos. Nascimento permanece fora da tela; despawn distante não conta como morte ou recompensa.
- O visual genérico de substituição P0 deixava espécies diferentes com a mesma silhueta marrom e ocultava a anatomia própria do bestiário. O adaptador agora preserva o visual procedural autoral por família quando o substituto é genérico, incluindo focinho, cauda e pernas animadas. Assets externos excluídos continuam fora da build.

## Terreno em blocos

O shader compartilhado recebe linhas discretas em quadrados de 1m, derivadas da posição no mundo. A malha visual usa antialiasing e desaparece gradualmente à distância para reduzir cintilação. O parâmetro é preservado pelos três filtros de textura. Texturas de grama, terra, pedra e suas máscaras de transição continuam presentes; a malha não altera relevo, navegação ou colisões.

## Combate e táticas executadas

A integração anterior lia propostas do Bestiary, mas praticamente só autorizava short_slash; as posições de cerco não eram executadas. O host agora consome papéis, destinos e vagas de ataque do serviço bestiary.tactics, e os atores físicos executam aproximação, flanqueamento, separação e manutenção de distância. Até dois oponentes recebem ataques simultâneos no grupo próximo, com prioridade rotativa e validação de estado, alcance e linha de visão.

Arqueiros equipam arco, recuam quando pressionados e disparam projéteis físicos. Flanqueadores recebem posições laterais. Combatentes ocupam posições distintas ao redor do jogador. As propostas continuam consultivas: enemy.gd e PlayerCombat mantêm a autoridade de executar dano. Arcos, golpes e técnicas passam a respeitar também os sólidos na camada 4, inclusive muralhas; personagens não viram paredes artificiais no teste de linha de visão. O teste dispara uma flecha contra um obstáculo e outra contra o jogador desobstruído para verificar bloqueio e impacto reais.

O jogador mantém mais velocidade durante golpes, usa combos com botão mantido e janela maior de encadeamento. A duração do ataque básico foi reduzida em 14% antes dos modificadores já existentes. Esquiva e técnica podem cancelar a recuperação após o impacto; antecipação, energia, recarga, invulnerabilidade e custos continuam validados pelos seus donos existentes. A direção do golpe comprometido continua legível.

## Batalha dos doze

Os onze oponentes do jogador agora alternam alvos, aproximam, recuam, orbitam e separam seus corpos. A pressão sobre o jogador gira entre subconjuntos de heróis a cada quatro segundos, quebrando duelos isolados nas bordas da arena. Usam as técnicas dos próprios arquétipos de Catalog.HEROES, com execução física no ator do prólogo: projéteis, sequência canalizada, cortes/área, salto/investida, escudo, cura, controle, armadilha persistente e guardião temporário que se move e ataca. Esses executores NPC são limitados à batalha do prólogo; não gastam recursos nem concedem progressão pela autoridade do jogador.

Os efeitos usam o VFX Forge já integrado, por autorização explícita do host para atores vivos e técnicas pertencentes ao respectivo arquétipo. As sequências de lançamento são únicas por batalha/replay. Sons de preparação, lançamento, arma e impacto usam o mixer e os eventos existentes do Sound Forge. Não foi criado outro serviço de áudio nem importada arte externa.

A validação nativa observa deslocamento dos onze, lançamentos, projéteis, canalização, armadilha, salto, guardião físico, eventos de áudio e efeitos recebidos pela ponte VFX. Contadores e resultados reais estão nos logs; o número de lançamentos pode variar com o combate. Reprodução por AudioStreamPlayer/driver Dummy verifica integração, não a experiência auditiva de um aparelho físico.

## Direção Murim e pesquisa

A revisão usa o universo marcial como organização de mundo: seitas e clãs, linhagens, mestres/discípulos, manuais, treinamento e cultivo de energia interna. Referências conceituais incluem qi, meridianos/dantian e passos leves; esses termos orientam a linguagem sem substituir o cânone fantástico já próprio do EXO. A escala sobrenatural dos doze é mantida pelo prólogo.

Foram examinadas as 9 escolas, 12 estilos e métodos de treino existentes, além dos arquétipos e técnicas. Os nomes exibidos de técnicas genéricas foram aproximados do cultivo: Dardo de Qi, Barreira de Qi, Tração de Qi, Corte de Abertura e Circulação Restauradora. Os IDs e dados de custo continuam estáveis. Os nomes espelhados pelo Skill Forge foram sincronizados, mantendo sua validação de compatibilidade, em vez de enfraquecê-la.

A tentativa de consulta externa ao resumo Wuxia recebeu HTTP 403 na política de rede deste ambiente. Ela está registrada em murim-update-inputs.json e não foi apresentada como fonte consultada. Esta rodada contém pesquisa interna e revisão conceitual; uma bibliografia externa verificada permanece pendente.

## Evidência e limites

Os resultados finais, comandos, logs, capturas OpenGL reais, diff e hashes por arquivo acompanham o ZIP QA. Os primeiros testes que falharam permanecem identificados como históricos. A extração final deve importar e executar as suítes na engine oficial Godot 4.6.2; compilar sozinho não constitui a validação deste trabalho.

A amostra cobre os casos reportados e regressões existentes, não todos os mundos possíveis ou sessões indefinidas. Windows/Android, desempenho na GPU alvo, equilíbrio com jogadores e saída de áudio física exigem validação nesses aparelhos. Comprovação comercial dos recursos autorizados pelo proprietário continua pendente conforme os manifestos anteriores. Esta entrega não declara homologação comercial.

Extraia em pasta nova e crie uma nova jornada para avaliar a revisão completa. Não sobreponha o ZIP antigo.
