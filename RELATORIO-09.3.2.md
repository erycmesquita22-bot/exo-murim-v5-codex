# EXO-Murim 09.3.2 — Correção de estrutura e retorno aos recursos originais EXO

**Base:** ZIP EXO-Murim-09.3.1-Revisao-Controlador.zip. Entrega para teste na Godot, não aprovada visualmente.

## Código alterado

- `arsenal.gd`: bainhas longas agora são anexadas à estrutura local do tronco, atrás do corpo e não ao pivô com offset aplicado por quadro. Armas de punho/adagas não ganham bainha de espada; espadão é ocultado quando guardado. Bainha começa oculta e nunca aparece ao mesmo tempo que a arma empunhada no jogador. NPCs não exibem a bainha duplicada enquanto usam a arma.
- `combat/martial_motion.gd`: removida atribuição fixa de `Transform3D` da bainha a cada quadro; ela só alterna visibilidade no estado guardado, seguindo a hierarquia anatômica. Empunhadura reposicionada na orientação local do antebraço para não atravessar horizontalmente a barriga em repouso.
- `audio/events.json` e `murim_flow.gd`: evento de descida do Deus Supremo passa a combinar `astral_rupture.ogg`, `energy_impact.ogg` e `eco_eco_boss.ogg` do EXO Visual, removendo a chamada genérica `landing`. As três faixas são disparadas somente no evento de contato da cena.
- `audio/skill_registry.json`, `audio/skill_registry.gd`: reforçadas as três fases originais do Salto Impetuoso (execução, vento no ar, contato no solo), com volume que não esconde o vento. Eventos sem arquivo não são marcados como tocados.
- `assets/exo_identity/base_0.png` até `base_215.png`: **216 texturas HD de 256×256 originais do criador EXO**, transferidas diretamente do ZIP-fonte. São imagens compatíveis com as coordenadas UV Minecraft 64×64 (escala de 4×).
- `exo_identity.gd`, `wardrobe.gd`, `ui/character_creation.gd`, `pause_ui.gd`, `journey_save.gd`: restauradas opções cosméticas que existiam no EXO original: seis cores de pele, seis de roupas, seis de cabelo, sete formatos corporais, quatro trajes, quatro cortes, quatro formatos de olhos, seis cores de íris, três intensidades de musculatura desenhada e três detalhes de rosto. Mantida a importação de PNG 64×64 sem modificações na textura do usuário. Saves antigos continuam aceitos porque novas propriedades são opcionais. O tamanho especial de entidades (ex.: Deus Supremo) não é mais sobrescrito pela escolha cosmética.
- `qa0932.gd`: testes estruturais para encaixes, bainhas não duplicadas, paleta e arquivos de áudio, **disponíveis para executar na engine**.

## Áudio original, direitos e fidelidade

As cópias de `ten/4_cast.ogg`, `ten/4_impact.ogg` e `wind_break.ogg` são **byte a byte idênticas** ao EXO Visual. O código do mod combina também sons nativos do Minecraft, que **não foram redistribuídos** no jogo independente. O áudio total do mod, portanto, não é reproduzido literalmente em todos os seus componentes; a sequência dos efeitos próprios foi restaurada e reforçada. Foram usados recursos pertencentes aos arquivos-fonte fornecidos, não gravações de franquias externas.

## Verificações executadas fora da Godot

- Confirmada integridade de 216 PNG originais, todos 256×256.
- Confirmados hashes idênticos dos três arquivos de Salto Impetuoso utilizados e de `astral_rupture.ogg` em relação aos originais.
- JSON válido em todos os arquivos do projeto (34 arquivos).
- Todos os `preload("res://...")` diretos apontam a arquivos presentes (auditoria estática).
- Verificado por leitura do código que o Deus Supremo não chama mais o som genérico de pouso e que o controlador não redefine a transformação da bainha.

## Limitações importantes

Não foi possível executar a Godot neste ambiente (binário indisponível). Ainda falta validar animações e posicionamento visual sob rolagem, golpes pesados, perfis de NPC e importação de skins em jogo. Os ataques complexos de duas mãos continuam dependentes de teste visual e polimento posterior. **Não interpretar as verificações estáticas como aprovação jogável.**

## Executar

Extrair o projeto em pasta diferente da versão anterior; abrir `project.godot` na Godot. Executar `godot --headless --path . --script res://qa0932.gd` e testar visualmente o personagem na criação, adagas, espada na mão/guardada, esquiva e sequência sonora do Salto Impetuoso, além da descida do Deus Supremo no prólogo. Preservar backup do save antes de abrir.
