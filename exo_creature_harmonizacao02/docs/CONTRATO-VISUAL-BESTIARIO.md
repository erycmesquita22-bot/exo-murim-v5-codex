# EXO-MURIM — CONTRATO VISUAL BESTIÁRIO 02

**Escopo:** descrição de assets gráficos independentes. Bestiário 02 continua sendo autoridade sobre ID de espécie, IA, bioma, população, spawn, vida, dano, loot, recompensas, hitboxes funcionais e persistência. Esta entrega **não altera o EXO Core**, Convergência 03 ou Bestiário 02.

## Pipeline determinístico

`Bestiário 02 species.id` → `CATALOGO-CRIATURAS-UNIFICADO.json.assets_by_species[id]` → `recommended_variant.scene` → `PackedScene` + `AnimationPlayer` → `SOCKET_ATTACK_ORIGIN` e `collision_profile` descritivos → ação existente do Bestiário que decide a janela de dano/hitbox.

**Contrato de orientação:** GLB original usa **+X à frente, +Y acima**. Cena harmonizada aplica rotação Y de +90° para **-Z à frente**. A escala é proposta em wrapper visual, não deve ser aplicada outra vez ao ator físico. Dimensões de colisão são sugestões e ainda não validadas em jogo.

**Contrato de animação:** `idle`, `walk`, `run`, `attack`, `hit`, `death` permanecem como nomes brutos no GLB. Verificar o nome importado no AnimationPlayer (`nome` ou `GLB/nome`). A duração e os instantes válidos devem ser lidos da animação importada — **não há evento de dano embutido no GLB**.

**Sockets:** `SOCKET_ATTACK_ORIGIN` (ponto visual de origem de ataque), `SOCKET_VFX_CENTER` (efeitos), `SOCKET_BACK` (adornos/apoios). Anexados como filhos da junta correspondente; não são hitboxes, emissores ou gameplay.

## Ligações por ID real

| Bestiário 02 | Cena visual recomendada | Ações/ataques autorizados pelo Bestiário (não executados aqui) |
|---|---|---|
| `bear` | `res://exo_creature_harmonizacao02/scenes/bear/forge.tscn` | `paw_slam, bite` |
| `boar` | `res://exo_creature_harmonizacao02/scenes/boar/art02.tscn` | `tusk_charge, headbutt` |
| `corrupted_wolf` | `res://exo_creature_harmonizacao02/scenes/corrupted_wolf/forge.tscn` | `bite, lunge` |
| `deer` | `res://exo_creature_harmonizacao02/scenes/deer/forge.tscn` | `kick` |
| `fox` | `res://exo_creature_harmonizacao02/scenes/fox/forge.tscn` | `bite` |
| `leopard` | `res://exo_creature_harmonizacao02/scenes/leopard/art02.tscn` | `pounce, bite` |
| `mountain_goat` | `res://exo_creature_harmonizacao02/scenes/mountain_goat/art02.tscn` | `headbutt` |
| `rabbit` | `res://exo_creature_harmonizacao02/scenes/rabbit/forge.tscn` | `kick` |
| `snake` | `res://exo_creature_harmonizacao02/scenes/snake/forge.tscn` | `quick_bite` |
| `spirit_deer` | `res://exo_creature_harmonizacao02/scenes/spirit_deer/forge.tscn` | `kick` |
| `stone_guardian` | `res://exo_creature_harmonizacao02/scenes/stone_guardian/art02.tscn` | `paw_slam` |
| `tiger` | `res://exo_creature_harmonizacao02/scenes/tiger/art02.tscn` | `pounce, bite` |
| `wolf` | `res://exo_creature_harmonizacao02/scenes/wolf/art02.tscn` | `bite, lunge` |

## Sem GLB adequado no catálogo atual

- `wild_ox` — boi selvagem; não confundir com búfalo.
- `wild_buffalo` — búfalo selvagem; não confundir com boi ou capra.
- `qi_serpent` — serpente de Qi; não atribuir automaticamente a serpente comum sem identidade visual própria.

## Modelos artísticos fora do registro atual do Bestiário

`desert_monitor`, `desert_scorpion`, `demon_boar` e `kitsune` são modelos visuais, não entradas novas de IA/bioma. `corrupted_wolf` vem do modelo `shadow_wolf` do Forge, e `snake` do modelo `serpent` do Forge: ambos tiveram a correspondência registrada **explicitamente**, sem duplicar a espécie. A associação de `stone_guardian` ao modelo rochoso existente deve ser validada pela direção de arte, mas corresponde ao ID existente no Bestiário 02.

## Perfil descritivo de colisão

`variant.collision_profile.body_extent_xyz_scene_minus_z` fornece tamanho proposto para o corpo em coordenadas da cena-wrapper. `damage_zone = null`: IA/Bestiário define duração, raio, camada de colisão, máscara e aplicação de dano. Não instanciar formas simultaneamente se a criatura já herdar colisores do ator existente.

## Procedimento de integração futuro (não executado)

1. Copiar apenas `res://exo_creature_harmonizacao02/` ao projeto de testes; não apagar pacotes antigos ou substituir a rotina autoritativa.
2. O integrador consulta `integration/visual_catalog.gd` a partir do `species.id` existente e instancia **somente a apresentação visual**; mantém CharacterBody3D/IA existentes e seus eventos.
3. Conferir escala do protagonista, altura real dos pés, pivôs e orientação em animação, visual da câmera e colisão. Ajustar a escala de cada wrapper/descritor sob controle de QA.
4. Associar `attack` a eventos e janelas de dano do Bestiário 02, sem usar um ataque visual para executar dano por si.
5. Medir FPS/RAM em 4/8/16 atores no Compatibility, preservar capturas e falhas; só então promover.

**Estado:** contrato pronto para QA/integrador da Convergência 03, não instalado no jogo.
