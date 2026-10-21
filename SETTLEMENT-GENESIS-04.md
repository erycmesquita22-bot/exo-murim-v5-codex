# EXO World Genesis 04 — Settlement Core (implementação inicial)

## Escopo

Este pacote **não** representa uma conclusão do World Genesis, nem comprova que 88 regiões estejam prontas para jogo. É um avanço incremental sobre o **piloto 03**, introduzindo planejamento funcional de aldeias, vilas e cidades para regiões categorizadas como `settlement`. O World Atlas de 88 regiões, seus portais e o piloto de 7 regiões são preservados. A nova lógica **não altera** loot, personagens, missões, saves da campanha, armas ou interfaces.

**Atenção:** esse pacote vem como **fonte para o Work validar**. Os resultados históricos dentro de `evidence/` e relatórios 03 permanecem documentação do pacote base, não são evidência da mudança 04. Não houve certificação Godot da versão 04 nesta entrega.

## Arquivos efetivamente modificados

- `genesis/settlements/settlement_planner.gd` (novo): ruas e lotes, funções cívicas, reservas, fachadas, fundações adaptáveis, contratos serializáveis e validação independente.
- `genesis/region_data.gd` (alterado): usa o planejador somente para `settlement`; natureza, ruínas e masmorras mantêm o planejador prévio; distâncias das ruas são consultadas pela vegetação e pelo material do chão.
- `genesis/region_scene.gd` (alterado): os edifícios já disponíveis recebem metadados funcionais e a praça usa a âncora do plano em vez de objetos dispersos.
- `tests/settlement_core.gd` (novo): roteiro Godot para reproduzir atlas de 5 seeds, validar contagens, geometria lógica, exportação JSON e determinismo.
- `tests/settlement_geometry.gd` (novo): roteiro Godot para instanciar 3 assentamentos, conferir instâncias e superfícies.

## Contrato de dados

`SettlementPlanner.plan(spec, gates, rivers, half_extent, height_sampler, river_hub)` devolve `status`, `region_id`, `scale`, `target`, `lots`, `streets`, `fixtures`, `metrics` e `errors`. Em erro, `status=invalid`, incluindo os lotes parciais **somente para depuração**; o adaptador não instancia assentamentos parciais.

Cada lote inclui `id`, posição, altura, orientação, meia-extensão, porta, ponto de acesso à rua, função (`farmstead`, `inn`, `smithy`, `martial_school`, etc.), forma (`linear`, `L`, `courtyard`) e necessidade de fundação em terraço.

**Por enquanto, a forma e a função são metadados.** As cenas exibem a casa modular do piloto com modelos existentes; **não existem ainda edifícios 3D únicos** para mercado, escola marcial, residência em U e forja. Não declare essas fachadas como implementadas. `export_contract` gera JSON-portável sem serializar nós Godot.

## Diretrizes arquitetônicas

- Identidade única Murim (referências chinesas); variação climática/econômica depois, sem novas culturas arquitetônicas.
- Aldeia de 4–10 lotes; vila de 12–26; cidade de 35–48 na revisão inicial. São **parâmetros de protótipo**, não limites históricos nem capacidade final.
- A geração por seed usa domínio RNG isolado da progressão. Mesmo seed + mesma versão = mesmo layout.
- Os lotes são reservados após ruas e saídas regionais, evitando estradas para portais, rios e conflitos entre lotes.
- Não usar os assets finais como dependência do layout: substituir fachadas deve ser transparente para o planejador.
- Regiões com terreno impossível geram plano `invalid` em vez de reduzir arbitrariamente a contagem. Refinar a recuperação com reposicionamento e replanejamento antes de aprovar produção.

## Instruções para o Work

1. Abrir este ZIP como cópia, **Godot 4.6.2 Standard Compatibility**. Não reescrever o jogo principal.
2. Testar parser/import (`godot --headless --editor --path . --quit`), abortar se houver erros de parse.
3. Executar `godot --headless --path . --script res://tests/settlement_core.gd` e depois `.../tests/settlement_geometry.gd`, registrar stdout, stderr, versão Godot, falhas por seed e duração.
4. Rodar as suítes de regressão do piloto 03 (`tools/run_genesis_qa.py`) e comparar resultados com os relatórios anteriores. Separar regressões novas de limites existentes.
5. Em seguida aumentar o conjunto de seeds (`godot --headless --path . --script res://tests/settlement_core.gd -- 1000`), conferir densidade, estradas transitáveis, porta acessível, degraus/fundações, objetos nos caminhos, aparência e FPS nos assentamentos maiores. **Nenhum desses resultados é declarado aprovado aqui**.
6. Não alterar `GENESIS-VERSION.json` para fingir aprovação; atualizar versão e manifesto **após** validação e decisão de promoção.

## Limites importantes

Ainda não há gramática modular que combine fisicamente módulos de parede/telhado em casas I/L/U; ainda não há ruas com navmesh certificada nem IA/rotinas dos NPCs; terraços têm informação lógica, mas não malha de contenção; não foi feito o controle definitivo de streaming/culling por bairro para 48 construções. A validação em runtime deve rejeitar situações problemáticas, não mascará-las como aprovação.
