# R10 — Atores/equipamentos e autoridade

| Ator | Conectado no código | Limite |
|---|---|---|
| Jogador | Sim, Flow.apply_character → Wardrobe/Skin3D → VisualR10; escolha em `character.visual_r2` | QA de aparência e save/reopen NOT_RUN |
| Residentes, comerciantes, guardas, discípulos | Sim, Resident.setup com papel oficial e UID LivingWorld | Rotas, densidade, performance NOT_RUN |
| Mestres R9 | Sim, quando mestre real/slot de escola existir; paleta Jade por ID de escola oficial | Nenhum mestre físico encontrado/comprovado em Godot |
| Hostis `Enemy` oficiais (blade/mage) | Sim, sem novo spawn/dano/loot | 8 Bestiário humanoid IDs ainda não garantidos |
| Bosses especiais | Mantidos com artwork anterior | Não receberam R2 para evitar conflito com apresentação especial |

`Arsenal.equip` continua produzindo malhas, empunhadura e bainha. `Skin3D.equipment_visuals` continua apenas visual sem atributos. R10 sincroniza duas mãos em evento e evita segunda bainha decorativa, sem prometer arma orientada perfeitamente. Não houve alterações de estatísticas, loadout nem ownership do inventário.
