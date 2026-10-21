# EXO-MURIM — RELATÓRIO DUNGEON GENESIS 01 — POLIMENTO 0.2.0

**Data:** 19/10/2026  
**Estado:** CANDIDATO DE INTEGRAÇÃO — SEM APROVAÇÃO NATIVA  
**Base real:** `EXO-Murim-EXO-Core-01-CANDIDATO-CORRIGIDO.zip`  
**SHA-256 da base:** `d6cae1fc95078b9b083755d68ee59c99568801e01fde8c5983366dc4c616f1ac`  
**Engine alvo:** Godot 4.6.2 Standard / Compatibility  
**Escopo:** somente `res://exo_dungeon/`, sem sobrescrever o Core.

## 1. Resultados efetivamente executados

| Verificação | Resultado | Evidência |
|---|---:|---|
| Auditoria estática de contratos, fontes e dependências | **26/26 PASS** | `evidence/QA-ESTATICO.json` |
| Referência procedural em Python, **após último ajuste de diversidade** | **36.000/36.000 PASS** | `evidence/QA-REFERENCIA-MASSIVO.json` |
| Amostra por família no teste de referência | **6.000 por família** | JSON massivo |
| Assinaturas distintas na referência | **36.000/36.000**, sem colisões na amostra | JSON massivo |
| Progressão inválida no modelo de referência | **0 casos detectados** | JSON massivo |
| Casos adversariais no modelo de referência | **245/245 rejeitados** | JSON massivo |
| Objetivo trivial imediatamente após entrada | **0 no modelo de referência após correção** | JSON massivo |
| GDScript executado nativamente em Godot | **NOT_RUN** | Executável Godot 4.6.2 ausente |
| Simulação física/CharacterBody3D e FPS | **NOT_RUN** | Requer Godot e controlador real |
| Salvamento real EXO v4 + reabertura | **NOT_RUN** | Requer Core integrado e Godot |

**Interpretação obrigatória:** os 36.000 casos rodaram em uma **transliteração independente Python com RNG diferente**, exercitando escolhas de topologia, encaminhamento de chaves, conectividade lógica e testes adversariais. **Não são 36.000 dungeons GDScript testadas no motor.** A equivalência exata de execução GDScript, o desempenho e a física continuam desconhecidos.

### Métricas do modelo de referência

- 36.000 dungeons geradas, distribuídas igualmente por seis famílias.
- 32.847 dungeons com pelo menos uma chave/portão; 30.540 com ao menos uma sala secreta.
- 54.000 transições de andar e 144.512 circuitos adicionais entre os grafos da amostra.
- 5 a 88 salas por dungeon; média 36,5. Variedade de `floors` de 1 a 4.
- Não significa que existam inimigos jogáveis, baús efetivos, puzzles interativos ou combate finalizado.

## 2. Bugs reais de lógica encontrados pela revisão e testes de referência

1. **Fechaduras apenas lógicas** na 0.1.0: o jogador poderia atravessar corredores sem impedimento físico. Criado `LockedSeal_*`, colisão e remoção controlada.
2. **Chaves autoatribuídas pela simulação de caminhos**: adicionado objeto de coleta não físico, validação de proximidade, evento `key_collected`, marcação delta opcional pelo integrador.
3. **Corredores abertos nas laterais**: adicionados trilhos/muros baixos com colisores, largura transitável prevista de aproximadamente 2,75 m.
4. **Atalhos capazes de contornar fechaduras**: o gerador agora marca como trancadas todas as ligações que cruzam o corte de progressão.
5. **Chaves sorteadas em salas secretas**: o teste de referência expôs objetivos inalcançáveis; o seletor agora exclui salas secretas como portadoras de chaves obrigatórias.
6. **Validação insuficiente por fechadura**: acrescentada prova de que cada portão obrigatório realmente separa lados do mapa sem sua chave, mesmo quando outros pisos têm fechaduras.
7. **Chaves sem fechadura e salas secretas sem passagem**: acrescentadas rejeições `orphan_key` e `orphan_secret`.
8. **Dungeons pequenas com final trivial**: a terceira sala tenta prolongar um ramo antes de expandir indiscriminadamente.
9. **Segredos quase invariáveis**: perfis de probabilidade diferenciados por família (0,53–0,76) criam mais diversidade de exploração.
10. **Obstáculo central de tumba**: deslocado para a lateral, liberando passagem/spawn no centro.
11. **Persistência visual de portões/chaves**: `materialize(plan, snapshot)` não reexibe lacres já abertos ou chaves já coletadas.
12. **Métodos de serviço de progresso**: incluídos `mark_key_collected` e `mark_gate_opened`, mantendo único domínio de save central.

13. **Risco de looping de portais ao tocar na área de chegada**: substituído acionamento automático por interação `request_floor_transition`, supressão de solicitações pendentes e `acknowledge_floor_transition` pelo controlador oficial. O portão/portal já não dispara apenas por contato de um inimigo ou chegada do próprio jogador.

## 3. Polimento e garantias possíveis

- A topologia é reproduzível por seed/ID e protegida por versão de gerador 2 + digest; não migrar layout de versão 1 implicitamente.
- Áreas principais sem chaves devem ficar inacessíveis até achar a chave necessária; atalhos não se tornam buracos na progressão.
- Portas de 3,2 m e corredor protegido têm análise geométrica nominal; **ainda falta colisão em Godot com personagem real**.
- O sinal `transition_requested` fornece contrato, não executa teleporte sem integrador.
- Inimigos, armadilhas, recompensas e boss continuam **descritores**: não chamar de gameplay concluído.
- Recompensas exigem operação atômica do serviço de itens com recibo único; o marcador de recibo isolado não basta para garantir ausência de duplicação em falha de energia/inventário.

## 4. Suítes nativas preparadas — NÃO EXECUTADAS

1. `run_qa.gd`: 7.200 casos por seed (1.200 por família), determinismo, validação, propriedades de grafo, adversariais, mock do Core e round-trip JSON.
2. `run_mechanics_qa.gd`: 144 cenas materializadas (24 por família), inspeção de trilhos e portões, interação de coleta/abertura com ator simulado, interação explícita de portal e tentativas repetidas.
3. `run_render_smoke.gd`: 6 casos físicos simples com `MeshInstance3D` e temporização do materializador.

Esses scripts exigem execução na Godot 4.6.2, idealmente em PC e com áudio/vídeo desabilitados para lógica; repetir depois com renderizador Compatibility real, sem headless, para verificar navegação e capturas. Nenhum dos 7.200 cenários nativos foi contado como aprovado.

## 5. Pendências bloqueantes para considerar o produto jogável

1. Importar e compilar GDScript 4.6.2 (versão exata não disponível no ambiente).
2. Usar CharacterBody3D EXO para percorrer colisores, portas, passarelas, chaves, portões, segredos e escadas/portais sem travar.
3. Instalar handlers de input/HUD no controlador oficial; este pacote **não os substitui**.
4. Integrar inventário/itens, encontros oficiais do Bestiário, IA, boss real, dano, loot e mecanismos de armadilha.
5. Integrar save v4 com transações, falhas induzidas, load em processo novo e migração do gerador 1 quando aplicável.
6. Testar desempenho físico real: draw calls, nós, memória, FPS médio, 1% low e P95/P99. A geometria de laboratório ainda cria muitos nós individuais.
7. Rever variedade visual, formas orgânicas de caverna, composição de salas, pistas dos segredos e ambientação artística Murim original.

**Veredito:** a versão 0.2.0 é mais segura na lógica e nas APIs do que a 0.1.0; o teste de referência ampliado demonstra ausência de falhas para a amostra avaliada, **mas não certifica que as dungeons estão jogáveis no jogo real**. Liberar somente como candidato de integração, sujeito aos gates nativos.
