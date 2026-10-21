# EXO-Murim — correções das auditorias 01

21/10/2026. **Candidato parcial; NÃO HOMOLOGADO e não é uma beta.**

## Resultado

Corrigidos os rótulos técnicos do criador, o vão físico no topo das escadas do Interior Forge R3 e a fachada que ocultava o jogador no interior integrado. As correções anteriores CEO CP01/CP02 de save e portas foram reconstruídas e testadas de verdade em Godot **4.6.2.stable.official.71f334935**. Não houve troca indiscriminada de módulos ou alteração do acervo original.

## Base e coleta

- Base exclusiva de aplicação: `EXO-MURIM-V4-REPARO-CHAT-C02-INTEGRAL.zip`.
- SHA-256 conferido: `9a3e205d3dd7db949a93bf13a17e9bdbc61225a73eb2f22e9f2bef41dd6ccc0e`; CRC PASS, 6.672 entradas.
- CEO CP02 reconstruído pelo instalador original sobre essa C02: exit 0; SHA desta reconstrução `5ccae89fb6f27656f8f5bc0a4ace9b965ea7e18f75d236e495cb1c4aadadc1ad`. Seus relatórios não foram tratados como execução nativa: os testes foram repetidos.
- Seleção: C02 possui evidência histórica de portas/ativação; CP02 contém reparos localizados de rollback/interior. A reprodução nativa confirmou esses caminhos, justificando mantê-los. Isso não prova superioridade geral da C02 a todos os ramos.
- Controle mestre GER-01, matriz técnica 01, relatórios CEO CP01/CP02, C02, QA Godot anterior e Interior R3 recuperados e lidos. Três coletâneas com **34 pacotes internos**: 34 hashes iguais ao índice e 34 CRC PASS. Inventário e hashes completos em `evidence/`.
- **Não localizados:** entrega específica posterior da auditoria agendada P0/P1/P2 e entrega denominada “Validação 2”. A busca por títulos e a listagem recente estão preservadas. Os pacotes CEO P0/P1/P2 disponíveis foram analisados; não equivalem a afirmar acesso a outras conversas ou às execuções agendadas.

## Correções e limites

| Item | Alteração efetiva | Evidência/estado |
|---|---|---|
| Save/interiores CP02 | Snapshot antes de preparar save; rollback; replay/laboratório sem commit; coordenadas globais; recuperação de queda; autosave interno | VALIDADO no escopo nativo abaixo; autoria do reparo anterior preservada |
| Criador | Traduções de camadas, acessórios e armaduras; opções persistem os mesmos IDs canônicos | Falha reproduzida antes; callbacks, schema e captura depois PASS |
| R3 escadas | Patamar conecta fim da rampa ao piso superior, sem alterar os 52 JSONs autorais | Antes: queda física após ultrapassar a rampa; depois 14 subidas PASS |
| R3 roteiro | Flush dos eventos de tecla; proteção contra instância nula; tempo suficiente para alcançar piso superior; exige chão e altura >4,7 m | Teste original travava após E não processado; roteiro ajustado revelou o vão físico |
| Interior integrado | Recorte visual das fachadas exteriores voltadas à câmera, portado seletivamente do R3 | Colisores continuam presentes; captura real antes/depois; portas/reload repetidos |
| HUD duplicado | Nenhuma alteração nova: C02 já escondia o painel antigo no HUD oficial | Teste de visibilidade e captura real confirmam o cenário exercitado |

O R3 autônomo continua separado. Seu `interior_portal_session.gd` e seu save de demonstração **não substituem** a sessão/persistência EXO. No host integrado, interiores de dois pisos continuam bloqueados por regra existente (`floors>1`); corrigir o builder não os habilita automaticamente. Nenhum asset externo foi adicionado ao jogo.

## Testes efetivamente executados

| Teste | Resultado | Limite |
|---|---|---|
| Import CP02 e import final | PASS, exit 0 | Ler logs para avisos; não é gameplay |
| Suíte funcional integrada final | **242 checks PASS**, 70 técnicas exercitadas | Progressão/equipamentos injetados por fixture; não prova aprendizado natural |
| Ativação integrada final | PASS; seis mestres City Forge em seed101/r78, NPC03 e Crowd | Uma cidade; não prova rotina/ensino de todas as escolas |
| Interior ampliado | 10 entradas/saídas, transform de sala, queda, autosave em disco, lab sem commit: PASS | Relógio de autosave acelerado por delta; não é sessão humana de 20 s |
| Reabertura | Novo processo restaura região, visita e posição interna; recusa saída distante e permite porta: PASS | Mesmo fixture isolado; não são saves pessoais |
| Interface | Rótulos sem IDs técnicos, callback cabelo preserva `topknot`, schema, HUD oficial/alternativo: PASS | Tradução PT-BR; EN/zh-CN continuam pendentes |
| Godot gráfico | Compatibility/OpenGL Mesa llvmpipe; PNGs reais criador/interior | Xvfb 1152×720, limite de 15 FPS para captura; sem benchmark; áudio Dummy |
| Interior R3 autônomo corrigido | **117 checks PASS**, 52 plantas instanciadas, 14 subidas, 10 ciclos E, save/recriação da cena | Recriação na mesma execução; reabertura EXO foi testada em processo separado |
| Core Persistence 01P | 11 checks PASS | Suíte modular |
| Economy R5 | 1.068 checks PASS | Suíte modular; não habilita nove bens sem item físico |
| QA estático CP02 | 16/16 PASS | Sintético, não substitui motor |
| Coletâneas | 34/34 SHA e CRC PASS | Integridade, não funcionamento dos 34 módulos |

Dados de teste separados por `XDG_DATA_HOME`, originais preservados. Logs registram comandos, duração e exit code. Avisos de V-Sync/socket no display virtual e ausência de dispositivo de áudio nas primeiras tentativas são do ambiente; capturas finais usaram áudio Dummy. A aprovação não inclui som audível, GPU do usuário, Windows ou Android.

## Falhou nesta rodada

- `tests.gd`: **212 passaram / 162 falharam**, incluindo acesso a `exo_core` ausente em `main.gd`, host legado usado pelo roteiro. Não alterado nem marcado como aprovado.
- `legacy_audio_qa.gd`: **7 passaram / 1 falhou**; catálogo de fases de áudio não acompanha todas as técnicas do catálogo expandido. Não inventada associação de sons para ocultar a falha.
- `consolidation_qa.gd`: exit 1 antes de resumo, após verificações iniciais de menu. Causa completa não isolada nesta rodada. Permanece falha aberta.
- Roteiro R3 original: entrada E falhou e acesso nulo interrompeu a suíte; timeout preservado. Com instrumentação correta, 14 checks de escada falharam, levando à correção física; execução final passou.
- Primeira tentativa de portar cutaway introduziu erro de indentação em `interiors.gd`; corrigido antes das verificações finais. Log da tentativa preservado, sem distribuir a versão inválida.
- Tentativas iniciais de preparar display falharam por ambiente; execução gráfica posterior foi obtida. Nenhum bloqueio ambiental foi convertido em PASS.

## Matriz técnica — pendências

| Achado original | Apuração atual |
|---|---|
| AUD-001/002 interiores/portas | VALIDADO apenas o subconjunto e os fluxos descritos; outras tipologias/caminhada humana pendentes |
| AUD-003 mestres | Seis atores legítimos e perfis presentes; deslocamento e progressão natural NÃO HOMOLOGADOS |
| AUD-004 arquitetura | PENDENTE: builder urbano/kit aprovado não substituído |
| AUD-005 Crowd | PENDENTE: equivalência de malha, roupa/cabelo, destinos, colisão e custo |
| AUD-006 técnicas | 70 sob fixture; 98 operações e aprendizado natural PENDENTES |
| AUD-007 economia | Suíte R5 PASS; nove bens sem item físico e E2E merchant/reload PENDENTES |
| AUD-008 HUD/IDs | Corrigidos rótulos cosméticos; cenário HUD oficial sem duplicação; diálogos/idiomas/resoluções restantes PENDENTES |
| AUD-009 regressões | TESTE-FALHOU: três suítes históricas, mantidas nos logs |
| AUD-010 direitos | BLOQUEADO para homologação comercial: assets de terceiros ainda presentes na base; não distribuível como release aprovada |
| AUD-011 saves | Isolamento aplicado nos testes desta rodada; config de produção preservada |
| AUD-012 referências | Walker CP01 preservado, QA estático PASS; raiz própria do template respeitada |
| AUD-013 diversidade | PENDENTE: métricas multisseed e avaliação artística ampla |
| AUD-014 gate | Evidência adicionada para os fluxos exercitados; não gate universal de todos os módulos |
| AUD-015 dungeon/voo/armas | PENDENTE: regressão física/visual completa, água/pontes, mapa TAB e ruínas |

**Alterado mas não validado em campanha real:** patamar de dois pisos no host integrado (regra ainda bloqueia esses interiores). Foi validado fisicamente no R3 autônomo. **Homologação de todos os demais fluxos: NÃO.** A captura interna ainda mostra minimapa/contexto da região exterior; UX de mapa interno permanece pendente. Zoom 22 da captura foi configuração explícita do roteiro, não nova câmera automática do produto.

## Uso dos entregáveis

- Integral `EXO-MURIM-AUDITORIA-PENDENCIAS-01-CANDIDATO.zip`: extraia em pasta nova. É candidato técnico, preserva assets/limitações da C02.
- Patch: `python aplicar.py C02-original.zip NOVO-candidato.zip`. Exige hash exato, confere cada arquivo, CRC e igualdade byte a byte de todas as entradas não alteradas; recusa sobrescrever saída existente. Não aplicar sobre ramos concorrentes ou diretamente sobre CP02.
- `C02-para-AUDITORIA-01.patch` é cumulativo; `CP02-para-AUDITORIA-01.patch` mostra somente o incremento para revisão.
- R3 corrigido é projeto autônomo separado. Não sobrepor seu `project.godot` ou sessão à integral EXO.
- Evidências contêm logs brutos de sucesso e falha, hashes, inventários, scripts executados e capturas. `SHA256SUMS.txt` identifica as saídas finais.
