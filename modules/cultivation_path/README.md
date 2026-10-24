# Caminho do cultivo — módulo 04

O projeto abre em `modules/village_npcs/VillageNPCs_V11.tscn`. O rig, malha, UV e texturas V4 permanecem os do projeto anterior. O módulo usa os quatro clips de cultivo já feitos para os mestres, aplicando a postura Idle aprovada ao mesmo esqueleto do jogador. Não há novo personagem nem textura substituta.

Na vila, fale com Ji Wol (`T`), depois com um mestre de cultivo (`T`). Vá ao círculo do pátio da seita ou à clareira do terraço e aperte `C`. Cada ciclo dura nove segundos; `C` interrompe. Fadiga acima de 80 impede iniciar, e acima de 65 impede avanço. Ela diminui com tempo de descanso. `J` abre a jornada e a escala marcial. Após os ciclos requeridos, `X` dentro do círculo realiza o avanço. A espada precisa estar guardada para iniciar cultivo. Dano, morte ou saída da área quebram a concentração.

A escala da bíblia é Comum, Terceira Classe, Segunda Classe, Primeira Classe, Pico Marcial, Transcendente, Supremo, Profundo, Harmonia, Natureza e Céu Marcial. Os estágios iniciais/intermediários/avançados estão implementados até Segunda Classe intermediária. Os demais são horizonte de conteúdo e permanecem bloqueados. As 12 camadas do mundo são outra progressão, não um sinônimo desses reinos. O início segue `O Preço do Rio`: a personagem é desconhecida, recebe orientação, treina postura/respiração e conquista o primeiro Qi. Não existe formação de núcleo neste início porque não é a nomenclatura da bíblia.

Arquivos: `progression.gd` contém estado, gatilhos, treino, fadiga, avanço, bônus modestos e UI; `ranks.json` é o catálogo de reinos. Estado por slot fica em `user://exo_cultivation_slot_N.json`; novo jogo zera esse estado. Contrato de integração: `configure(host)`, `use_slot(slot)`, `reset_state()`, `on_talk(npc_id)`, `toggle_cultivate()`, `breakthrough()`. Os IDs dos NPCs e locais são os do roster HWA-02.

Limites: não há campanhas além do início do vale nem prova jogável para Primeira Classe e acima; portanto os reinos altos não são liberados. A progressão atual usa ciclos e orientação para os primeiros estágios; provas marciais contextualizadas podem ampliar as condições em futuras regiões.
