# EXO-Murim — Convergência 03 / Work Candidato 01

**Checkpoint integral de retomada. Consolidação final ainda NÃO concluída.**

## Continuidade e base

Esta retomada recuperou exclusivamente `EXO-MURIM-CONVERGENCIA-03-ALFA-R13.zip`: 242.432.618 bytes, 4.732 entradas, CRC íntegro, SHA-256 `48ee4ea0bb9cd357ef416fcd6db099df9f8bc06d17be342d93afdc8f1de6fe21`.

As mensagens fornecidas relatavam uma execução mais avançada, mas seus arquivos intermediários não estavam disponíveis neste ambiente nem foram localizados entre os checkpoints salvos. Existia uma árvore antiga do Cidade Viva; ela NÃO foi usada como base nem recebeu o merge da R13. Dessa execução antiga foi reutilizada somente a instalação da Godot. As correções abaixo foram reconstruídas e executadas sobre uma cópia integral da R13. Não se afirma recuperação do código perdido, equivalência com o progresso narrado, nem conclusão da antiga tarefa.

Engine executada: `4.6.2.stable.official.71f334935`, Standard. Renderização gráfica: Compatibility / Mesa llvmpipe por CPU. Cinco capturas novas do viewport, sem composição conceitual, em `WORK_CHECKPOINT/evidence`. Não há benchmark da Vega 8 nem sessão humana homologada.

## Correções implementadas e verificadas

1. **Compilação:** tipo explícito de `wall_collision` e da célula seguinte no gerador de salas; identificador reservado `trait`; constantes que sombreavam `Engine`; referências a perfil fora de escopo; material `wood/timber`; chamadas dinâmicas indevidas sobre classes com métodos estáticos. O teste de parser agora exige `can_instantiate()` e deixa de aprovar scripts inválidos apenas porque `load()` devolveu um recurso.
2. **Save/JSON:** schemas numéricos aceitos corretamente após JSON, sem aceitar valores fracionários; seed do mundo reconstituída como inteiro para conservar sua representação textual e os contratos de identidade; contexto de visita da dungeon validado com inteiros JSON; chaves `StringName` legítimas aceitas na transação de loot, preservando a recusa de objetos não serializáveis.
3. **Criador/seed:** a seed escolhida passa a atualizar o atlas da nova campanha. O próprio módulo Marcial prepara seu domínio vazio para essa seed, apenas durante o criador e sem permitir apagar perfis, vínculos, aulas ou recibos existentes. Isso evita que a reabertura desative o serviço marcial por seed divergente.
4. **Viagem transacional:** WorldGenesis constrói a região candidata separada. Roster, descoberta, posição de destino e eventos são preparados antes de liberar a região anterior. O roster usa a mesma autoridade e pode ser preparado sem escrita antecipada; a gravação oficial confirma o conjunto. Se falhar, a cena candidata é descartada e a região, jogador, moradores, estado e arquivo anteriores permanecem. O teste injeta uma pasta inexistente e compara IDs de objetos, posição, documento e bytes salvos.
5. **Temporização:** encontros legados respeitam a pausa da simulação. A recuperação regional aguarda a sincronização física após reposicionar a cena candidata, antes de consultar chão e colisões.
6. **Vegetação:** seeds regionais decimais grandes são reduzidas pela função já existente `seed_mod`, sem conversão que exceda o inteiro assinado de 64 bits. Não foi alterada a geração das 88 regiões nem a seed de loot.
7. **Escola Jade:** plataformas baixas e rampas são identificadas como chão, preservando paredes e colisões. A rota usa o grafo de ruas oficial e uma aproximação física local limitada, com AStarGrid e varreduras de cápsula em cada segmento. Se não existe caminho comprovado, o mestre continua recusado. Não há teleporte nem NPC artificial. Na seed 101/região 15, o mestre real chegou à estação e marcou `arrived=true`.
8. **Dungeon:** fechamento dentro da instância não tenta acessar o transform global de um jogador que já saiu da árvore. A reabertura confirma âncora exterior segura, limpa a visita pendente e mantém o serviço Marcial ativo. Entrada, saída e reentrada passaram pelo método oficial de interação E.
9. **Validador de estradas:** a faixa lateral de teste passa a respeitar a largura real da via. O offset fixo de 3,5 m amostrava fora das pontes estreitas em duas regiões importadas. A correção não suaviza terreno nem altera estradas. Foram executadas 1.845 consultas físicas de chão/cápsula nas regiões 26 e 48 da seed 816204; todas passaram. O scanner de dados nativo validou 352 regiões em quatro seeds.
10. **Promoção marcial:** comparação de rank aceita os números do catálogo JSON sem reprovar o mesmo inteiro apenas pela representação float. Suíte Marcial R2 passou. Fixtures antigas de animação agora verificam o movimento autoral de braços em vez de clipes importados removidos; o teste de memória social mede o TTL a partir do último contato efetivo. As tentativas anteriores ficam identificadas como histórico.

## Evidências atuais

Os logs de `logs/current` são os resultados finais; `logs/history` conserva tentativas anteriores e diagnósticos. Sucesso exige código de saída correto E ausência de erros de engine/script; uma linha PASS isolada não basta.

| Verificação | Resultado | Limite |
|---|---|---|
| Varredura dos scripts | PASS | Carregamento nativo; não equivale a executar cada ramo |
| Bootstrap oficial | PASS, 9 verificações | Boot headless |
| Criador → campanha → comando de movimento → chão → cidade 78 | PASS, 15 verificações | Entradas automatizadas; não sessão humana |
| Reabertura automática em outro processo | PASS, 5 verificações | Cidade, moradores e host marcial |
| Viagem com falha de gravação | PASS | Mesma cena e atores, estado e arquivo anterior |
| Core Persistence / 100.101 recibos | PASS, 11 verificações | Teste funcional nativo; não benchmark de hardware alvo |
| Loot atômico | PASS, 16 verificações | Replay, inventário cheio e falha de save na suíte |
| Contrato Dungeon R6 | PASS, 22 verificações | Transações; complementar ao teste físico |
| Dungeon física E → chão → E → reentrada → fechar | PASS | Mesmo jogador e caminho de interação oficial |
| Dungeon reaberta automaticamente | PASS | Exterior seguro, visita limpa, serviço marcial ativo |
| Jade: porta, salão, retorno e mestre | PASS | Seed 101/região 15; NPCs em fixture física acelerada a 5 Hz |
| Mundo: 4 seeds × 88 regiões | PASS | Validação nativa de dados, sem caminhada integral |
| Corredores de estradas problemáticos | PASS, 1.845 amostras | Raios e cápsulas nas duas regiões identificadas |
| Capturas gráficas | 5 PNGs reais | Compatibility por llvmpipe; sem benchmark |
| Regressão de combate, inventário, cultivo, áudio, aparência, fauna e monumentos | Ver matriz JSON | Não declara cobertura total dos módulos |

A fixture do mestre executa `Resident.step`, `move_and_slide` e colisões reais, sem alterar o código do jogo para 5 Hz. Seu horário foi acelerado e os demais sistemas do jogador/ecologia ficaram suspensos. Não é medição de FPS nem teste de um dia completo. O teste de interação coloca o jogador em âncoras de cenário para isolar o acesso; a caminhada entre todas as regiões ainda não foi realizada.

## Estado dos sistemas

| Sistema | Estado nesta retomada |
|---|---|
| Core, boot e campanha | Integrados; fluxos acima verificados |
| Persistência/loot/recibos | Integrados; testes adversos selecionados passaram |
| WorldGenesis/88 regiões | Integrado; 352 validações de dados e corredores específicos |
| Terrain Forge | Integrado; importação e capturas Compatibility executadas |
| NPCs/Cidade Viva | Integrados; moradores na campanha e chegada física do mestre; ciclo completo de todos os NPCs pendente |
| Forja/interiores | Integrados; Jade entrada/saída e suíte de geometria verificadas |
| Dungeon | Integrada; entrada/saída/reabertura e transações verificadas; conteúdo adicional parcial |
| Mestres/discipulado | Serviço e acesso físico verificados; ciclo completo de confiança, matrícula, aula e desbloqueio ainda não homologado |
| Outras oito escolas | Catálogo preservado; atividades físicas completas continuam bloqueadas/parciais |
| Fauna/Humanoides | Integrações herdadas preservadas; suítes selecionadas passaram; sem homologação visual completa de cada espécie/arma |
| Mapa e UX | Versão da R13 preservada; polimento citado nas mensagens anteriores não foi recuperado |

Os `integration_mode` históricos do registro não foram reescritos para fingir completude. Esta matriz descreve a cobertura real atual; os catálogos e contratos herdados continuam preservados.

## Pendências para continuar diretamente deste ZIP

- **P1:** completar e testar um fluxo real de confiança → matrícula → aula → técnica → reabertura. Chegar ao mestre não prova ensino completo. Não falsificar ajuda ou confiança para passar no teste.
- **P1:** reimplementar/verificar armadilhas com dano, cooldown, desarme e rollback. O código dessa melhoria relatada anteriormente não foi recuperado; este candidato não a declara concluída.
- **P1:** reimplementar/verificar as melhorias anteriores de mapa, remoção de IDs técnicos nos diálogos e navegação local de todos os moradores. Não presumir que estejam neste checkpoint.
- **P1:** ciclo completo dos moradores da cidade, testes de filas/colisão com jogador e guardas em várias seeds. O 65/65 relatado anteriormente não é resultado reexecutado nesta retomada.
- **P1:** teste de aula interrompida, custos Qi/stamina, desbloqueio duplicado, morte na dungeon/interior e encerramento abrupto por kill do processo. O fechamento ordenado foi testado; kill adverso não é equivalente.
- **P2:** poses/bainha/duas mãos/rolagem, voo, mapa TAB, missão Explorar Ruínas e densidade de trajetos precisam de reprodução e revisão visual/humana.
- **P2:** benchmark instrumentado no Ryzen 3200GE/Vega 8; Android; aprendizagem nas outras oito escolas; cobertura física de todas as dungeons e orientações de interiores.
- **Entrega executável:** templates de exportação não estavam disponíveis. Não foi produzido executável Windows/Linux de distribuição; este é um projeto-fonte integral que abre pela raiz `project.godot`.

## Abertura, saves e rollback

Extraia o ZIP inteiro em uma pasta nova. Importe `project.godot` na Godot 4.6.2 Standard, mantenha Compatibility, aguarde a importação e pressione F5. Não sobreponha arquivos manualmente a uma pasta antiga. O nome e namespace herdados R13 QA permanecem configurados no projeto; isso não muda sua base nem converte saves pessoais.

Os testes usaram arquivos `work_campaign.json`, `work_dungeon.json` e `work_jade.json` dentro de `user://` (`EXO-Murim-Convergencia-03-ALFA-R13-QA` no ambiente Linux). Cópias dos saves de teste acompanham `WORK_CHECKPOINT/paired_qa_saves`. Não foram utilizados saves pessoais. Não instale esses saves de QA como campanha pessoal.

Para rollback, restaure o ZIP R13 original e seus saves pareados da mesma revisão; não copie apenas scripts antigos sobre um save já alterado. Este ZIP contém manifesto de preservação e diff R13 → Work. Prossiga desta revisão integral para as próximas correções, sem refazer merges nem iniciar Convergência 04.

## Proveniência

Não foram adicionados modelos, skins, texturas ou áudios externos. As novas imagens são capturas do próprio jogo. As 480 skins legadas continuam em quarentena; este teste técnico não comprova direitos comerciais dos assets herdados. Preservam-se os relatórios de proveniência da R13. Não classificar este checkpoint como release comercial homologada.
