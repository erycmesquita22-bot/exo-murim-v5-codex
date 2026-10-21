# EXO independente — regras de continuidade

Proprietário: diretor criativo. Assistente: direção técnica e integração.

Antes de alterar, ler LEIA-ME.txt, RELATORIO-09.2.md, TESTES-09.2.md e PRESERVACAO-09.2.json. Consultar RELATORIO-09.1.md para histórico marcial. Identificar a versão efetiva; trabalhar em cópia. Manter os identificadores de saves, itens, habilidades e personagens compatíveis.

## Decisões obrigatórias
- Godot 4.6.2 Standard, GDScript, Compatibility. Não trocar renderizador sem justificar e validar.
- Sombras suaves pintadas no chão em todos os perfis. Sol e lanternas sem sombras dinâmicas. Não ocultar os carimbos no Alto.
- Uma única estrutura de navegação EXO; não recriar menus aninhados.
- Não substituir controlador, rig, armas, animações, inventário, progressão ou salvamento aprovados sem demonstrar necessidade.
- Direção 09.3: corpo Minecraft 64×64 articulado. Modelo externo removido; não adicionar segunda apresentação.
- Casas com entrada local +Z, orientadas para o pátio. Colisões acompanham o root. Guilda, descanso e treino permanecem acessíveis por fora; não inventar interiores.
- Áudio de magia/Qi não reutiliza o efeito de esquiva. Contato depende de material e contexto; impacto não toca quando o golpe erra.
- Materiais externos precisam de origem, licença e registro das adaptações.

## Validação
Executar suites listadas em tools/run_checks.py; erro de script invalida execução mesmo se as asserções passarem. Rodar playable_validation.gd com renderização para alterações de fluxo. Benchmark somente em processos sequenciais, sem outros testes concorrentes, com mesmo ambiente, resolução e roteiro. Publicar métricas brutas e limites do equipamento.

Não tratar teste por entrada automatizada como sessão humana, gravação com FPS fixo como benchmark, nem ausência de erro como aprovação artística. Android e audição estética dependem de validação humana/dispositivo.

- Koto exclusivo da narrativa; nunca reutilizar em Qi, invocação, chefe ou missão.
- Meditação deve alinhar ao solo e mover fisicamente antes de sentar. Não simular AFK offline.

## Movimento 09.1
- Jogador: avaliar referência visual somente após ação/meditação. Não restaurar Run_Weapon como padrão de exploração.
- hands_free é modo independente de Manoplas, não item fictício. Preservar inventário/UID e compatibilidade de saves.
- Prioridades em combat/martial_motion.gd; não aplicar pose de equipamento rígida após o balanço livre.
- Manoplas fora de combate permitem braços livres, sem ocultar as luvas.
- Não prometer IK de terreno ou cabelo/roupa físicos: não foram implementados.

## Fundação procedural 09.2
- Geração v1 e suas regras são versionadas. Não editar semântica e reutilizar o mesmo número. Nunca rerrolar itens materializados ao carregar.
- UID local e instance_id do mundo devem permanecer estáveis. Derrota materializa; coleta move a instância completa. Preservar recompensas fixas, transações e limite de 24 espaços.
- Modificadores só do item equipado, suspensos em mãos livres. Não apresentar propriedades sem execução real.
- Registro audiovisual em audio/skill_registry.json: somente Salto Impetuoso integra originais nesta versão. Outros IDs preservam o áudio 09.1. Não redistribuir sons vanilla do Minecraft.
- Historicamente, na 09.2 a seed definia loot/encontros e vila/região permaneciam fixas. A 09.4 introduz terreno e lotes secundários por seed, sem alterar a semântica do loot de 09.2. Não apresentar streaming, NPCs procedurais completos ou multiplayer como implementados.
- Evidências 092 têm roteiro e fixtures explícitos. Reabrir em segundo processo para validar persistência. Sem aprovação humana ou Android presumida.

## Mundo 09.4
- O corpo, a personalização e os sistemas de arma 09.3.3 são congelados.
- A Guilda, o pátio, o leito e os marcos de missão preservam coordenadas e acesso.
- A seed do mundo é escolhida no criador, a região é reconstruída antes do jogo, e as recompensas de três marcos são eventos persistentes.
- `world.landscape_version=1` é independente da geração v1 de itens. Não reutilizar v1 caso o algoritmo de paisagem mude.
- `world/biome_plan.gd` é puro e determinístico. `world/landscape.gd` faz apenas geometria.
- Godot ainda precisa testar importação/visualização/colisões antes de validar a entrega.

## Level design 09.4.5
- Os layouts V2 mantêm as posições dos serviços/âncoras; alterações de apresentação não mudam a seed ou o schema dos salvamentos.
- `world/level_design.gd` apresenta ruas, lotes e decorações não colidíveis; NÃO adicionar props sólidos em caminhos de missão.
- `world/landscape.gd` fornece três caminhos exteriores com colisão baseada na superfície triangulada real do terreno; se mudar `height_at` ou `STEP`, conferir também `surface_height`.
- Testar `qa0945.gd` na Godot e caminhada humana nos serviços e nas três saídas. Testes estáticos não validam jogabilidade, arte ou FPS.

## Convergência 01
- Entrada canônica: convergence/game.tscn (subclasse do main.gd). O main.gd original continua preservado.
- O recinto inicial é separado das 88 regiões externas. Não remapear as coordenadas das missões legadas para os exteriores.
- Seeds 101/816204 usam os atlas LAB2 fornecidos; outras usam o planejador nativo. Não substituir os atlas importados pelo resultado do planejador nativo com seed igual.
- Convergence schema 1, regional_version 4; Settlement VERSION 3. Terraços cívicos e rampas foram corrigidos. Versionar mudanças semânticas futuras.
- Forja consome lotes de 10.8m, com rotação arbitrária do root no Genesis; seed textual é reduzida por seed_mod, nunca int() de uint64.
- Loot contém y/region; não deixar saques regionais aparecerem no recinto ou em outro exterior.
- NPCs usam layer 8 e colidem com terreno/estruturas. Agendas externas simples; não anunciar interiores, comércio ou contratos em UI como implementados.
- Relatório vigente: RELATORIO-CONVERGENCIA-01.md. Logs em convergence/validation. Relatórios 09.x/Genesis herdados são históricos.
- tools/run_convergence_checks.py executa o gate novo. Não considerar erros da engine aprovados por causa de uma linha PASS anterior.

## Convergência 01.2
- Base direta C01; controladores protegidos em convergence/preservation012.json continuam intactos.
- Genesis regional_version 4 / Settlement 3 preservados. Apresentação architecture_version 2; rotinas 2; migração de vínculos de ocupação 3. Não confundir estas versões com loot ou raiz v4 do save.
- Modelo-base Forja pode receber composição especializada. semantic_function/composition registram a função real; não anunciar a casa-base como escola sem os componentes especializados.
- Pátios expandidos somente após Architecture.can_expand: terreno existente, rios, ruas, lotes e acessos são restrições; sem expansão segura, composição compacta explícita.
- Rotas externas usam o grafo compartilhado Streets. Abrigo noturno é proxy registrado na entrada: não anunciar interiores navegáveis.
- Preservar IDs originais de moradores; novos ocupantes recebem slots próprios, capacidade de moradia e teto de 72 personagens ativos. Serviços registrados não equivalem a comércio ou economia jogáveis.
- Kit cache: nomes box/cylinder não identificam um material. Usar caminhos de recurso estáveis para manter cores e evitar crescimento em revisitas.
- Gate reproduzível: tools/run_convergence012_checks.py. --rendered exige display e executa assets/playable. Migração usa fixture gerada a partir do projeto C01 separado.
- Relatório vigente: RELATORIO-CONVERGENCIA-01.2.md; validações atuais em convergence/validation012. Resultados C01 e 09.x são históricos.

## Assentamentos e NPCs 03
- Base incremental: Refino Visual 02. Texturas/estrada e controladores protegidos preservados.
- RegionalData 5 / Settlement 4: aldeias e vilas usam candidatos de fachada e ruas cívicas mais curtas; contagens/IDs/88 regiões preservados. Cidades mantêm o layout anterior.
- State aceita versões regionais 4 e 5, inclusive números após JSON. Rotinas 3 descartam somente coordenadas/índice de percurso antigos; identidade, vínculos, visitas e conversas são preservados.
- Moradores estacionam em uma linha paralela à fachada, em duas alas separadas pelo acesso à porta. Não criar filas avançando para a rua.
- Visibilidade do corpo/nomes usa frustum e raios ortográficos contra terreno/construções; estados e deslocamentos externos continuam fora da câmera.
- Validação local: convergence/frontage_qa.gd; relatório e logs atuais em convergence/validation_frontage.

## EXO Visual 01 — candidato não validado nativamente (19/10/2026)
- Este projeto incorpora a base EXO Core 01 CORRIGIDO + patch Fortificações 02 R2 + a nova camada EXO Visual.
- Contrato: `visual 1.0.0` em `exo_core/modules.json`; serviços via `exo_visual/module.gd`. Não registrar domínio de save para preferências gráficas.
- `graphics.gd` é adaptador de compatibilidade para HUD, menu e efeitos antigos; o schema visual fica em `exo_visual/spec.gd` e usa `user://graphics.cfg`.
- Mantidas as texturas aprovadas em `textures/terrain_approved/*.png`; não substituí-las durante o QA. Importação solicita mipmaps; comparar qualidade com os mesmos arquivos originais.
- Scripts novos precisam ser abertos na Godot 4.6.2 Compatibility. As 23 checagens estáticas não substituem importação limpa, parse GDScript, compilação dos shaders, captura e regressão real.
- Execute `exo_visual/docs/ROTEIRO-WORK-QA-01.md`; marcar falhas reais como FAIL e testes impossíveis como NOT_RUN. Não reportar capturas anteriores do EXO Core como imagens novas do EXO Visual.
- Forward+ é experimental e só pode ser adotado depois de execução e medição real; não alterar o `project.godot` para Vulkan/Forward+ sem aprovação posterior.

## Cidade Viva 01 R2
- Base: candidato EXO Visual 01, com Core e Fortificações R2. Relatório atual: RELATORIO-CIDADE-VIVA-01-R2.md.
- A apresentação urbana é versão 2; budgets máximos aldeia 24 / vila 86 / cidade 180. Não são metas obrigatórias quando o espaço seguro é insuficiente.
- Preservar IDs, lotes, ruas, seed, 88 regiões e saves. Jardins usam a textura de grama aprovada, sobre malha conformada ao terreno; não reescrever texturas originais.
- Reservar fachadas dos moradores, pátios ampliados, ruas, acessos fluviais e o perímetro real. Raios devem conter as dimensões do catálogo; plantas colidem pelo tronco, pavilhões pelos pilares.
- Lanternas urbanas leem o relógio persistido do Core e não criam outro relógio. Sem sombras dinâmicas nas lanternas.
- Não anunciar bancas, hortas e novos anexos como economia, colheita ou interiores novos. As rotinas são as do Living World existente.
- Reproduzir cidade seed 101 / região 78; cidades fluviais 14 e 26. QA em cidade_viva/tests e resultados em cidade_viva/validation. Capturas novas em cidade_viva/evidence, com metadados.
- Benchmarks usam processo gráfico separado e não usam FPS fixo. O ciclo completo de NPCs usa a fixture acelerada qa_day_fast.gd a 5 Hz; o jogo permanece a 60 Hz. Não chamar esse teste de sessão jogável a 60 Hz. Retirar o limite de exibição da fixture headless não é medição de FPS.

## C03 — Work Candidato 01 / checkpoint de retomada
- Base exclusiva R13; estado e limites atuais em WORK_CHECKPOINT/RELATORIO-WORK-CANDIDATO-01.md. Leia esse documento e o manifesto antes de continuar. Não repetir merge desde uma base anterior.
- O checkpoint é parcial. As mensagens de uma execução interrompida não equivalem a arquivos recuperados. Ensino completo, armadilhas novas, mapa refinado e ciclo completo dos moradores permanecem pendentes conforme o relatório.
- Não remover validações físicas para materializar mestres. A aproximação local exige cápsulas; o Living World conserva autoridade de identidade e movimento.
- Godot 4.6.2: scripts e logs de testes atuais em WORK_CHECKPOINT/logs/current. Use tools/run_work_checkpoint_checks.py com o executável explícito. Erros de engine invalidam o resultado mesmo se houver PASS.

## V4 Pré-WorldGenesis / Compatibility Checkpoint 01
- Continuidade vigente em V4_CHECKPOINT/RELATORIO-COMPATIBILIDADE-V4-PRE-WORLDGEN-01.md, QA e pendências anexas. Não reiniciar o merge de uma base anterior.
- Base C3 preservada. WorldGenesis V4 não foi implementado; só contrato para próxima etapa.
- City R4 é semântica; Crowd exige recibo físico por cena, emitido após commit. Não voltar a remover apresentação em region_exited preparado antes do save.
- Economy usa carteira Living World e staging do Inventory dentro de um commit; apenas três bens. Não remover verificação de comerciante físico, horário, distância, quote/revisão e recibos.
- Interior novo, 168 skills autorais, histórias V4 e VFX sem Bridge continuam bloqueados. NPC02 mantém movimento e UID. Terrain R3 não substituiu assets C3 aprovados.

## WorldGenesis V4 — candidato integrado (20/10/2026)
- Continuidade vigente: WORLDGENESIS_V4/RELATORIO-WORLDGENESIS-V4.md e MATRIZ-C3-V4.md. Seções anteriores são históricas.
- Novas campanhas com flag worldgen_v4/new_campaigns_enabled usam generator 4 e regional_version 7, com atlas/perfis/templates congelados no JourneySave existente. Não remover marcadores para fazer downgrade.
- Grafo de 88 regiões preservado. Saves anteriores continuam pela geração legada. Sem novo dono de persistência, economia, NPCs ou combate.
- WorldGenesis confirma a geometria física; City R4 continua semântica e NPC03 consultivo. Interior novo, Terrain R3 visual, histórias/skills/VFX sem hosts continuam bloqueados segundo a matriz.
- Runner nativo: tools/run_worldgen_v4_checks.py EXECUTAVEL_GODOT. Reaberturas precisam de processos separados. Evidência atual em WORLDGENESIS_V4/evidence; QA antigo preservado nos diretórios históricos.
- Não iniciar Convergência V4 final sem nova etapa autorizada. Não chamar a V4 completa apenas porque o gerador novo está ativo.


## Convergência V4 — estratégia vigente em 20/10/2026
As instruções atuais do usuário substituem a restrição histórica de não iniciar esta etapa. Não há obrigação de compatibilidade com saves C3. WorldGenesis V4 é obrigatório em novas campanhas; City Forge R4 é proprietário da geometria urbana. Preservar Core e componentes funcionais sem substituto validado. Não declarar conclusão de habilidades/progressão a partir de fixture de QA.


## V4 Reparo Chat C02 — continuidade vigente
- Base integral C01 SHA-256 8796e58d3f8905f0edb37bac6344481a6a173342269f874cf8b993eb7b53522e. Relatórios R01–R07 sem seus ZIPs integrais não equivalem a mudanças recuperadas.
- Escopo e limites atuais em REPARACAO_CHAT_V4/ESCOPO-E-BASE.md e RELATORIO.md; evidência nova somente nesse diretório.
- Crowd recebe atlas 2048 com texturas finais dos NPCs da cena, sem demo/fallback. Não reduzir as texturas 256 a 64 nem inventar fonte aprovada. Malha clássica continua simplificada.
- Rotas preservam os pontos físicos e usam comprimento acumulado >=9 m; não exigir 16 m entre amostras adjacentes de 0,25 m. Caminhada é unilateral, com parada e replanejamento pelo diretor existente.
- Runner tools/run_repair_chat_checks.py GODOT --rendered. Sessão gráfica automatizada de 180 s não é benchmark nem homologação humana. Core, geração V4 e save permanecem autoridades existentes.
