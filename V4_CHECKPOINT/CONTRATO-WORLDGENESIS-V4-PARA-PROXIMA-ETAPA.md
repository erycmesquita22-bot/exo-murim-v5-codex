# Interface para o futuro WorldGenesis V4

Este documento especifica fronteiras; **não implementa WorldGenesis V4**. A autoridade atual continua C3 e seu grafo de 88 regiões.

| Campo / recurso | Contrato | Estado atual |
|---|---|---|
| `world_id`, `seed` | Identidade persistente; seed de campanha inteiro 0..2147483646. Não reseedar campanha existente. | C3 |
| `region_id` | Inteiro 0..87 em APIs de mundo. Interior aceita string somente na fronteira de identidade; normalizar no host. | C3 |
| `region_seed` | Preservar representação decimal; reduzir por `seed_mod` quando necessário. Não converter uint64 fora do alcance. | C3 |
| Bioma e tags | ID estável e tags explícitas; sem inferir riqueza de figurantes. | C3; tags adicionais são propostas |
| Portais e conexões | IDs e pares do grafo, orientação, âncora de chegada com chão e cápsula. | C3; topologia preservada |
| Lotes / ruas | IDs, função real, coordenadas, rotação, dimensões úteis e reservas. C3 é o owner da geometria. | C3; City R4 somente metadados |
| `building_instance_id` | Hash canônico de mundo/seed/região/assentamento/lote/edifício; não confundir template repetido com instância. | Biblioteca Interior implementa identidade; host persistente futuro |
| Interiores / portas | Pareamento por função e dimensões; recibo de seleção versionado, porta e retorno físicos, autorização conferida pelo owner, um commit de entrada/saída com rollback. | Interior Forge: tickets; transição nova BLOCKED |
| Revisão física | Revisão da cena materializada, recibo ligado à mesma revisão e região. Metadados planejados não contam como geometria. | Adaptador C3 Crowd implementado |
| Crowd | Zonas aprovadas, pontos 3D, envelope, limites e exclusões de portas/estações. Revalidar após materialização. Figurantes nunca persistem como NPC. | Até quatro faixas aprovadas; falha fecha a zona |
| Estações NPC | UID Living World, função, âncora comprovada, capacidade/fila/patrulha com colisão. NPC03 propõe, NPC02 move. | Movimento NPC02; proposta NPC03, execução futura |
| Economia | Perfis e produção por região; comerciante real/horário/reputação; IDs oficiais de inventário. Quote fingerprint e revisão do estoque revalidados no commit único. | Três bens ativos, demais bloqueados; restock autônomo futuro |
| Story anchors | ID estável e localização física confirmada. Biblioteca propõe; Narrativo confirma fatos, Jornada objetivos/recompensa. | PROPOSAL_ONLY; host narrativo ausente |
| Encounter slots | Owner de spawn, capacidade, família, UID/recibo e reservas físicas. Nunca criar executor de combate alternativo. | C3 herdado; expansão futura |
| Skills e audiovisual | Combate decide custo/hit/dano; Bridge emite fases/cast ID comprovados; apresentação não altera persistência. | 16 legadas preservadas; 168 e VFX novos bloqueados |
| Persistência | JourneySave + SaveCoordinator + ledger existentes; sem segundo arquivo/carteira. Recibos append-only, limites mantidos. | Implementado |

Os dicionários de propostas/tickets não são assinaturas: `verified_by_host=true` enviado por cliente não prova autoridade. Bindings de callbacks precisam permanecer privados ao integrador. Não publicar métodos privilegiados de autorizar comerciantes, casts ou Bridge.

A futura implementação deve demonstrar migração explícita de versões/recibos, save/reopen em processo separado, falha de gravação, inventário cheio, idempotência e cenas reais em Compatibility. Não alterar semântica de seed/topologia de campanhas existentes sob o mesmo número de versão.
