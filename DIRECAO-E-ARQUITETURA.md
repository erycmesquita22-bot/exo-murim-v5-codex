# Direção preservada — escopo posterior à estabilização

EXO independente: RPG de ação isométrico com progressão por uso, exploração, treinamento e decisões, em mitologia própria com influência Murim. Minecraft Dungeons orienta legibilidade e impacto; Hero’s Adventure orienta liberdade e consequências; EXO Minecraft orienta progressão. Nenhum desses jogos é uma licença para copiar conteúdo.

## Capacidades futuras — projeto, não funcionalidades implementadas

| Domínio | Regra de implementação futura | Base atual preservada |
|---|---|---|
| Mundo | Seed do mundo e sub-seeds por região/domínio; evitar RNG global para decisões persistentes | Região fixa e vegetação com seed local; ainda sem streaming |
| Identidade | ID estável independente da instância gráfica; registro de estado por ID | UIDs de inimigos/itens e metadados estáveis dos quatro edifícios |
| Coop | Anfitrião decide eventos e alterações do mundo; personagens separados do estado regional | Saves locais; ainda sem replicação ou autoridade de rede |
| Destino de Vida | Sorteio persistido com versão da regra e seed do personagem; vantagens e desvantagens com caminhos próprios | Não implementado; não usar bônus provisórios falsos |
| Equipamentos/aparência | Peças com sockets, convenção de eixos, unidades, material e rig; receitas persistem IDs de componentes | Arsenal, Wardrobe e Anatomy separados; ainda sem catálogo completo de sockets |
| Progressão | Manter treino, maestria, requisitos e descoberta além do nível | Cultivation, Inventory, JourneySave e catálogos preservados |
| AFK | Persistir treino escolhido e relógio limitado, sem depender de renderização contínua | Não implementado |
| Monetização | Cosméticos e anúncios opcionais identificados; auditar licença de cada recurso | Não implementada |

Não afirmar que os sistemas atuais já resolvem essas capacidades. Extrações futuras devem ser incrementais: WorldState/CharacterState versionados, geradores puros com RNG próprio, região como apresentação do estado, adaptador de autoridade para ações. Preservar os IDs existentes em migrações. Esta revisão não adiciona essa infraestrutura sem uma necessidade jogável imediata.
