# EXO-Murim 09.3.3 — Correção localizada de poses de armas (candidata para testes)

- Fonte: pacote completo 09.3.2; não altera `wardrobe.gd`, `exo_identity.gd`, recursos da personalização ou salvamentos.
- `arsenal.gd`: **retirado o alongamento `arm.scale.y`** no posicionamento da empunhadura de arco/besta; uso da articulação do cotovelo com dois segmentos fixos de 0.375 unidade, limitada ao alcance do braço.
- `arsenal.gd`: centralização da arma à frente do tronco durante arco/besta para reduzir alcance artificial e desconexão das mãos; preservei o sistema existente de munição, corda e ponto de disparo.
- `arsenal.gd`: fixação do armamento corpo a corpo mais próxima do pulso; orientação conforme família também para cajados, lanças, foices e martelos.
- `arsenal.gd`: bainhas convencionais menores e com afastamento traseiro mensurável; nenhuma bainha comprida para adagas, armas de haste ou armas à distância.
- `arsenal.gd`: objetos substituídos ficam invisíveis antes de serem enviados para liberação, evitando flash de duplicação num quadro.
- `qa0933.gd`: novo teste estrutural de comprimentos de braço, fixações, troca de categorias e bainhas.
- `qa093.gd`: corrigida expectativa antiga de pai da bainha (agora acompanha `torso`, não `pivot`).

**Limites:** Godot não está instalada neste ambiente. Integridade do pacote e inspeção estática não substituem teste visual de todas as poses; considere esta entrega uma candidata. Compare os testes com sua 09.3.2 aprovada em personalização, preservando o ZIP anterior.
