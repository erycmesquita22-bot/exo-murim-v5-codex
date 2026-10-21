# EXO Core 01 — arquitetura da Convergência 02

Engine: Godot 4.6.2 Standard, Compatibility. Entrada: `convergence/game.tscn`.
O diretório de saves continua EXO-Murim-Convergencia-01; a raiz JSON continua v4.

## Infraestrutura executada

`exo_core/core.gd` conecta o ciclo da cena aos serviços existentes. `module_registry.gd` valida IDs, fornecedores exclusivos, dependências obrigatórias/opcionais e versões; ordena deterministicamente o grafo e inicializa os nove módulos. Falha obrigatória bloqueia inicialização; falha de módulo explicitamente opcional é registrada.

`service_registry.gd` oferece `invoke(serviço, método, argumentos)` com métodos permitidos e referências fracas aos provedores. Serviços: persistência, regiões, NPCs, inventário, combate, progressão, missões, narrativa, aparência e arquitetura. Não há outro controlador de personagem ou regras alternativas de dano.

`event_bus.gd` distribui envelopes schema 1 com ID, tipo, origem, região e contexto. Consumidores são invocados em ordem de registro, Jornada antes de Narrativa. Publicações reentrantes são enfileiradas, com teto de 128 por lote; schema/origem incorretos e colisão de ID são recusados. O lote restaura o documento de save se um consumidor recusar. Callbacks devem limitar efeitos ao estado transacional; não abrir arquivos ou criar efeitos irreversíveis antes do commit.

Recibos duráveis do Core ficam em `exo_core.receipts`; eventos narrativos mantêm os recibos existentes em `narrative.receipts`. Não são dois barramentos: o primeiro distribui eventos do jogo, o segundo é a proteção de idempotência interna do módulo narrativo. O scheduler narrativo continua aplicando suas operações internas no módulo. Ação física tem um único ponto de publicação. Eventos de viagem identificam cada transição; descoberta/XP e fatos narrativos têm recibos próprios para não duplicar efeitos em revisitas.

O Core observa alterações de XP, nível, aparência, equipamento, contratos e reputação antes de `save_progress`, publicando as diferenças na mesma escrita. Entrada/saída regional, conversa, morte e coleta têm pontos explícitos nos executores. APIs legadas são mantidas para compatibilidade. O Core não transfere automaticamente recompensas: os executores existentes continuam responsáveis por elas.

## Identidade

Os IDs de moradores, membros ecológicos/gerações e itens não são renumerados. `contracts/entity_contracts.gd` fornece uma identidade qualificada `exo/<world-id>/<tipo>/<id-local>`; o protagonista usa o ID estável do mundo e `protagonist`, não seu nome editável. O mesmo ID local do Living World continua em rotina, contrato e memória. O destino narrativo legado preserva sua derivação original; não é rerrolado por migração.

## Persistência e propriedade

| Domínio | Dono lógico | Escrita |
|---|---|---|
| raiz v4, inventário, itens/equipamento e atributos | sistemas legados / Inventory | coordenador único |
| world e atlas/visitas/atores em convergence | Genesis / Convergência | coordenador único |
| convergence.ecology | Regional Ecology / combate | coordenador único |
| living_world | Living World | coordenador único |
| journey_dynamic | Jornada | coordenador único |
| narrative | Núcleo Narrativo | coordenador único |
| character.skin3d e skin_file | Skin 3D | coordenador único |
| exo_core | EXO Core | coordenador único |

`JourneySave.write()` é a fachada de compatibilidade. Ela passa pelo `save_coordinator.gd`, que valida domínios registrados e migração, e chama a primitiva privada de escrita atômica legada. Essa primitiva é o único escritor do JSON do jogo: temporário, flush, releitura/validação, backup e rename. Os módulos não serializam arquivos paralelos. PNGs importados permanecem em user://exo_skins, sem reencodificar a arte original.

A migração acrescenta somente uma extensão opcional schema 1 à raiz v4. Antes da primeira gravação sobre um arquivo legado, preserva seus bytes em `.pre-exocore01.json`. Saves v2/v3 seguem as migrações existentes. Arquivos inválidos/futuros não são descartados. O teste de interrupção encerra o processo depois do backup e antes do rename final; o processo seguinte recupera o último commit. Isso não equivale a teste de falha elétrica de hardware/fsync do sistema operacional.

## Arquitetura física

Todos os 163 GLBs estão presentes no catálogo combinado. O catálogo V02 integrado é preservado; somente IDs ausentes são acrescentados pelo catálogo V03. As casas e suas especializações existentes continuam nas parcelas de 10,8m. Templos e compounds V03 exigem parcelas maiores; não são encaixados à força nas casas atuais. As APIs e os laboratórios dessas composições estão incluídos e foram testados nativamente.

Forja é dona de casas e cercados de lote existentes. Fortificações é dona exclusiva dos anéis externos de cidade; o Core não aplica um segundo perímetro Forja sobre o mesmo anel. O planejador Fortificações foi versionado para 2: reserva maior nos portões chanfrados e tentativa determinística de margens alternativas. Planos parciais ou com travessias de rio sem solução física são marcados BLOCKED e não instanciados. Não são sucesso de muralha concluída.

Os anéis usam GLBs V03 de muralha, torre e portão, com colisores explícitos e batch estático. Aberturas muito largas recebem duas torres originais em vez de esticar o telhado do portão. Não há portas levadiças, interiores de torre ou cerco militar. A geometria nova não altera o grafo de 88 regiões.

## Limites

Três histórias narrativas são cenários lógicos e não missões físicas novas. Rumores são lógicos; não há tropas/facções físicas adicionais. O Core e Narrativa têm teto de 12.000 recibos; ao atingir capacidade recusam novos eventos em vez de apagar histórico. É necessária uma futura política de arquivo antes de campanhas que excedam esse teto.

A auditoria de referências detecta um ciclo legado por carregamento dinâmico entre `region.gd` e `world/village_v2.gd`; não há novo ciclo de preload no Core. O código legado ainda pode acessar campos diretos: a fronteira de serviços é obrigatória para módulos novos, e não uma alegação de eliminação de todo acoplamento histórico.
