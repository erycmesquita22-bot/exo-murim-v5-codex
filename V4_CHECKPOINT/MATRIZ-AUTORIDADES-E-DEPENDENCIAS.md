# Autoridades no checkpoint

| Domínio | Owner único | Consumidores e limites |
|---|---|---|
| Registro de módulos/serviços | EXO Core | Dependências versionadas; módulos novos opcionais |
| Save e commit | JourneySave / SaveCoordinator | Domínios registrados; sem gravação independente dos adapters |
| Seed/atlas/portais | WorldGenesis C3 | City acrescenta metadados; Terrain R3 somente preview |
| Geometria/lotes | Materializador C3/Forja | Crowd recebe aprovação física após commit |
| NPC persistente/carteira | Living World | Economy confere UID e ator físico; NPC03 apenas propõe |
| Movimento de NPC | NPC02 / Resident | Agenda NPC03 não substitui o controlador |
| Inventário | Inventory C3 | Callback privado faz staging de três mapeamentos |
| Comércio | Economy | Estoque, revisão, preços e recibos no domínio aprovado; sem restock sem owner |
| Jornada | Manager existente + extensão 02 | Recompensa legada preservada; história nova bloqueada |
| Fatos narrativos | Núcleo Narrativo | Biblioteca/Jornada02 sem permissão para commit de história |
| Combate/energia | Runtime C3 / Techniques | Skill Forge não cria executor ou custos paralelos |
| Portas/interiores | Host C3 existente | Interior Forge retorna tickets; transição nova desativada |
| Apresentação | Crowd / VFX | Crowd efêmero e comprovado; VFX sem Bridge fica bloqueado |

As versões e dependências exatas estão no `exo_core/modules.json`. As funções extraídas dos providers estão em `API-REAIS-EXTRAIDAS.json`; o registro de serviços restringe métodos públicos. Bindings privilegiados não devem ser publicados.
