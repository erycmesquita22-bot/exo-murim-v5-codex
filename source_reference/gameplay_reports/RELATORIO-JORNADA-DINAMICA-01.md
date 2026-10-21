# EXO-Murim — Jornada Dinâmica 01

**Data:** 19/10/2026  
**Base usada:** `EXO-Murim-Mundo-Vivo-02-R2-VALIDACAO-FUNCIONAL.zip` — base R3 aprovada provisoriamente na rodada anterior.  
**Engine alvo:** Godot 4.6.2 Standard, renderizador Compatibility.  
**Estado desta entrega:** implementação-fonte integrada e testada **offline**; **não é aprovação de execução/jogabilidade na Godot**.

## 1. Auditoria real

A base foi extraída integralmente, com 3.541 arquivos de origem efetivos. Foram revisados `convergence/game.gd`, `convergence/state.gd`, `regional_ecology/rewards.gd`, `regional_ecology/director.gd`, `regional_ecology/territories.gd`, `living_world/quests.gd`, `living_world/bridge.gd`, `living_world/state.gd`, `living_world/factions.gd`, `journey_save.gd`, `inventory.gd`, `ui/pages/journal.gd`, `ui/pages/character.gd`, `ui/menu_shell.gd`, e os atlas nativos `101` e `816204`.

**Sistemas reaproveitados:**

- Atlas de 88 regiões, rotas e IDs estáveis do World Genesis.
- Territórios e mortes registradas com ID de geração (`eco/rXX/tXX/mN/gNNNN`), loot e XP regional.
- Banco `convergence.ecology.xp_total`, tabela aprovada de redução de XP, patentes por `regional_ecology/rewards.gd`.
- NPCs, profissões e identidades persistentes do Living World.
- `living_world.balances.bronze` e `living_world.reputation`, sem mexer na moeda legada `coins` (seu invariante é rígido).
- Inventário de 24 slots, material real `iron` e validação/transação existente de `journey.write()`.
- Menu `P > MISSÕES > Crônicas e contratos`, sobreposição de objetivo e diálogos por `E`.

Não foi criado outro worldgen, outro inventário, outro gerador de equipamentos, moeda legada ou sistema de NPCs.

## 2. Sistemas programados

### EXO Quest Engine (`res://journey_dynamic/`)

`quest_generator.gd`: gera ofertas de modo determinístico a partir do atlas, região, tipo de NPC, roster persistente, grupos reais e estado de renovação dos territórios. Pesquisa rotas no grafo de portais; recusa objetivos inexistentes, grupos parcialmente mortos e territórios ainda não renovados. Identifica um objetivo estável por contratante/tipo.

`quest_manager.gd`: persiste contratos, progresso, recibos específicos da missão, conclusão, reivindicação única, abandono, rastreamento, descobertas, histórico resumido e reputação local. Estados do fluxo: `AVAILABLE` (oferta), `ACCEPTED`/`ACTIVE`, `COMPLETED`, `REWARDED`; `CANCELLED` equivale à retirada da lista ativa com histórico.

`quest_ui_adapter.gd`: adiciona contratos ativos, objetivos, recompensas, disponibilização contextual por NPC, aceitação, entrega, reivindicação, abandono, rastreamento e histórico à página existente. Não substitui HUD/menus.

### Sete tipos implementados na fonte

1. **Eliminar inimigo** de um território real, validando UID da geração.
2. **Limpar território**, contando os membros necessários do mesmo grupo/geração.
3. **Visitar região** selvagem alcançável.
4. **Coletar ferro**, a partir do loot já existente em território hostil identificado.
5. **Entregar ferro** real do inventário a um NPC (consumo e save na mesma transação).
6. **Conversar com outro morador** da região de origem (ID persistente).
7. **Investigar ruína** real, usando um lote/posição gerado pelo Genesis e raio de interação de 7m.

O contrato **Estrada dos Salteadores** aparece prioritariamente para NPCs comerciantes, mensageiros e agentes da guilda, quando houver alvo válido. Pode ser seguido desde a vila até o território, combate, retorno ao contratante e recompensa via menu P. Se o atlas/território não disponibilizar alvo, o gerador não produz um contrato impossível.

### Progressão integrada

- A XP de mortes já depositada em `convergence.ecology.xp_total` é incorporada uma única vez ao progresso principal, por `combat_imported`.
- A XP de contratos e a pequena recompensa de primeira descoberta de região não sofrem redutor de combate.
- Níveis 1–50 usam a função de ranking existente, em vez de inventar nova fórmula.
- Um ponto adicional de atributo por subida de nível, gasto na ficha original; seis pontos fundadores continuam com sua lógica.
- Atributos avançados respeitam o máximo por atributo e os novos limites legitimados pelo progresso persistido.
- Conclusões concedem bronze Living World, reputação local e `comunidade`, e ferro opcional via `inventory.add`. Inventário cheio impede reivindicar recompensas materiais.

### Estado persistente

Uma extensão **opcional** `journey_dynamic` foi adicionada ao save v4, preservando carregamento de saves sem esta seção. A validação da extensão foi integrada a `journey_save.gd`; as contas de bronze/facções existentes continuam com a validação do Living World. Recibos de morte impedem contar duas vezes o mesmo adversário; contratos `REWARDED` não podem ser reivindicados novamente. A transação usa a escrita atômica `.tmp`/`.bak` preexistente e restaura o estado em memória se falhar.

**Limites atuais:** cinco contratos ativos; até 2.000 recibos de conclusão; até 256 acontecimentos no histórico exibido; descoberta regional independente (até 88). Estes limites evitam crescimento irrestrito; política de arquivamento para mais de 2.000 contratos é uma evolução futura.

## 3. Alterações de compatibilidade / preservação

- `convergence/game.gd` — instancia o módulo; envia entrada de região, conversa, morte e eventos de investigação; exibe objetivo rastreado.
- `inventory.gd` — emite o evento de coleta **antes** de `save_progress()`, na mesma transação do loot.
- `journey_save.gd` — valida/restaura a extensão nova e aceita pontos de atributos ganhos por nível sem ampliar os seis iniciais de saves legados.
- `ui/pages/journal.gd` — insere o adaptador na página Crônicas já existente.
- `ui/pages/character.gd` — expõe gasto de pontos obtidos em níveis.

Sem substituições em `main.gd`, World Genesis, `regional_ecology/rewards.gd`, diretor ecológico, rig, animações, arsenal, técnicas, World Clock, IA, assets, sons, projeto Godot ou prólogo. O manifesto SHA-256 enumera mudanças exatas.

## 4. Testes efetivamente executados nesta rodada

| Verificação | Resultado | Evidência/limite |
|---|---|---|
| Extração e auditoria da base R3 | **PASS** | ZIP de 176.333.858 bytes montado e comparado |
| Integridade estrutural dos scripts modificados | **PASS (léxico)** | Delimitadores balanceados e caminhos preload conferidos; **não é compilação GDScript** |
| Grafos/rotas do atlas nativo 101 e 816204 | **PASS (offline)** | Todas as 88 origens e todos os destinos por atlas alcançáveis nos descritores existentes |
| Checagem de referência e controle de fonte | **PASS** | 3.536 arquivos intactos, cinco modificados, seis adicionados, zero removido |
| Modelos independentes de recibos e transações | **PASS (offline)** | 24.000 cenários simulados em Python; não executaram o código GDScript |
| **Bateria offline total** | **PASS — 88.736 verificações; 0 falhas** | `journey_dynamic/qa_offline_result.json` |
| Parser/compilação/importação Godot 4.6.2 | **NOT_RUN** | Executável não disponível neste ambiente |
| Teste nativo `qa_journey.gd` | **NOT_RUN** | Entregue para execução no Work com Godot |
| NPC oferecendo missão → aceitar → combater → reivindicar | **NOT_RUN** | Depende de sessão Godot e evidências físicas |
| Save, encerramento do processo e reabertura com novo estado | **NOT_RUN** | Não afirmar persistência validada fisicamente |
| Regressões completas da R3 após as mudanças | **NOT_RUN** | Resultados anteriores da R3 **não** certificam a versão nova |
| FPS, P95, tempo de carregamento, memória | **NOT_RUN** | Não foram coletadas medições desta versão |
| Cinco capturas reais da Jornada 01 | **NOT_RUN** | Não foram inventadas capturas; imagens da R3 não são evidências da Jornada 01 |

## 5. Bugs / riscos tratados em desenvolvimento

1. **Busca com chaves incorretas de regiões:** corrigido o controle de visitados em BFS para indexação pelo número efetivo da região, evitando rotas falsas.
2. **Contrato em território ainda em renovação:** gerador agora consulta `defeated_at` e relógio (540s) e recusa grupo indisponível.
3. **Ferro coletado no território, mas missão originada na vila:** coleta compara região de origem do recurso, e não a do contratante.
4. **Morte em outra geração:** `on_kill` compara o sufixo de geração ao contrato original.
5. **Apenas XP regional:** sincronização por cursor `combat_imported` evita recompensar duas vezes uma morte ao reabrir.
6. **Bloqueio por cinco contratos:** incluída ação de abandonar contratos, com histórico e salvamento.

**Observação:** estes itens foram corrigidos a partir da análise da fonte e da lógica. Sem execução nativa, não são alegações de bugs reproduzidos e eliminados na Godot.

## 6. Validação obrigatória no Work/Godot antes da aprovação

1. Extrair o ZIP completo em pasta limpa e abrir `project.godot` na **Godot 4.6.2 Standard**, Compatibility; verificar importação sem erro de GDScript/shader.
2. Executar a suíte de lógica nativa: `godot --headless --path . --script res://journey_dynamic/qa_journey.gd` (trocar `godot` pelo caminho do binário se necessário). Arquivar stdout, stderr e exit code.
3. Reexecutar suítes oficiais da R3, em especial `convergence/qa.gd`, a bateria de Mundo Vivo, ecologia, rotinas, personagem, inventário e prólogo.
4. Com save de teste na etapa de aventura e seed **101**, entrar na região **86**; encontrar comerciante ou membro da guilda, interagir com **E**, abrir **P > MISSÕES**, aceitar **Estrada dos Salteadores**. Verificar a região de destino mostrada, atravessar portais, esperar spawn válido, derrotar inimigo regional e retornar ao NPC para resgatar a recompensa. Se a população comercial não estiver presente na região 86, localizar um contratante elegível em outro assentamento sem alterar o worldgen.
5. Testar os outros seis tipos: território de dois inimigos, região selvagem, ferro de saque, entrega de dois ferros, segundo NPC, ponto de ruína. Alternar entre regiões e reiniciar a Godot.
6. Casos de falha: inventário 24/24, interrupção antes de reivindicar, salvar e fechar após vitória, repetir entrada/região/conversa/morte, grupo parcialmente morto, NPC temporariamente em rotina, alterar alvo com save intacto, tentar reivindicar duas vezes.
7. Registrar ao menos **cinco capturas verdadeiras**, logs do console e snapshots JSON dos estados antes e depois; medir memória e P95 em condições equivalentes à R3.

### Critério de liberação

**Não liberar como versão jogável aprovada** enquanto houver `NOT_RUN` na importação Godot, no ciclo completo, persistência, regressão física e ausência de dupes. Esta entrega é uma candidata de integração, não uma R3 validada novamente.

## 7. Comandos de QA offline

```bash
python tools/qa_jornada_dinamica_offline.py
godot --headless --path . --script res://journey_dynamic/qa_journey.gd
```

O primeiro script executa apenas verificações offline; o segundo só funcionará quando a Godot estiver disponível.
