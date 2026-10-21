# EXO Dungeon Genesis 01 — CANDIDATO DE INTEGRAÇÃO

**Ramo autônomo:** todo código funcional permanece em `res://exo_dungeon/`.
**Core de referência:** `EXO-Murim-EXO-Core-01-CANDIDATO-CORRIGIDO.zip`.
**Projeto incluído:** laboratório standalone Godot 4.6.2 Standard / Compatibility; não sobrescreva `project.godot` central.

## Sistemas funcionais entregues

1. Planta determinística multiandar com seis perfis e salas em grade espacial, árvore geradora, atalhos, segredos e fechaduras com chave adquirível antes do bloqueio.
2. Verificador de colisão lógica de salas, ligações, coordenadas e alcançabilidade do objetivo com estados de chaves. Rejeição de plantas inválidas.
3. Descritores de encontros, recompensas e armadilhas sem duplicar IA, loot, inventário ou economia.
4. Runtime Godot com pisos, corredores, portas, paredes e colisores físicos voxel originais, mais peças de demonstração distintas por família.
5. Domínio de persistência leve: descobertas, mecanismos, recibos, visitas, mudanças. Serialização fica com o save coordinator do Core.
6. Manifesto do módulo, inicialização, serviço público `dungeons`, execução QA massiva e smoke de renderizador em Godot.

## Limites explícitos

- É um **candidato**, não um sistema já instalado no jogo. A pasta inteira deve ser integrada pelo integrador central.
- Os marcadores de encontros/recompensas não equivalem a inimigos e itens jogáveis. Nenhuma API de concessão de loot é chamada.
- Os andares são planos 3D separados e o materializador posiciona marcadores de transição: não há interação de teleport, escada física ou retorno de personagem conectado ao controlador oficial.
- Os visuais são geometria voxel **própria** de laboratório; não pretendem reproduzir os GLBs/UVs da Forja 03, que permanecem no Core original e exigem inspeção visual na Godot.
- Não são afirmadas capturas reais, testes de performance, colisão jogada, FPS ou validação de scripts pela Godot quando ela não for executada.

## Como executar no computador

Abra o `project.godot` incluído em Godot 4.6.2 Standard / Compatibility e execute a cena principal. Teclas: `1..6` escolhem família, `R` muda seed, `Q/E` alternam piso. Para suites:

```bash
godot --headless --path CAMINHO_DA_PASTA --script res://exo_dungeon/tests/run_qa.gd
godot --headless --path CAMINHO_DA_PASTA --script res://exo_dungeon/tests/run_render_smoke.gd
```

**Não** execute contra a produção até o integrador conferir as interfaces e os assets efetivamente presentes no Core; depois rode testes de save v4, migração, regiões e gameplay.

## Polimento 0.2.0 — nota de integração

A geração usa um corte da árvore para impedir bypass dos portões; a chave obrigatória não deve ser colocada em segredo lacrado. Salas secretas podem não aparecer em alguns pisos. No runtime, a coleta usa `collect_key(room_id,key_id,actor)` e a abertura usa `unlock_gate(gate_id,actor)` — ambos recusam atores afastados. A carga do estado aceita snapshot opcional em `materialize(plan,persisted)`. Eventos locais de coleta e abertura exigem que o integrador confirme o delta com o Core antes do save definitivo. Portais agora exigem `request_floor_transition(source_room,actor)` seguido de `acknowledge_floor_transition(actor)` após resposta do controlador para evitar bounce automático. O controlador do personagem, UX, inimigos e inventário permanecem fora do módulo.

`tests/stress_reference.py` é somente um **modelo de referência Python**, não prova de execução nativa. Suítes Godot preparadas: `run_qa.gd`, `run_mechanics_qa.gd`, `run_render_smoke.gd`.
