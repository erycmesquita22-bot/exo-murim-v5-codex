# EXO-Murim V5 — base de desenvolvimento integrada

Godot **4.6.2 Standard**, GDScript, renderizador **Compatibility**.
Abra `project.godot`, aguarde a importação e execute F6 na cena `convergence/game.tscn` ou F5 no projeto. O jogo mantém menu, prólogo, criação de personagem e campanha procedural. A criação de personagem inicia a campanha no assentamento da seed escolhida. Os saves desta base usam o diretório próprio `EXO-Murim-V5`; saves anteriores não são requisito de compatibilidade.

## Controles

WASD: movimento; mouse: orientação; botão esquerdo: ataque; 1–6: técnicas; Espaço: esquiva; E: interação; P: ficha/missões; Tab: mapa; Esc: pausa/configuração. Próximo a um NPC acessível, E conversa; afastando-se do NPC e aproximando-se da porta, E entra no edifício. Dentro, E junto à saída retorna ao exterior.

## Integração

- EXO Core coordena os registros de serviço/eventos e a persistência existente, sem outro escritor de saves.
- WorldGenesis V5 **5.0.1** valida o atlas e entrega lotes aprovados ao Settlement. O algoritmo de topologia/atlas permanece uma dependência interna `genesis/v4`, conforme o contrato do pacote recebido; não há um segundo mundo concorrente.
- Settlement Forge **1.0.1** é o único materializador de assentamentos urbanos e dono do índice de edifícios/portais. Biblioteca completa de 52 plantas presente. O contrato de handoff recebido seleciona dez plantas térreas por função; isso não significa que todas as 52 variantes ou os pisos superiores estejam homologados.
- NPC System **0.4.1** é o único diretor/ator operacional dos habitantes. Living World conserva identidades; Settlement/WorldGenesis conservam vias e estações; narrativa/economia mantêm seus próprios domínios.
- As árvores NPC02, NPC03 e Interior Forge anterior foram retiradas. O materializador urbano antigo foi retirado. City Forge mantém planejamento semântico; Monumental mantém complexos institucionais; Dungeon mantém suas instâncias. São responsabilidades distintas.
- Economia opera com comerciante físico, carteira única, inventário e commit do Core. Conversas notificam o Core antes dos menus de comércio/treino, permitindo completar missões sem perder eventos.
- VFX Forge recebe eventos de release autenticados em processo pelo Techniques real. Não executa dano, não cobra energia e não cria outro controlador de combate.

## Recursos criativos

A atualização do Drive restaura **216 paletas EXO FighterArt** e **113 texturas/atlas de terreno**, mediante declaração explícita de autoria do proprietário; os comprovantes foram prometidos e continuam pendentes. Inclui **91 OGG Sound Forge** com hashes e IDs de geração, ligados ao mixer existente, e **42 modelos Forja reconstruídos do código fornecido**. O criador oferece categorias, quatro estilos e prévia animada; o Hive usa o rig completo dos NPCs e depende de corredores validados fisicamente. Consulte [DRIVE-UPDATE](docs/v5/DRIVE-UPDATE.md).

As 480 skins em quarentena, assets comerciais de terceiros e bibliotecas visuais antigas sobrepostas não foram importados. Os demais substitutos procedurais continuam identificados; a atualização não torna todo o conteúdo final. Fontes vendorizadas continuam fora da build; a UI usa a fonte técnica da engine.

Para regenerar os recursos novos: Python 3 + Pillow 12.3.0; execute `python tools/v5/rebuild_generated_art.py` e importe novamente no Godot. As especificações e o gerador estão no projeto; só incluem os substitutos ainda ativos e preservam as restaurações. Os 42 modelos Forja têm gerador separado tools/v5/build_forja_models.py, que usa NumPy e trimesh e atualiza seu catálogo. A execução normal do jogo não depende de Python nem dos ZIPs de origem.

## Testes reproduzíveis

```
python tools/v5/run_qa.py --godot /caminho/para/Godot_4.6.2 --output /caminho/para/resultados
```

O runner exige a versão oficial 4.6.2, usa diretórios de save isolados, conserva códigos de saída, exige resultados dos testes e também verifica erros da engine. Inclui carregamento de scripts/cenas/recursos, testes dos módulos e fluxos reais de campanha, interiores, NPCs, comércio, missão, combate, loot e dungeon. Não substitui QA humano ou de dispositivo. Os comandos e a cobertura efetivamente executados acompanham o pacote QA.

No ambiente Linux Codex:

```
bash tools/v5/install_godot.sh
bash tools/v5/godot.sh --headless --editor --import
bash tools/v5/godot.sh --headless --script res://qa/v5/integration.gd
```

`GODOT_BIN` permite selecionar outro caminho para o executável. O instalador baixa a distribuição oficial e verifica SHA-512. O wrapper usa diretórios XDG locais graváveis. Cada tarefa Codex já é isolada: use o checkout existente, sem criar worktree adicional.

## Estado e limites

Esta é uma base de desenvolvimento com testes identificáveis, não uma promessa de ausência de todos os bugs. Os resultados atuais estão em drive-final/ e drive-last-code/ no pacote QA; tentativas anteriores com falhas são histórico. Capturas OpenGL foram obtidas em Xorg virtual/Mesa llvmpipe; números desse ambiente não representam GPU de jogador. Exportação Steam/Windows, dispositivo Android, áudio em hardware, todas as seeds possíveis e homologação comercial integral não foram demonstrados. Arte, música/vozes e validação de plataforma ainda exigem produção/revisão conforme a lista de conteúdo a repor.
