# EXO-Murim 09.1 — Corpo Marcial e Combate Desarmado

## Resultado implementado
Preservados áudio, perfis gráficos, renderizador, vila, missões, inventário,
progressão, modelo de personagem e licenças da 09. Recursos binários comparados
por hash; nenhum novo modelo provisório. A direção artística oficial continua
sendo o espadachim Murim low-poly estilizado fornecido pelo proprietário:
segunda referência como padrão-base, terceira como evolução de equipamento.
São conceitos, não arquivos 3D, e não foram apresentados como malha integrada.

### Auditoria e composição
O controlador aplicava Arsenal.animate depois da locomoção, anulando poses de
braços; o adaptador visual também selecionava sempre Run_Weapon e era atualizado
fora do passe de habilidades/esquiva. Agora há uma composição explícita por
prioridade: meditação > esquiva > habilidade > ataque > aéreo > locomoção.

A avaliação do esqueleto do jogador ocorre uma vez ao final do passe de física,
com seleção de clipe, camada marcial e transição curta entre poses. A prévia
continua avaliando sua pose própria. AnimationTree não foi adicionado: o projeto
já combina rig procedural e AnimationPlayer manual; a composição ordenada
resolve o conflito sem substituir o controlador ou o sistema de acerto.

Run e Walk CC0 já existentes fornecem a base de braços/pernas. A fase acompanha
a distância efetiva; o corpo gira suavemente, com rotação pequena de abdômen e
cabeça. Tecidos do rig anterior recebem o sinal real de movimento. O cabelo do
modelo 09 acompanha o osso Head; não há simulação física independente dos fios.
A roupa usa a deformação esquelética existente, sem nova simulação de tecido.

### Equipamento e mãos livres
R alterna character.hands_free (bool opcional). A arma e seu UID continuam no
inventário. A especificação unarmed é um modo de combate, fora do catálogo de
itens: alcance de 1,45 m, dano-base 9, ciclos 0,36/0,40/0,48/0,62 s e potências
0,9/1,0/1,1/1,35. Soco esquerdo, direito, palma com dedos estendidos e finalização
com rotação de tronco/quadril e participação das pernas. As janelas existentes
controlam dano, contato, reação, crítico, impulso e áudio; não há arco de lâmina.
Manoplas preservam alcance 1,85 m, base 11 e combo equipado de três golpes.

Bainha de uma mão montada no corpo, transferência da arma para a mão em tempo
compatível com a janela de acerto, incluindo adagas rápidas. Duas mãos mantêm
a empunhadura durante exploração; R guarda para combate desarmado. A troca de
modo é bloqueada durante ações para não mudar o tipo de dano no meio do golpe.
Mesmo ataque que erra mantém postura de combate por quatro segundos; isso
impede embainhar no meio da recuperação e bloqueia configuração nesse período.

### Arquivos principais
- main.gd: entrada R e ordem do passe de composição.
- combat/martial_motion.gd: prioridades, orientação suave e apresentação do equipamento.
- combat/unarmed.gd: definição dos quatro golpes e pose procedural compatível.
- combat/player_combat.gd: comprimento do combo por modo, sem alterar os outros combos.
- characters/reference_visual.gd e martial_pose.gd: clipes, camadas de ossos e transições.
- rig.gd: rotação pequena de tronco. animation_library.gd auditado e preservado.
- arsenal.gd: bainha, anexos de duas mãos/Manoplas e despacho de pose desarmada.
- journey_save.gd: validação do campo opcional hands_free, sem migração destrutiva.
- ui/pages/inventory.gd e settings.gd: botão na página existente e texto do controle R.

## Validação executada
Godot 4.6.2, Linux, Compatibility. Onze suítes: tests, release_qa, discovery_qa,
fidelity_qa, consolidation_qa, ruins_martial_qa, assets_qa, stabilization_qa,
quality09_qa, martial_qa e war_qa. Logs do ciclo final no pacote.

martial_qa verifica mãos livres sem outro item, integridade de inventário,
save/recarga/retomada real, braços visíveis em Walk/Run, diagonal, quatro acertos,
palma com dedos estendidos, erro sem dano, saque, bloqueio de troca durante ação,
Manoplas iniciais/equipadas/guardadas, corrida relaxada com luvas, combo próprio,
esquiva, habilidade, bastão de duas mãos, colisão do limite e saque de adaga.
quality09_qa verifica novamente meditação e rotas de áudio narrativo/chefe.

O vídeo EXO-09.1-Corpo-Marcial.mp4 e as capturas são gerados na engine com
entradas reais do controlador por roteiro, em câmera lateral de inspeção.
Fixture declarada: personagem humano da 09, alvo de treino fixado a cada frame
para isolar animação/acerto e concessão explícita de um item Manoplas no roteiro.
O piso/colisões são os do pátio que já existia na 09; nenhuma região foi criada.
FPS fixo de 30 somente na gravação, nunca no benchmark. Não houve sessão humana.

## Desempenho e limites
Comparação isolada descrita em COMPARATIVO-DESEMPENHO-09.1.md, números brutos no
JSON. Mais 4 draw calls/48 primitivas da bainha, cerca de 0,3 MiB rastreados.
Host compartilhado e renderização por CPU impedem concluir um ganho estável de
FPS ou prever GPU/Android. A referência atual é preservada; isto é uma atualização
de movimento/combate, não a entrega da malha Murim definitiva. Não há novo elenco.

Conferência final do ZIP: extração nova, importação sem cache, boot normal,
assets_qa, martial_qa (41 verificações) e quality09_qa executados novamente,
sem erros. Logs fresh-* incluídos. CRC e hashes conferidos no arquivo final.
