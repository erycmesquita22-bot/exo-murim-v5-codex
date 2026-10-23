# EXO-Murim V5 — Character Refit 01 | Relatório de auditoria e implementação

**Base integral:** `EXO-MURIM-V5-OTIMIZACAO-URBANA-AC-CANDIDATO.zip`, preservada.
**Engine testada:** Godot **4.7.2**, Compatibility / Mesa llvmpipe, Linux. **Engine-alvo:** 4.6.2 — não testada aqui.

## Implementação

- Criado `exo_character_refit01/geometry.gd` como **única autoridade para as novas roupas Murim**, construídas como malhas vertex-color (mesmo material compartilhado) por articulação. Escolha de robes, túnicas, trajes de treino, faixas, cabelos, mantos e cores.
- `wardrobe.gd` substituído mantendo API `apply`, `piece` e `animate_cloth`, compatível com 64x64, corpo slim/clássico e escalas. A atualização remove os elementos visuais de roupa anteriores, em vez de somar novas malhas.
- `rig.gd` manteve todos os contratos de torso/limbs e animações; eliminada geometria da espada dummy e adicionados marcadores de empunhadura/bainha. `arsenal.gd` continua parentando a arma no **antebraço**, usando transform do novo marcador para compatibilidade.
- `exo_humanoids03_r2/scripts/actor_visual_adapter.gd` não gera mais roupas R2 duplicadas; seleção autoral válida preservada no estado visual/save.
- NPC System 04 e Multidão Fantasma recebem identidade estável para variedade de roupas, sem alterar lógica ou persistência.
- Prévia de personagem atualiza diretamente pelo mesmo `Wardrobe.apply`; inserida descrição do Refit na personalização.

## Evidências de testes

| Teste | Status | Observações |
| --- | --- | --- |
| Importação editor | PASSOU | Godot editor exit 0; sem parser errors encontrados nos logs analisados |
| QA de galeria visual | PASSOU | 4 personagens reais renderizados no Compatibility, screenshot anexado |
| Reequipagem de armas | PASSOU | 11 categorias em teste; `qa0932.gd` de regressão passou |
| Contrato R10 | PASSOU | 26 asserções, sem falhas, com novo estado sem meshes R2 |
| Contrato R2 de seleção | PASSOU | 22 asserções, sem falhas |
| Compatibilidade 64×64, slim e reapply | PASSOU | `qa_compatibility.gd`; sem falhas |
| NPC real e crowd visual | PASSOU | `qa_integration.gd`; sem falhas |
| Boot da cena principal | PASSOU | Godot exit 0, sem erros explícitos |
| QA completo de Skin3D (75 reaplicações + capturas) | NÃO CONCLUÍDO | Teste excedeu limite de execução sem relatório conclusivo |
| 4.6.2 e Android | PENDENTE | Validar em dispositivos/engine alvo |
| Polimento das 11 armas em todas as poses | PENDENTE | Montagem testada estruturalmente; aparência deve ser aprovada no gameplay real |

Nenhum `project.godot`, save, Core, CityForge, WorldGen ou menu foi alterado.

**Estado:** Implementado e parcialmente validado; não homologado até análise visual e testes na engine-alvo.
