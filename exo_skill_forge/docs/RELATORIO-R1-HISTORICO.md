# EXO-MURIM — Skill Forge 01 / Relatório de Entrega

**Status de entrega:** módulo independente candidato, com implementação de catálogo, composição de habilidades, encaminhamento das 16 técnicas existentes, interface de autorização para técnicas novas e QA offline aprovado. **Não declarar integração jogável** sem Godot e sem host de combate autorizado.

**Fonte auditada:** EXO-MURIM-CONVERGENCIA-03-ALFA-R13-1.zip, SHA-256 `e958f60ea4c4a1f44ed09ff2c2a24075e85d506d3a19d4ddbf09df9b8a97210a`.

## Resultado

| Capacidade | Entrega | Evidência |
|---|---|---|
| Biblioteca de técnicas | 44 fichas (16 legadas + 28 autorais) | `exo_skill_forge/data/*.json` |
| Criação sem programar nova classe | 10 templates e gerador de receitas em Python | `tools/add_skill.py` + `tools/example_recipe.json` |
| Dano/área/distância/Qi/stamina/cooldown | Balance e instruções de efeitos por dados | `runtime/planner.gd`, `runtime/validator.gd` |
| Escolas, estilos e armas | Referências ao catálogo da R13; filtros | `runtime/catalog.gd` |
| Técnica tradicional | Encaminhamento ao cast do host, nunca execução duplicada | `integration/legacy_bridge.gd` |
| Novas técnicas | Plano interpretável + serviço que falha fechado sem host | `module.gd`, `runtime/planner.gd` |
| NPCs/inimigos | Especificações de ator, diagnóstico de serviços, contrato com AI | `docs/CONTRATO-HOST.md` |
| Áudio por fase com múltiplos sons | 33 eventos OGG reais identificados por SHA em fonte própria | `data/media_sources.json` |
| VFX | 4 atlas de protótipos relacionados a técnicas | `data/media_sources.json` |
| Licença e segurança de mídia | Bloqueio até import e confirmação humana explícita | `runtime/validator.gd`, `docs/MEDIA-INTEGRATION.md` |
| QA Python | **20/20 PASS, 180.000 iterações**, 0 falhas | `tests/QA-OFFLINE-RESULTS.json` |
| QA GDScript + gameplay | **NOT_RUN**, pois Godot não estava instalada | `tests/qa_native.gd` preparado |

## Pontos críticos preservados

`techniques.gd` permanece como a única autoridade de Qi (`mana`), stamina e cooldown legado. O sistema de 3 slots iniciais/6 máximos continua na `data/slot_rules.gd`. `exo_martial` continua proprietário das técnicas e ensino vinculados a escolas, e `cultivation.gd` continua proprietário da aprendizagem. O Skill Forge não altera `EXO Core`, progresso do jogador, script da Convergência, inventário, save ou NPCs.

Uma nova técnica pode ser criada via JSON sem GDScript específico, mas **não será jogável até a integração do executor genérico com autorização oficial, desbloqueio, UI, persistência, animação e VFX/áudio**. Esta escolha evita dar poderes indevidos ao módulo durante a integração de C3 e impede duplicar HP/Qi/drops.

## Compatibilidade

Compatibilidade de **contratos estáticos R13 verificada**: IDs, 16 técnicas, escolas, estilos, armas, costs e campos, manifest EXO Core e Sound/VFX declarados. Compatibilidade em execução R13/R14/C3/Android/PC **não verificada**. O instalador rejeita bases com arquivos oficiais alterados e exige revisão manual para versões posteriores.

## Próximas responsabilidades técnicas

1. Executar QA nativo e importar na Godot 4.6.2 Compatibility em **cópia** da Convergência mais atual.
2. Implementar um `CombatHost` atômico confiável para interpretador de skills novas, reconhecendo school/cultivation/slots e recibos de cast.
3. Conectar o host às 28 técnicas autorais, somente após autorização de progressão e avaliação de balanceamento, e vincular animações.
4. Integrar Sound Forge 01/VFX 02 com aprovação de cada asset e escuta/inspeção real; medir simultaneidade e overdraw.
5. Regressão in-game real em PC Ryzen 3200GE/Vega8 e Android, com até 60 atores visíveis, sem executar técnicas em Crowd Illusion.

**Conclusão:** a fundação do EXO Skill Forge 01 está entregue como módulo e catálogo seguros, não como sistema novo que substitui o combate. As funções pendentes são explicitamente sinalizadas.
