# Revisão de segurança dos interiores — 21/10/2026

IMPLEMENTADO E VALIDADO em Godot 4.6.2 oficial:
- Colisores invisíveis em cada borda exposta do piso térreo, inclusive soleira e contornos côncavos. A saída continua sendo interação E.
- Recuperação automática para spawn autorado quando a posição sai do piso ou cai abaixo dele.
- Save de interior fora do piso volta ao spawn. Retorno externo é recalculado pelo prédio atual.
- Retorno manual pelo marco/laboratório encerra a visita antes de posicionar o jogador na região, restaurando exterior e visibilidade dos moradores.

Evidências nativas atuais:
- interior_safety PASS: 52 plantas, 1860 bordas verificadas por física; caminhada de CharacterBody3D por 120 frames em direção +Z desde o spawn de cada planta sem queda.
- campaign PASS: inclui queda forçada no void, recuperação automática, save inválido e ação manual de checkpoint durante queda.
- resources, gameplay e dungeon PASS.
- Logs: /workspace/exo-v5-qa/interior-fix e /workspace/exo-v5-qa/interior-safety-r2.

Limites: isto não homologa toda a navegação dos andares superiores, todas as posições de mobiliário nem todos os dispositivos. O teste de caminhada não percorre cada ponto da planta. Não houve alteração nos assets, áudio ou criador de personagens nesta revisão.

BLOQUEADO — atualização visual recebida por link:
https://drive.google.com/drive/folders/1pbNkQUM_HGhV0bQtSBHcv-zUsSCWqypj
A tentativa de acesso retornou curl 56: CONNECT tunnel failed, response 403. Não foi possível listar os arquivos; os nomes internos são desconhecidos. Não foram baixados, auditados ou integrados. Rascunho de rede salvo permitindo drive.google.com e drive.usercontent.google.com, ainda dependente de publicação/aplicação pelo ambiente. Nenhum bloqueio de rede foi contornado.

A autoria própria continua obrigatória conforme solicitação original. O projeto anterior deverá servir como fonte seletiva de recursos comprovados, sem sobrepor o código atual. Esta revisão é técnica parcial e NÃO constitui entrega da restauração visual nem homologação comercial.
