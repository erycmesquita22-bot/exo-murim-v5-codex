# EXO-Murim — NPCs de Haneul 01

Base: Coração 01 Visual 1.1 / Haneul V11, Godot 4.6.3 Standard, Compatibility no ambiente de teste.

## Origem e escopo

A Bíblia EXO-Murim V0.1 encontrada no histórico compartilhado define HWA-02 como vila do Vau de Haneul, Ji Wol como barqueira que conhece passagens e desaparecimentos no rio, e estabelece a regra de residência, agenda, relações, objetivo, decisões, recursos e destinos plausíveis para NPCs importantes. O `HWA02_manifest.json` fornece coordenadas fixas da travessia, cais e praça. Implementei cinco habitantes **apenas na vila**: Ji Wol, dois pescadores, uma moradora da praça e uma atendente da casa de chá. Os quatro moradores sem nome usam cargos, sem inventar biografias canônicas. Personagens de Yunseong, Mokjin e seitas não foram movidos para Haneul.

## Implementado

- Instâncias do GLB V4 original, mesmo rig, UV, rosto, animações Idle/Walk/Hit_Reaction/Defeat; roupas com cores distintas por material duplicado. Nenhum modelo facial novo.
- `CharacterBody3D` com cápsula e área de dano separada; 90 HP para Ji Wol, 60–70 HP para outros. Nome e vida acompanham cada ator.
- Cinco agendas curtas com pontos fixos, orientação e desvio básico de obstáculos; à noite ficam no ponto de residência. Golpe faz recuar e procurar abrigo. Não atacam o jogador.
- `T` conversa com o morador mais próximo. Ji Wol menciona a travessia e observa os viajantes. Se ferida, a fala muda para recuperação.
- Espada e artes de lâmina do jogador usam consulta física por área, linha de visão e lista de vítimas por golpe para atingir NPCs. Vida não depende de teste de distância simples.
- Save próprio `user://exo_village_npcs_01.json` guarda vida, posição e relógio; Começar nova jornada restaura o grupo. NPCs são invisíveis, sem colisão e sem simulação na estrada e nos interiores.

## Verificação executada

- Importação real: `qa/village_npcs/import.log` sem erro de script.
- Suíte headless `qa/village_npcs/suite.gd`, resultado `VILLAGE_NPCS_PASS`: cinco atores com rig e chão; Ji Wol na travessia, movimento, fala, dano 20 de 90 para 70 por área, sem duplicação no mesmo golpe, persistência de vida, suspensão/restauração em estrada e interior, agenda noturna, morte persistente e reset de nova jornada.
- `qa/village_npcs/routes.log`: os cinco moradores percorreram mais de 1 m em 3 s e continuaram apoiados no terreno.
- Capturas gráficas reais X11/Mesa llvmpipe 1280×800: `ji_wol_ferry.png`, `fisher_jetty.png`, `ji_wol_life.png`; `capture.log` registra `VILLAGE_NPCS_CAPTURE_PASS`.

## Limites

As cores variam, mas todos compartilham a silhueta, o rosto e o cabelo V4 enquanto os assets individuais ainda são produzidos. As agendas são rotas locais; não há navmesh global, travessia de balsa, troca comercial, missões ou reações sociais sistêmicas a agressões. A definição de relações, objetivo e destinos em `roster.json` é base de dados para evolução; não representa ainda todos os resultados narrativos possíveis da Bíblia. O usuário pode fornecer uma edição mais recente da Bíblia para revisão posterior. Não houve teste manual por jogador humano nem novo benchmark de FPS. Áudio gráfico usou driver dummy.

## Instalação

O ZIP de atualização aplica-se à cópia **Coração 01 Visual 1.1**. Extraia e execute `python3 install.py /caminho/do/projeto`. O instalador verifica hashes, salva backup e ativa `VillageNPCs_V11.tscn`. Há também projeto completo em TAR.XZ.
