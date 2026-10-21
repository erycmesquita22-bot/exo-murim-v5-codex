# Matriz owner/consumer — Skill Forge R3

| Interface/tema | Owner autoritativo | Skill Forge pode | Skill Forge NÃO pode |
|---|---|---|---|
| Skills legacy, Qi interno `mana`, vigor, recovery | `techniques.gd` / Combat | Encaminhar ID legado existente à posição do loadout real | Debitar Qi/vigor ou duplicar cooldown |
| Novas skills | Combat owner v2 futuro | Catalogar e propor plano interno, encaminhar após binding confiável | Causar damage/HP, criar field/physics/collider sem host |
| Skills aprendidas, slots 3–6 | Journey/Cultivation/Core | Ler tags/requisitos | Dar unlock, mudar slots e hotbar |
| Mestres e Artes Marciais | `exo_martial` | Indexar escola, estilo, nível | Gerenciar relações/treino, autoconceder técnicas |
| IDs arma / pose equipada | Inventory/Exo Items/Combat | Classificar candidatos por arma, consultar poses catalogadas | Afirmar equipamento equipado por metadado do cliente |
| NPCs e inimigos físicos | NPC System/Bestiary/Combat | Entregar catálogo filtrado | Transformar Crowd em alvo/dano, criar IA nova |
| WorldGen, City R4 | World/City | Receber contexto e adaptadores futuros parametrizados | Alterar seed, regiões, cidades; especular API R4 |
| Save e ledger de receipts | SaveCoordinator/JourneySave | Nenhum escritor; contrato para receipt | Salvar itens, XP, HP, mastery, ledger próprio |
| Sound/VFX/Animation | Audio/VFX/Rig | Roteamento faseado e chaves pendentes | Fazer preload de mídias inexistentes ou usar mídia sem direitos |
| Traduções | Localization owner | IDs estáveis + nomes originais PT-BR | Inventar localizações finais EN-US e zh-CN |

Fallback: nenhuma API física certificada → `BLOCKED_HOST`, sem cast autoral; legacy permanece no host. Receipts só podem ser aceitos de host in-process confiável e persistidos pelo Combat/SaveCoordinator, não pelo módulo.
