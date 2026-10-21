# EXO-Murim — Convergência V4 — Candidato consolidado 01

Entrega de integração funcional, **ainda parcial**. Não é uma declaração de Convergência V4 integralmente concluída ou de versão pronta para lançamento.

## Base e continuidade

Trabalho incremental em cópia do último checkpoint WorldGenesis V4 Candidato03. Nenhum reinício na C3. Base integral preservada: `EXO-MURIM-WORLDGENESIS-V4-INTEGRADO-CANDIDATO-03.zip`, SHA-256 `6315bb557e9044d433307e55ec9b36ed0a92eb4638ce4586cefe8c6c022b0b8a`; CRC validado. Novo diretório de dados da aplicação: `EXO-Murim-Convergencia-V4-C01`. Saves C3 não são alvo de migração/compatibilidade desta entrega. A autoridade de geração é V4; atlas sem contrato V4 é recusado, sem fallback urbano C3.

Atualizações físicas incorporadas: Terrain Forge R3, SHA-256 `a39fa3ebfb7a78a9d093c3d5e8d4d32962bcf1e94f99bc06f48f419998b1bd8d`; Bestiário03, SHA-256 `160651a55ff672c90d7330309fb60ea6c80840e3c492ecad711b5ac19ac18f34`. Ambos os ZIPs tiveram CRC validado. O Bestiário03 foi reconciliado somente nos dez arquivos novos/modificados em relação à base; as correções mais novas do ator físico de fauna foram preservadas.

## Resultado efetivo

- City Forge R4 constrói as cidades do jogo. WorldGenesis valida implantação, rios, reservas, portas, afastamentos e vias; não há fallback para SettlementPlanner C3. Receitas compactadas, conectores entre setores e ajuste de fachadas preservam os edifícios autorais, com colisões reais e portas livres.
- 69 planos urbanos aprovados nas seeds 101, 707 e 18026. Isso é prova de planejamento, **não 69 cidades renderizadas/testadas individualmente**. Cenas físicas/capturas adicionais cobrem aldeia r7, vila r15 e cidades r14/r78, seed101.
- Cidade78: 32 edifícios, 48 NPCs físicos, 92 decisões NPC03 aceitas no cenário de ativação. Crowd criou 16 figurantes às10h e17 às12h em quatro faixas verificadas; figurantes não recebem combate, inventário ou persistência individual.
- Bestiário03: API nativa passou13 verificações. Host físico consumiu propostas de ataque em grupos de1,4,8; máximo2 ataques simultâneos durante toda a janela; nove golpes despachados no cenário agregado e dano real pelo Combat. Posições dos inimigos nesse teste foram fixtures explícitas. O diretor ecológico também gerou um inimigo real em teste separado; nenhum diretor paralelo foi criado.
- **70 técnicas autorais realmente executadas** em cena nativa Godot, com dano/status, cura ou escudo conforme o plano. Todas tiveram custo e cooldown verificados. Arma incompatível, Qi/stamina insuficiente, parede sólida, alcance, plano adulterado, falha de save e repetição de recibo foram exercitados. Os testes forneceram nível50, discipulado, aprendizagem e equipamentos por fixtures: **não comprovam obtenção natural das70 em campanha**.98 autorais seguem bloqueadas por operações sem executor físico completo.
- Biblioteca: **35 registros únicos** comprovados nos cenários QA, em 35 pares registro/consumidor. Contagem agregada entre campanhas de teste; não é uma promessa de quantidade por campanha. Distribuição: city_pavement_material=4, enemy_danger=1, npc_dialogue=20, npc_traits=6, quest_offer_priority=4. Catálogo disponível:1228 registros/76 domínios; disponibilidade, cache e propostas armazenadas não contam como integração. Ledger integral em `BIBLIOTECA-CONSUMO-REAL.json`. Diálogos de48 residentes passaram pelo modal nativo; captura gráfica adicional demonstra o texto em cena.
- Interior Forge: três portas físicas preparadas e aprovadas no r78, com piso e cápsula livres; entrada, visita salva, retorno, falha de gravação com rollback e reabertura em processo separado aprovados. Seleção permanece congelada pelo receipt existente. Visita reabre no ponto seguro de entrada, não na posição arbitrária de caminhada dentro da sala. Até3 interiores térreos por assentamento; não são52 tipologias habilitadas automaticamente.
- Seis professores vinculados a escolas CityR4 no r78, com os perfis do módulo marcial existente. Um chegou a uma estação física reconhecida pelo host após60 segundos de rotina. Matrícula/provas/currículos completos não foram simulados como desbloqueios de campanha.

## Matriz C3 → V4

| Módulo | Estado | Substituição / execução | Limite restante |
|---|---|---|---|
| EXO Core | ATIVO | Preservado; Registro único; eventos; JourneySave/SaveCoordinator | Não foi substituído |
| WorldGenesis V4 | ATIVO | Substitui geração C3 de novas campanhas; Grafo 88; terreno V4; trilhas; POIs; campanhas e reabertura | Limpeza ampla de ferramentas históricas pendente |
| City Forge R4 | ATIVO | Substitui SettlementPlanner/Architecture/Forja no urbano principal; Receitas autorais; setores; ruas; lotes; edifícios com colisão; acesso ligado às vias | Fortificações e monumentos especializados mantidos sem substituto validado |
| Terrain Forge R3 | ATIVO | Substitui recursos anteriores na camada principal de materiais; Atlas 4x4; relva/terra/pedra/folhagem; pavimentos por setor e tema | Dressing adicional preservado; não é um segundo relevo |
| NPC03 | PARCIALMENTE ATIVO | Decisões V4 aplicadas a residentes reais; 48 residentes na cidade 78; 92 decisões aceitas; traços da Biblioteca | Movimentação/roster/habitação continuam nos owners existentes; não foi reescrito todo NPC02 |
| Crowd Illusion R4 | ATIVO | Remove dependência de cenário Cidade Viva C3; Quatro faixas com envelope físico amostrado; setores City R4; 16-17 figurantes no r78 | Figurantes visuais; não são NPCs de combate |
| Bestiário/Inimigos 03 | PARCIALMENTE ATIVO | Atualização 2.0.0 → 3.0.0 em entrada única; Táticas consultivas consumidas por melee físico; cap 2; impacto validado pelo Combat | Flancos/navegação tática; grupos mistos/boss; técnicas autorais inimigas bloqueados |
| Skill Forge R3 | PARCIALMENTE ATIVO | Executor autoral conectado ao Combat aprovado; 70 autorais com efeitos físicos e custo/cooldown/arma/LOS/persistência | 98 autorais sem executor completo; progressão natural de todas as 70 não homologada |
| Biblioteca Universal R4 | PARCIALMENTE ATIVO | Propostas aceitas por consumidores tipados; Traços NPC; diálogo; prioridade de ofertas; materiais urbanos; perigo de inimigos | Não ativa automaticamente todos os 1228 registros; eventos/arcos avançados pendentes |
| Interior Forge R2 | PARCIALMENTE ATIVO | Novo host físico substitui hall genérico nas portas City aprovadas; Até 3 interiores selecionados por região; receipt congelado; entrada/retorno/reload | Pisos múltiplos; todas as tipologias; halls R7 ainda não migrados |
| Economy R5 | PARCIALMENTE ATIVO | Mantém único dono funcional atualizado; Mercador físico City R4; cotação; compra; carteira/estoque/inventário/save atômicos | 3 bens físicos; 9 dependem de hosts de itens/produção ainda ausentes |
| Jornada Dinâmica 02 | PARCIALMENTE ATIVO | Missões disponíveis continuam no owner único; Ofertas reais priorizadas por Biblioteca; progresso/recompensas do sistema aprovado | Arcos V4 dependentes de fatos narrativos não conectados ao executor |
| Mestres urbanos | PARCIALMENTE ATIVO | Escolas físicas City substituem dependência exclusiva de monumentos R7; 6 ocupações marcais legítimas no r78; perfil persistente; chegada física comprovada de 1 | Matrícula e provas específicas de todas as escolas/técnicas ainda pendentes |
| Áudio/VFX/animação | PARCIALMENTE ATIVO | Reutiliza recursos e apresentadores existentes; Rigs/ações/feedback genérico de técnicas; eventos de áudio do host | Clips e VFX autorais específicos não homologados; áudio audível NOT_RUN |

## Legados removidos do fluxo principal

1. Chamada de SettlementPlanner C3 para assentamentos, sua tentativa de fallback e a dependência do materializador urbano em Architecture/Forja para edifícios ordinários: substituídas por City Forge R4 físico.
2. Renderização secundária Cidade Viva no host regional e suas constantes/imports não usados: removidos. Crowd deixa de exigir `cidade_viva.rendered` e exige CityForge físico mais receipt de amostragem atual da geometria.
3. Geração de relevo C3 anterior à aplicação do perfil V4: removida do caminho principal. Atlas C3 é recusado; seleção por feature flag não retorna silenciosamente a C3.
4. Aceitação de versões regionais4/5/6 no validador desta entrega: removida. Campanhas exigem versão regional7 com contrato de gerador4.
5. Placa antiga de portal de retorno sem função: removida. Viagens de campanha usam passagens regionais reais.
6. Quatro arquivos obsoletos de comparação C3×V4 (`capture_compare.gd`, `benchmark_compare.gd` e seus UIDs) foram excluídos: após tornar V4 obrigatória, esses scripts poderiam rotular V4 como C3.

**Não foi feita exclusão em massa dos arquivos históricos C3.** Ferramentas/laboratórios, relatórios e referências antigas ainda existem no pacote; não são a implementação principal. A lista exata de arquivos adicionados/modificados/removidos e hashes está em `MANIFESTO-ALTERACOES.json`. Permanecem Core, executor de combate aprovado, roster/movimentação, fortalezas, ruínas/dungeons e halls monumentais sem substituto físico homologado. Isso é limitação explícita da consolidação, não preservação por save antigo.

## QA real e limites

Godot4.6.2 Standard, Compatibility/OpenGL. Cenas nativas executadas no motor; capturas gráficas por renderização Compatibility em Xvfb. Testes automatizados invocam os mesmos métodos de gameplay (incluindo interação E), não equivalem a uma sessão manual de teclado. Sem execução de binário exportado Android/Windows.

| Caso | Estado | Evidência |
|---|---|---|
| Integridade base/insumos | PASS | SHA-256/CRC descritos acima |
| Importação e parse | PASS | import-consolidated.log |
| City69 planos /3seeds | PASS | city-three-seeds.log |
| City físico/NPC03/Crowd/professores | PASS | city-final.log; live-actors-final.log; capturas |
| Bestiário03 contratos/combate físico/reload | PASS | bestiary03-native.log; bestiary03-physical-final.log; bestiary03-reopen.log |
|70 técnicas, custos, cooldown, paredes e rollback | PASS sob fixture | functional-consolidated.log |
| Biblioteca consumidores, diálogo e persistência | PASS | library-ui.log; BIBLIOTECA-CONSUMO-REAL.json |
| Mercador físico, operações atômicas e regressão Economy | PASS | economy-consolidated.log; economy-reopen.log |
| Travessia E, cápsulas de estrada, POIs e save/reopen | PASS | wg4-traversal.log; wg4-reopen.log |
| Novas campanhas707/18026 e digest/atlas no reload | PASS | seed*.log |
| Entrada/saída/rollback Interior e reabertura separada | PASS | functional-consolidated.log; interior-reopen.log |
| Core/persistência/contrato SkillForge | PASS | core-contracts.log; persistence.log; skill-contracts.log |
| Matrícula/provas/currículo das70 técnicas em campanha | BLOCKED/PARCIAL | hosts de provas e estações/currículos incompletos |
|98 autorais e técnicas de NPCs/inimigos | BLOCKED | operações/host ainda ausentes |
| Arcos V4/fatos narrativos/eventos avançados | BLOCKED | integração de fatos não implementada |
| Todos interiores multiandar e halls antigos migrados | BLOCKED | homologação de portas/navegação/tipologia pendente |
| Áudio audível, validação manual longa, Android real | NOT_RUN | não inferir a partir de DummyAudio/headless |
| Otimização global/FPS em PC modesto | NOT_RUN | fora do escopo desta etapa |

Tentativas de desenvolvimento que falharam não são usadas como evidência PASS. O checkpoint intermediário CP01 é recuperável, mas antecede a ligação final do Bestiário03 e a remoção do requisito C3 do Crowd. Um sítio marcial monumental r14 permaneceu sem ocupação quando seu acesso físico foi recusado; não houve criação artificial de professor nesse sítio. A ligação CityR4 foi validada independentemente.

## Pendências prioritárias

1. Homologar obtenção natural das técnicas por escola, aulas, provas, reputação/atributos e interface; adicionar estações de ensino somente com geometria e testemunhos reais. Não liberar todas por registro.
2. Implementar, testar e mapear os98 conjuntos de operações restantes (projéteis, canais/campos, deslocamentos e status ainda ausentes); manter sem autorização até lá.
3. Ampliar Bestiário03 para navegação/flancos, magos/arqueiros/boss e grupos mistos, sem mapear propostas para efeitos inexistentes. Técnicas autorais inimigas exigem executor de ator próprio com recursos e persistência aprovados.
4. Migrar halls R7 e tipologias restantes ao InteriorForge, validar escadas/pisos múltiplos e estabelecer polígonos/câmeras adequados para interiores maiores.
5. Vincular Jornada02 aos fatos narrativos e aos consumidores de eventos reais; ampliar Biblioteca além dos domínios demonstrados.
6. Ativar nove bens Economy restantes somente após hosts físicos de produção/itens/serviços; não criar carteira/inventário paralelos.
7. Remover ferramentas e código histórico inerte por fechamento de dependências, mantendo os checkpoints como referência de migração.
8. Qualidade visual: interiores maiores, variedade arquitetônica visível, pavimentação e transições adicionais; clips, áudio e VFX específicos com QA audiovisual. Não bloquear mecânicas aprovadas por esse polimento.

## Abrir, reproduzir e rollback

Extrair ZIP em pasta nova, importar `project.godot` na Godot4.6.2 Standard e executar F5. Renderer já éCompatibility. Criar nova campanha; a aplicação usa diretório de usuário próprio. Não é preciso instalar Python ou copiar módulos para jogar no editor. O motor não acompanha o ZIP.

Scripts de reprodução principais: `convergence4/tests/qa_activation.gd`, `qa_functional.gd`, `qa_library_ui.gd`, `qa_bestiary_scene.gd` (`-- --reopen` para reabertura) e `qa_reopen.gd`. O último requer o save gerado por `capture_day.gd`. `qa_city_data.gd` valida planos. Todos usam arquivos de QA separados do save normal. Fixtures nunca são executadas pelo F5 normal.

Flags locais: `exo_murim/convergence4/authorial_skills`, `physical_interiors`, `bestiary_tactics`. Desligar skills recusa autorização; desligar interiores deixa portas sem habilitação. WorldGenesis/City não possuem fallback C3; rollback dessas integrações exige restaurar o ZIP integral anterior em pasta isolada. Manter o save de QA correspondente ao checkpoint. Não misturar arquivos de versões por sobrescrita parcial.

Fontes autoritativas desta rodada são esta pasta e `convergence4/`. Pastas de evidências C3/R13/WORLDGENESIS_V4 mais antigas são históricas; seus PASS não substituem os testes atuais. Checksums finais do ZIP são entregues externamente para evitar autorreferência no próprio arquivo.
