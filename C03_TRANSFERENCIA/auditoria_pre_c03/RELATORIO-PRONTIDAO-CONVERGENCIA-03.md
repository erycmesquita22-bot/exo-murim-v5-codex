# Auditoria final pré-Convergência 03 — 19/10/2026

**Veredito: PRONTO COM BLOQUEIOS CONDICIONAIS.** Há base integral íntegra e candidatos rastreáveis para planejar fases em cópia. Isso NÃO libera merge geral, ativação de recompensas, matrícula marcial funcional, distribuição comercial nem homologação. As fases dependentes param nos gates abaixo. Nenhum merge, alteração de jogo, remoção ou migração de save foi executado nesta auditoria.

## Resultado e escopo efetivamente executado

Foram materializados **157 arquivos de fonte**, incluindo **57 ZIPs**. Todos os 57 ZIPs foram lidos integralmente para CRC e hashes de seus membros; nenhuma falha CRC foi encontrada. Foram comparadas árvores e scripts, contratos e evidências entregues. Os CSVs incluem todos os arquivos externos obtidos, manifestos embutidos e 31009 registros de membros. A matriz contém 118 relações de divergência/contrato; divergência histórica não significa que todos os blocos devam ser mesclados.

A busca usou inventário recente recursivo de 200 itens ZIP/MD/JSON/TXT/patch/diff, com corte suficiente para abranger todas as entregas prioritárias de 19/10, e busca nominal Core/Convergência. O arquivo mais recente do recorte era a instrução enviada às 19:57:49Z; Itens R3 foi entregue às 19:53:40Z. Não apareceu um sucessor dos candidatos selecionados nesse recorte. A conclusão vale para esses bytes e essa janela, não para entregas futuras. Arquivos de terceiros/versões anteriores fora do recorte não foram auditados exaustivamente.

**QA desta rodada:** integridade de ZIP, SHA-256 de fontes/membros, comparação de preimages, leitura estática e consistência de catálogos. Verificados 480 PNGs 64×64 no pacote Humanoides 03, 20 GLBs no pacote de Harmonização e referências das 16 técnicas marciais aos IDs do Core. **Godot não foi encontrada no PATH desta sessão; QA nativo: NOT_RUN**, sem marcar FAIL por ausência do motor. Não executamos os modelos Python entregues como se fossem GDScript; suas contagens são evidências históricas de cada produtor.

## Base integral escolhida

**EXO-Murim-Cidade-Viva-01-R2-PROJETO.zip**, **214,127,543 bytes**, **4.088 arquivos**, SHA-256 `1ef340db3f3ff0f133ec07808ee38d553ca4de7c48810f53b2cedc41cfde0b84`. A cópia com `(1)` tem o mesmo SHA e os mesmos bytes; não constitui outra revisão. A entrada configurada é `res://convergence/game.tscn`, renderer `gl_compatibility`.

Razões: é o projeto integral mais novo encontrado; contém Cidade Viva R2, EXO Visual com correções R2, Core corrigido e Fortificações 02 R2. A árvore do Core corrigido está inteiramente representada por caminhos nessa base: 36 membros comuns diferem e 176 foram acrescentados. Esses números incluem documentos/evidências; não são contagem de sistemas novos. Não trocar essa base por kits TESTE-PC, patches pequenos ou pelo Core ancestral de 192 MB.

**HUD paralelo confirmado:** o projeto HUD tem 7 caminhos exclusivos (`exo_ui/`), 22 membros comuns com hash diferente e não contém 122 caminhos da Cidade Viva R2. Portanto não é substituto integral superior. O patch HUD tem 11 arquivos; portar suas mudanças preservando `ui/pages/settings.gd` corrigido pelo R2. EXO Visual e fortificações já presentes devem ser preservados, não reaplicados cegamente.

**Core 01-P:** os 17 registros do manifesto foram confrontados com a base: os 15 arquivos preexistentes têm o hash antigo esperado e os 2 novos estão ausentes como esperado; todos os novos hashes do patch conferem. Isso comprova preimages compatíveis, não compilação ou integração funcional. `journey_save.gd` não é alterado pelo patch; continua autoridade junto ao SaveCoordinator.

## Candidatos e decisão

`READY_FOR_MERGE` significa pronto no papel específico indicado, inclusive preservar referência já integrada. `CONDITIONAL` exige gates explícitos; `BLOCKED` impede a função afetada. Nenhum desses estados é aprovação Godot/comercial.

| Arquivo exato | Versão | Tipo | Estado | Decisão e limite |
|---|---|---|---|---|
| EXO-Murim-Cidade-Viva-01-R2-PROJETO.zip | Cidade Viva 01 R2 | projeto_integral | CONDITIONAL | Base integral mais nova localizada; Visual+Fortificacoes; HUD paralelo; entrada legada ainda ativa |
| EXO-Murim-EXO-Core-01-CANDIDATO-CORRIGIDO.zip | Core 01 corrigido | projeto_integral_referencia | READY_FOR_MERGE | Ancestral verificavel, nao substituir a base Cidade Viva |
| EXO-Murim-EXO-Visual-01-PATCH.zip | 1.0.0 | patch_ja_contido | CONDITIONAL | Preservar versao/correcoes de Cidade Viva R2; nao reaplicar sobre ela |
| EXO-Murim-HUD-01-PATCH.zip | HUD 01 | patch | CONDITIONAL | Portar exo_ui e blocos de HUD/settings preservando correcoes Visual R2 |
| EXO-Murim-NPC-System-02-PATCH-CANDIDATO.zip | 0.2.0-candidate | patch_pre_requisito | CONDITIONAL | R1 necessario antes do DELTA R2; tres scripts compartilhados |
| EXO-Murim-NPC-System-02-R2-POLIDO-CANDIDATO.zip | 0.2.2-r2-candidate | delta_sobre_NPC02 | CONDITIONAL | Depende de R1; sem QA nativo; rotas de estacoes ainda exigem ponte |
| CORE-PERSISTENCE-01P-CANDIDATO.zip | 01-P / schemas 2 | patch_preparatorio_integral | CONDITIONAL | 17 arquivos; todos preimages compativeis; backup existente precisa validacao; QA nativo pendente |
| EXO-Murim-Itens-Procedurais-02-R3-CANDIDATO.zip | 2.0.2 | modulo_preparatorio | CONDITIONAL | Adaptador nao registrado; ativacao BLOCKED ate 01-P+hook+QA; 4 raridades/11 afixos no runtime |
| EXO-Murim-Dungeon-Genesis-02-R2-POLIDO-CANDIDATO.zip | 0.4.0 / generator 4 | modulo | CONDITIONAL | Instalacao isolada possivel; gameplay/loot BLOCKED ate checkpoints, recovery, IA e contrato atomico |
| EXO-Murim-Forja-Monumental-04-CANDIDATO-REVISADO.zip | 04-R1 / 0.4.1-preintegration / schema 5 | modulo_com_laboratorio | CONDITIONAL | Usar manifesto ADENDO; reserva real+transicao saloes pendentes |
| EXO-Murim-Mestres-Artes-Marciais-01-R2-CANDIDATO.zip | 1.2.0 | modulo | BLOCKED | Write API narrativa inexistente; provas trusted e desbloqueio Core nao conectados |
| EXO-Murim-Bestiario-Inimigos-02-PATCH.zip | 2.0.0 | patch_modular | CONDITIONAL | 16 fauna, 8 humanoides, 3 elites, 2 chefes; ponte fisica/dano/spawn central pendente |
| EXO-Murim-Creature-Harmonizacao-02-CANDIDATO.zip | 0.2.0-candidato / schema v1 | modulo_visual | CONDITIONAL | 17 IDs / 20 GLBs; 13 de 16 fauna cobertos; nao gera spawn |
| EXO-Murim-Humanoides-03-R2-CANDIDATO.zip | 03.R2.1-candidate | complemento_visual | CONDITIONAL | R2 sem PNG legado; 480 skins dependencia em QUARENTENA; eventos de pose propostos |
| EXO-Murim-Humanoides-Identidade-03-CANDIDATO.zip | Humanoides 03 | modulo_visual_dependencia | BLOCKED | 480 PNGs 64x64 verificados; titularidade comercial nao demonstrada: QUARENTENA |
| EXO-Murim-Fortificacoes-02-R2-PATCH.zip | 02 R2 | patch_ja_contido | READY_FOR_MERGE | Preservar implementacao ja na Cidade Viva; nao reaplicar |
| EXO-Skin3D-Hybrid-01-PATCH.zip | Hybrid 01 | patch_ja_contido_referencia | READY_FOR_MERGE | Preservar corpo/UV/outer layer existentes; nao substituir rig |
| EXO-Murim-Creature-Forge-01.zip | Forge 01 | assets_referencia | CONDITIONAL | Base rastreada da harmonizacao; nao duplicar catalogo ou spawn |
| EXO-Murim-Creature-Art-02-CANDIDATO.zip | Art 02 | assets_referencia | CONDITIONAL | Base rastreada da harmonizacao; nao contar variantes como especies |
| EXO-Forja-Arquitetonica-03.zip | Forja 03 | catalogo_laboratorio_referencia | CONDITIONAL | Referencia de catalogo; nao substituir WorldGenesis ou Forja integrada |

Versões anteriores de Itens QA-03, Dungeon 0.3.0, Forja 04 inicial, Bestiário 01, Mestres R1 e Creature Forge/Art são referências; não substituir os candidatos recentes por elas. Os ZIPs integrais antigos de Visual/HUD/Fortificações/Convergência foram comparados, mas a Cidade Viva prevalece como base. O R2 marcial referencia um R1 pelo hash `ff0bc...`: ele corresponde ao arquivo **EXO-Murim-Mestres-Artes-Marciais-01(1).zip**, e não ao homônimo sem sufixo (hash diferente). Usar o hash resolve essa ambiguidade; R2 contém seu próprio módulo completo.

## Riscos e impedimentos em ordem de gravidade

1. **Atomicidade Dungeon × Itens ainda contraditória — BLOQUEIO de loot de dungeon.** `exo_dungeon/module/entrypoint.gd::confirm_reward_receipt` comenta e exige verificador de transação já confirmada pelo coordenador, depois escreve marcador apenas em RAM. Itens R3 `confirm_pending` chama `domain_stage` ANTES de `world.save_progress()`. O contrato Dungeon também exige item+marcador no mesmo commit. Não é possível satisfazer simultaneamente uma comprovação durável anterior e incluir o marcador nesse primeiro commit sem definir outro protocolo. Owners Inventário/Core/Dungeon precisam escolher e implementar staging autorizado pré-commit no mesmo save (proposta preferida) ou reconciliação durável pós-commit explicitamente especificada. Nunca devolver `true` falso no verificador nem usar dois commits como se fossem um. Detalhe em MATRIZ-CONTRATOS.
2. **Persistência 01-P preparatória — BLOQUEIO de ativação R3.** Aplicação parcial proibida. Há ainda lacuna concreta no backup: `_migration_backup` aceita `.pre-corep01.json` preexistente apenas por não estar vazio; esse ramo não decodifica/valida identidade/schema ou integridade do backup. Corrigir no owner Core antes da adoção e testar backup inválido não vazio. Manter backups pareados e o arquivo original; não exigir migração de jogadores antigos como escopo de produto, mas proteger saves atuais usados no trabalho. Save 10k/100k precisa métricas nativas: ledger lógico continua dentro do JSON inteiro e EventBus faz cópia profunda.
3. **Mestres R2 sem write API narrativa — BLOCKED para matrícula real.** `narrative` registra apenas leituras `social_context/narrative_opportunities`; o contrato proposto `request_master_disciple_change` não existe. Mock não serve produção. Qi/stamina e provas de aula precisam runtime confiável; os tickets dependem das 16 técnicas reais, `cultivation.reveal/learn` e regras de 3 slots iniciais/teto 6. Há 9 escolas e 12 estilos nos dados, sem autoridade nova de técnicas.
4. **Dungeon host não montado.** Base `snapshot_region()` grava `player.position` sem guarda de visita ativa/recovery; instalar Dungeon sem conciliar esse ponto pode gravar coordenadas internas como exteriores. Precisa binding de checkpoint, recuperação no boot, validação de piso/cápsula, host de morte/encounter/loot e autorização WorldGenesis. V3 `generate()` foi preservado byte a byte como prefixo de `generator_v3.gd`; R2 acrescenta `generate_r2`. Isso não substitui testes determinísticos nativos das dependências V2/V3 e dos digests. Exterior continua residente em RAM.
5. **Forja e NPCs têm marcadores, mas a ponte física ainda falta.** Confirmados schema 5, 62 marcadores no contrato e layouts distintos de 70×72/146×142 m; reserva deve anteceder pequenos lotes/densificação. NPC R2 resolve aliases para `@activity/@square` sem ligação automática às 62 estações. Mestres requer tipos mais específicos (`training_lane`, `duel_ring` etc.) que não equivalem a qualquer pátio: mapear apenas estações realmente construídas e aprovadas. Interiores institucionais possuem cena/descritor, mas não transição geral instalada. Não tratar dungeon.enter como API de salão.
6. **Entrada legada permanece código ativo.** `murim_flow.create_character` chama `world.rebuild_region()` e `resume_checkpoint`; `convergence/game.gd` mantém HOME_GATE, `current_region=-1`, `return_home()` e a placa RECINTO INICIAL. Não há prova de criação → região procedural direta. Owner Flow/World precisa mudar esse caminho e regressões de missão/descanso antes de remover qualquer código. Ruínas usam coordenada fixa `RUIN_SURVEY`; a missão relatada precisa revalidação no contexto regional.
7. **Arte comercial: QUARENTENA das 480 skins legadas.** As imagens são íntegras em 64×64, mas o documento PROVENIENCIA-HUMANOIDES declara falta de titularidade demonstrada. R2 gera geometria nova sem PNG/GLB externo, o que não libera a dependência antiga. Guardar origem técnica e solicitar prova por asset; nenhum relatório desta auditoria certifica autoria. Respeitar a exigência comercial do diretor.
8. **Bestiário não é spawn/combate integrado.** Há catálogo/IA/ator e sinais de intenção; owner Ecologia/Combate deve ligar dano, ameaças, XP decrescente, loot e identidade por geração. Harmonização fornece 17 identidades entre 20 GLBs; 13/16 fauna têm visual. `wild_ox`, `wild_buffalo`, `qi_serpent` faltam; não substituir silenciosamente. As outras 4 identidades visuais fora do Bestiário não geram criaturas novas nesta release.
9. **Desempenho e benchmark PC sem conclusão válida.** O envio `(3)` termina em erro de indentação no script do KIT `exo_benchmark/benchmark_city78.gd:70`, não em prova de falha do jogo. O envio `(2)` registra `no_physically_safe_12m_street_route` na fixture. Há import inicial sem SCRIPT ERROR nesse envio, 43 casas/65 NPCs carregados, mas FPS/P95/P99 estão em branco no CSV. Não usar média 731,76 MiB daquele ensaio falho como benchmark aprovado. Há relato manual 30+ FPS Ultra, e evidência histórica llvmpipe com simulação congelada; ambos têm escopo diferente. Snapshot 532 MB/~40% CPU não é medição sustentável.

## Integridade documental: divergências explicadas

O CSV de manifestos contém verificações atuais e históricas, inclusive faltas de arquivos referenciados em distribuições antigas. **Não somar MISMATCH de manifestos históricos como corrupção da release.**

- Forja revisada carrega `MANIFESTO-SHA256.json` antigo com 14 hashes divergentes. O `exo_monumental/tests/ADENDO-FILE-SHA256.json` cobre 61 membros da revisão e todos conferem (incluindo o manifesto antigo preservado); selecionar o ADENDO como fonte atual e rotular o antigo histórico na próxima entrega.
- Dungeon R2: 87 membros declarados e 3 referências de ZIP confrontados com sucesso no manifesto R2; manifesto 02 anterior e histórico V1 têm divergências esperadas após R2.
- Itens R3: 60 arquivos e 6 registros/referências adicionais conferem; manifesto legado Itens 02 não representa os arquivos substituídos pelo R3.
- Core 01-P: os 17 arquivos novos e 3 ZIPs de referência conferem. Humanoides R2: 16 membros conferem.
- Documentos externos Core 01-P, catálogo Harmonização e manifesto Mestres R2 coincidem com seus homônimos internos verificados. Diffs que não vieram como arquivo externo independente foram encontrados dentro dos ZIPs; não estão ausentes da entrega.

## Evidência QA anterior e limites

Cidade Viva tem JSON nativo registrando **23 suítes PASS**, engine `4.6.2.stable.official.71f334935` e logs/capturas entregues. Essa é evidência histórica do checkpoint, não reexecução desta auditoria nem aprovação de todos os módulos novos. O ciclo NPC foi fixture acelerada isolada; o render benchmark usou llvmpipe com simulação congelada. Relatórios dos módulos recentes declaram Godot NOT_RUN. Nenhum teste de 100k Python demonstra tempo de save GDScript.

Lacunas persistentes: QA humano/nativo atual, licença das skins, serviço narrativo de escrita, ponte institucional, adaptação de runtime Bestiário, correção do kit PC e benchmarks comparáveis. Não encontramos contrato assinado entre todos os owners; documentos chamados CONTRATO são propostas técnicas, não aceite formal comprovado.

## SHA-256 das seleções

| Fonte | Bytes | SHA-256 calculado |
|---|---:|---|
| EXO-Murim-Cidade-Viva-01-R2-PROJETO.zip | 214127543 | `1ef340db3f3ff0f133ec07808ee38d553ca4de7c48810f53b2cedc41cfde0b84` |
| EXO-Murim-EXO-Core-01-CANDIDATO-CORRIGIDO.zip | 192209770 | `d6cae1fc95078b9b083755d68ee59c99568801e01fde8c5983366dc4c616f1ac` |
| EXO-Murim-EXO-Visual-01-PATCH.zip | 3198348 | `12c782c27aa79379ed4681fc5a30fd60ab35f20351abee0e9b138352839b401c` |
| EXO-Murim-HUD-01-PATCH.zip | 2362211 | `6d91ecfc3f8bcdf877c51fe1cfec861be116980aa7b05333476c4298124a29ea` |
| EXO-Murim-NPC-System-02-PATCH-CANDIDATO.zip | 37418 | `82d2a5b34fe162acec6ac8fe9ead4b710dd030a2e5391ae4b400a521e41dcc80` |
| EXO-Murim-NPC-System-02-R2-POLIDO-CANDIDATO.zip | 41430 | `244b58b45d700bf01f2da61abb06ba3191dbb32c71fe0ee40c8585a417acccd6` |
| CORE-PERSISTENCE-01P-CANDIDATO.zip | 63928 | `39c1fbd3e6a6ae2aa34f5521ec9e51b5cde65d137b6a01853f7d1a09c1a16f05` |
| EXO-Murim-Itens-Procedurais-02-R3-CANDIDATO.zip | 97434 | `1b6565119e18ebd33f5d30048b55f188054186f91ab8f47391a5d38190257c3d` |
| EXO-Murim-Dungeon-Genesis-02-R2-POLIDO-CANDIDATO.zip | 165309 | `5de1547a4b0457d004ede46fe05e3d41ce73af2a70a00ef1b49372f2549e3dc5` |
| EXO-Murim-Forja-Monumental-04-CANDIDATO-REVISADO.zip | 216499 | `c33baa93958b6c7b9be4ae277894ac4caa5b92b47ad835721a4f3954fd898030` |
| EXO-Murim-Mestres-Artes-Marciais-01-R2-CANDIDATO.zip | 72947 | `454ef44495a338b2146a62012febcaa4a0f3a6ef38627fd3a3284c4451423e75` |
| EXO-Murim-Bestiario-Inimigos-02-PATCH.zip | 41898 | `44bbbe60f612d2e1469156f3f21d2e612f0c623f98b224ecc2e4936c06133a6e` |
| EXO-Murim-Creature-Harmonizacao-02-CANDIDATO.zip | 2117819 | `ccf5bea979942d285557e3ccf0ac8162fa780b7543346fae28f10320cfc59bde` |
| EXO-Murim-Humanoides-03-R2-CANDIDATO.zip | 32096 | `8825785441671c39fc70d3c8e34a4f9c37b4c85406c04da6491280f729503c9e` |
| EXO-Murim-Humanoides-Identidade-03-CANDIDATO.zip | 494217 | `8f5e6a4b5d51c0b8b1541236aa385a15d734322ae948ac504e2a8b88a06baa3d` |
| EXO-Murim-Fortificacoes-02-R2-PATCH.zip | 3073327 | `52493720de59fd2fcd71dbf152805784ba964a9ea0dff08c688ad6849d252956` |
| EXO-Skin3D-Hybrid-01-PATCH.zip | 221887 | `bcab4f165cbe2dd7f68c1fc050593c5b0d9a3b245a5d0a700a7177b207736cc9` |
| EXO-Murim-Creature-Forge-01.zip | 3114441 | `26b383597e2ec6565e9e6c59578b5b2eee637e986eec73fd9deb39274ad37ee7` |
| EXO-Murim-Creature-Art-02-CANDIDATO.zip | 1414043 | `c30daec9cc500e3eec1c8c0f1472d40ded0fb747733166e608f9c8b36f2d3662` |
| EXO-Forja-Arquitetonica-03.zip | 26958470 | `bf0c2036b681e708bb9b35549d776df971a63e95e3f1476e32038a7c52252323` |

## Próxima ação autorizável e limites desta entrega

Seguir ORDEM-DE-MERGE-03 em branch isolado quando o diretor iniciar a próxima etapa. Fases podem preparar a base e validar 01-P antes dos módulos dependentes; sistemas bloqueados ficam desativados até os respectivos gates. O plano identifica correções a executar pelos owners, sem implementá-las neste chat. Não iniciar a Convergência 03 por este documento nem considerar a release homologada.

O pacote de auditoria contém os nove entregáveis requeridos, CSVs complementares de membros/manifestos, diffs não aplicados e evidências de inspeção. Não contém uma nova build do jogo.
