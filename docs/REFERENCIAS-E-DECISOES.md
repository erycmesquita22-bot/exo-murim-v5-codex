# Fontes e decisões

## EXO fornecido

Consultado o pacote `EXO-Central-e-Identidade-Fontes.zip` desta conversa.
A auditoria lê o `rpg-content.json` fornecido: versão de conteúdo 14, com 75 classes,
38 títulos, 111 ativas e 165 passivas. A fonte de Origens contém 180 linhagens.
Esses números descrevem o arquivo consultado, não todo o conteúdo já executável
na Godot. Conferidos os IDs de 16 técnicas e 12 representantes raciais.

`tools/audit_catalogue.py` gera `data/SOURCE-AUDIT.json`, comparando os representantes
com as definições atuais. `data/ORIGINS-AUDIT.json` registra nomes, pais e requisitos
originais das 12 linhagens. Efeitos base, requisitos completos e escala racial são
identificados como adaptados ou pendentes; não foram silenciosamente considerados
portados. Os parâmetros de maestria mantêm a consulta da versão 05.

Referências de UI: `GuiCentral`, `CentralCatalog`, `MenuTheme`, `MenuArt`, `ExoHud`,
`HudSettings` e `HudPresentation`. Esta versão adapta a hierarquia para um único
navegador Godot. As quatro imagens de fundo continuam vindas do EXO.
O catálogo interno antigo deixou de ser usado como outra janela de navegação.

## Hero's Adventure: Road to Passion

Fonte principal pública: https://store.steampowered.com/app/1948980/Heros_Adventure_Road_to_Passion/

Estudados a apresentação oficial e três capturas oficiais: organização do HUD,
contexto do ambiente, personagens e leitura das ações. O material apresenta
aprendizado por manuais / mentores, encontros e consequências envolvendo relações
e facções. A interpretação para o EXO é privilegiar descobertas no mundo, contexto
visível e decisões com efeitos persistentes. Nenhum código ou arte desse jogo foi
incorporado ao projeto, nem todas as rotas foram jogadas ou auditadas.

Aplicado agora: separação entre conhecimento descoberto e catálogo; interface
única com prioridade legível; condições do encontro descritas em dados, separadas
da transação e da apresentação. Descobertas já existentes foram preservadas.

Preparação para o futuro: eventos com condições, escolhas, estados e consequências
salvas; rotinas de NPCs e relações de facção; variações de história com validação de
cada rota. Essas expansões não foram acrescentadas como botões vazios.
O combate desta base continua sendo de ação em tempo real.

## Sons físicos

- Kenney, Impact Sounds: https://kenney.nl/assets/impact-sounds
- Kenney, RPG Audio: https://kenney.nl/assets/rpg-audio
- Joseph Sardin, Archery: https://bigsoundbank.com/archery-s0549.html

As três fontes identificam os sons usados como CC0. Créditos e hashes estão em
`audio/FOLEY-ORIGEM.json`; as licenças dos pacotes Kenney acompanham os arquivos.
A soltura de arco foi separada em dois disparos individuais, com fade curto.
Os arquivos físicos substituem os cliques genéricos em ataques / passos. O áudio
mágico mantido vem do EXO e consta de `AUDIO-ORIGEM.json`.

A escolha foi feita por função e material: movimento, contato, disparo e mecanismo
são eventos separados. Impacto de corpo não toca no vazio. O alvo acolchoado usa
impacto de tecido / soco; o som metálico é reservado ao corpo mecânico e ao mecanismo.
A amostra incluída permite uma comparação auditiva humana dos arquivos selecionados.

## Renderização

Documentação oficial consultada:
https://docs.godotengine.org/en/stable/classes/class_viewport.html
https://docs.godotengine.org/en/stable/tutorials/rendering/multiple_resolutions.html

O projeto mantém Compatibility e a engine já utilizada. Prévias passam a usar
textura de viewport com resolução explícita e MSAA; as faces do corpo usam normais
planas explícitas. A escala considera o tamanho da janela, com teto por textura.
Não foram ativados recursos de pós-processamento indisponíveis nesse renderizador.
