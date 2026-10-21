# Consolidação 06

A causa da navegação duplicada era a combinação de `central_menu.gd` e o construtor
inteiro do antigo `exo_menu.gd`. A antiga UI também continuava sendo instanciada
como HUD escondido. Ambas foram retiradas, preservando as regras executáveis.

| Responsabilidade | Proprietário |
| --- | --- |
| Cena, física, câmera e integração | `main.gd` |
| Ataques, esquiva, dano recebido e projéteis inimigos | `combat/player_combat.gd` |
| Técnicas e seus executores | `techniques.gd` |
| Catálogos importáveis | `data/*.json`, acesso por `catalog.gd` |
| Metadados e capacidades | `data/slot_rules.gd` |
| Persistência e validação | `journey_save.gd` |
| Fluxo do prólogo e primeira jornada | `murim_flow.gd` |
| Regra declarativa de encontro | `data/encounters.json`, `world/event_rules.gd` |
| NPC / clima / transação do encontro | `encounters.gd` |
| Estrutura única de navegação | `ui/menu_shell.gd` |
| Roteamento e estado da seleção | `exo_menu.gd` |
| Conteúdo de cada domínio | `ui/pages/*.gd` |
| Pausa, diálogo, cursor e objetivo | `ui/runtime_ui.gd` |
| Integração narrativa e entrada | `pause_ui.gd` |
| Seleção e criação | `ui/prologue_picker.gd`, `ui/character_creation.gd` |
| Renderização e interação da prévia | `ui/portrait_stage.gd` |
| HUD de combate | `exo_hud.gd` |
| Eventos sonoros | `audio/events.json` |
| Reprodução, mixagem e volume | `exo_audio.gd` |

A navegação mantém o mesmo `PageSurface` ao trocar páginas; o conteúdo anterior é
liberado. Prévia usa uma textura do SubViewport, sem o auto-redimensionamento do
SubViewportContainer que fixava a resolução. Fechar a tela desativa sua renderização.

`main.gd` caiu de 936 para cerca de 720 linhas; `catalog.gd`, de 797 para 33;
`exo_menu.gd` passou de 516 para 90. Isso documenta a transferência de responsabilidades,
não uma medida de qualidade por quantidade de linhas. O acoplamento ao objeto da cena
ainda existe: a próxima separação pode mover estado de combate e serviços de mundo,
com testes de integração preservados. Não foi introduzido um framework genérico.

Os limites atuais continuam 3 ativas e 2 passivas. O executor usa o tamanho do conjunto
configurado, e o validador admite até seis ativas. O teste de quatro espaços verifica
execução, recarga, reset e persistência; não simula um sistema de níveis inexistente.

O encontro atual conserva seu estado no mesmo save. As condições e parâmetros foram
separados de sua apresentação / transação. Um catálogo de eventos não é, sozinho,
um sistema completo de histórias ramificadas. Novos eventos ainda exigem conteúdo,
estados persistentes, consequências e validação das rotas.
