# EXO-Murim 09.4.4 — Base física da vila e retorno do treino

## Informações confirmadas pelo jogador
O movimento no modo treino funciona. O personagem pode ficar parcialmente enterrado e travado na aventura. A arena de treino usa plataforma física de colisão simples, enquanto a aventura usa um terreno triangular procedural. Isso orientou a correção sem mexer no sistema de movimento, animação e aparência.

## Código alterado
- `world/landscape.gd`: a malha de colisão passa a admitir contato dos dois lados. Acrescentado um `StaticBody3D` primitivo com `BoxShape3D` abaixo da região plana da vila, cobrindo o nascimento e caminhos centrais. O topo fica 2 cm abaixo do terreno original para não alterar a aparência nem bloquear o movimento. A arena separada e as regiões procedurais permanecem.
- `main.gd`: em raros casos de passagem sob a altura calculada do terreno durante aventura, o jogador é resgatado para posição segura. A rotina ignora o treino, a guerra do Panteão e saltos normais; não substitui as colisões físicas. Se a posição original estiver em colisão e todas as tentativas falharem, o fallback agora utiliza o corredor central livre, não a mesma posição bloqueada.
- `murim_flow.gd`: ao retornar do treino, volta a validar o contato com o solo na aventura; deixa de copiar diretamente a posição salva para dentro de uma colisão em mudança.
- `qa0944.gd`: teste executável que verifica nascimento no solo, deslocamento com entradas simuladas, entrada no treino, deslocamento no treino e retorno andando à aventura.

## Preservação
Arquivos de personalização, pele 64×64, sons, animações, arsenal, layout procedural, NPCs, inventário e missões permaneceram inalterados.

## Verificação
- ZIP e integridade dos scripts revisados serão conferidos antes da entrega.
- **Não executado:** Godot 4.6.2 e validação visual/física ao vivo; o binário não estava disponível neste ambiente. A falha só será considerada resolvida após o usuário executar o QA e testar o cenário real.

## Como testar
Com Godot 4.6.2, a partir da raiz do projeto:

`godot --headless --path . --script res://qa0944.gd`

Depois, iniciar uma nova jornada, andar pela vila, entrar no treino, mover-se normalmente e voltar para a vila. Conferir também uma partida 09.4.3 existente em cópia do save.
