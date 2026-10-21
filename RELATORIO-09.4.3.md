# EXO-Murim 09.4.3 — Correção de movimento e armas longas

## Origem
Atualização incremental do ZIP 09.4.2. Os arquivos de personalização e geração da vila não foram alterados.

## Correções implementadas

- `main.gd`: a cápsula do jogador recebeu snap de chão de 0,35 e margem física de 0,025; a posição de reaparecimento agora é conferida por raycast de colisões (solo inclinado, plataformas) e consulta de espaço livre com a mesma cápsula. Se necessário, procura pontos próximos. Incluí diagnóstico e **uma única** recuperação de travamento próxima ao local de nascimento se houver comando de deslocamento, mas o corpo não sair do lugar por 0,65 s. Não teleporta o personagem durante exploração normal longe do ponto de nascimento.
- `murim_flow.gd`: ao confirmar a criação de personagem, usa o mesmo posicionamento seguro para novos mundos, mantendo os pontos procedurais da vila.
- `arsenal.gd`: retirado o giro genérico -90° que apontava espadões, lanças, cajados e outras armas para baixo. Armas longas usam orientação vertical positiva e lâminas menores usam ângulo diagonal; transformações locais são armazenadas nos pontos existentes do antebraço.
- `qa0943.gd`: teste na cena real de chão, entrada de movimento e encaixe das armas. Executar `godot --headless --path . --script res://qa0943.gd` com Godot 4.6.2.

## Limitações e validação

ZIP, JSON e diferenças de arquivos conferidos. **Não foi possível executar a Godot neste ambiente**: o binário não está instalado e o download está indisponível. A movimentação e a aparência em jogo são, portanto, hipóteses implementadas que exigem teste no editor. Não declarar a falha como definitivamente resolvida até executar os testes.

## Reteste manual essencial

1. Cópia de save e novo mundo: andar WASD imediatamente ao aparecer; correr, pular e rolar.
2. Atacar parado e andando; verificar que o movimento não é bloqueado após atacar ou usar habilidades.
3. Espadão, lança, cajado comum e cajado arcano: girar, atacar e trocar de item sem pontas enfiadas no chão.
4. Confirmar que as vilas por seed, a personalização e o inventário permanecem como estavam.
5. Se continuar imóvel, conferir as linhas `EXO movement recovery` no painel Saída da Godot junto da mensagem de erro.
