# EXO-MURIM — CONVERGÊNCIA 03 ALFA R7 — RELATÓRIO DE ENGENHARIA

**Origem única:** `EXO-MURIM-CONVERGENCIA-03-ALFA-R6.zip`, SHA-256 `74badc58c82e417aa8b50f3a39fa93959a2c2dea6e4846c44e74a1b78ebf0957` — **conferido** antes da alteração. R6 preservada como arquivo independente.

**Estado:** CANDIDATO DE CÓDIGO; NÃO HOMOLOGADO, GODOT 4.6.2 NÃO DISPONÍVEL. Não há logs nativos, screenshots de jogo, métricas de GPU ou FPS. Não concluir que o jogo é executável por testes Python.

## Integração nova efetivamente escrita no código

1. `genesis/monument_reservations_r7.gd`: proprietário WorldGenesis, seleção de locais determinística **antes de qualquer lote comum**, proteção por retângulos reais da Forja, ruas cívicas, estradas radiais de portais, margens fluviais, bordas de região e amostras de relevo. Uma aprovação só é gerada depois que os verificadores autorizam a proposta. Sem sítio compatível: rejeita, não falsifica `approved=true`. Prioridade de famílias: escolas média/grande, templo, fortaleza e ruínas. **Não há garantia de instalar cada família em toda cidade**.
2. `genesis/settlements/settlement_planner.gd`: reutiliza a geometria oficial de ruas com método único `future_streets` e consulta footprints reservados para o poço e para lotes menores. Sem um plano cívico válido, a implantação nova é descartada e o loteamento oficial R6 é recuperado; campanhas com reserva previamente persistida bloqueiam replanejamento conflitante.
3. `genesis/region_data.gd`: contrato regional `monumental_r7` opcional e versionado, planejamento pré-lote, verificação adicional contra **segmentos de muralhas urbanas realmente calculados**, exclusão das áreas reservadas de vegetação e parcelas comuns. Regiões já visitadas antes da R7 permanecem legadas sem introdução silenciosa de novas construções. Regiões R7 persistidas mantêm seu layout mesmo com feature flag desabilitada.
4. `convergence/region.gd`: chama o `Builder.build()` original da Forja 04 **somente com recibo de reserva WorldGenesis**, sem aceitar receipts de laboratório; usa GLBs/colliders/estações do catálogo existente e publica `monument_portals`, `monument_stations` e `monument_build_summary`. Preserva o pipeline urbano/fortificações, mas possível interferência de decoração da Cidade Viva exige F5.
5. `exo_monumental/integration/interior_bridge.gd`: corrige portas de peças com yaw 0/1/2/3 e a rotação externa do complexo; nenhum marcador arbitrário a 0 graus.
6. `convergence/game.gd`: interação E com portas institucionais, cena própria `hall_interior.tscn` e `interior_builder.gd`, jogador único, teleporte para interior separado do exterior, retorno verificado por ray/cápsula, registros de visita sob o **JourneySave existente**, rollback de falha de escrita, recuperação em restart e morte. `restore_region` não regrava posição exterior antes de restaurar o interior ativo.
7. `exo_core/integrations/monumental_plans.gd`: serviço somente leitura `monuments.plans` v1.1.0 dá acesso aos footprints, reservas regionais e estações efetivamente instanciadas pelo WorldGenesis. Não há segundo SaveCoordinator ou propriedade duplicada de WorldGen/NPC.
8. `project.godot`: namespace de QA R7 e opt-outs `r7/monuments_enabled` / `r7/institutional_interiors_enabled`. Desligar visualização não elimina reservas de saves existentes.

## Observações restritivas

- O **catálogo** possui 11 layouts, 62 estações e 18 GLBs originais, mas a distribuição espacial efetiva nas seeds 101/816204/707/18026 ainda **não foi executada na Godot**. A quantidade de monumentos **materializados e jogados com sucesso é NÃO MEDIDA**, não zero provado. Ver `RESERVAS-E-COMPLEXOS-R7.json`.
- O Planner exige terreno preexistente adequado e a estratégia rejeita locais que pediriam terraços agressivos. Grandes seitas podem ser recusadas em centros urbanos congestionados; não foi introduzido um falso terreno plano ou contorno que corte ruas.
- Integração com NPCs publica estações semânticas com ID/posição/capacidade; **escalas reais de trabalho, rotas de patrulha e disciplinado marcial não foram homologadas**. Não teleporta NPCs para posições artificiais.
- A nova rota de interiores não usa a API Dungeon R6 para casas, não cria outro jogador e mantém um único checkpoint externo. Ainda é necessário validar abertura F5, retorno, recuperação pós-morte e posição da cápsula nas quatro rotações.
- Entradas monumentais de novas famílias de masmorra e novas rotinas de NPCs não foram impostas à R6. Dungeon física e loot R6 mantêm código idêntico, com QA de transações e física ainda pendente.
- Asset copyrights e uso comercial continuam com as restrições de R6; nenhuma skin em quarentena foi promovida.
- A R7 é **integração de código**, não aprovação do requisito visual de caminhar num complexo nem resultado de FPS na Vega 8.

## Testes executados

- Verificação SHA-256 de entrada R6: **PASS**.
- Bateria nova `C03_TRANSFERENCIA/qa_r7_static.py`: **52 PASS / 0 FAIL**, comparando arquivos com R6, catálogo, referências de `preload`, caminhos de rollback, proprietário do save e proteção de áreas; **não é parser GDScript**.
- `exo_dungeon/tests/qa_r2_reference.py`: PASS, referência geométrica Python, não Godot.
- `exo_items/tests/qa_atomic_r3_offline.py`: PASS, modelo de atomicidade Python, não transação Godot.
- `exo_dungeon/tests/static_audit.py`: 23 PASS com aviso de falta de ZIP histórico Core (ABI externa não testada).
- **NATIVE NOT_RUN:** Godot editor import, parser GDScript, R3–R6 GDScript, GLBs/colisões, locomoção F5, test runner `qa_c03_r7_native.gd`, 23 suítes Cidade Viva, testes de interior E/restart/morte, hardware/fps/memória Vega8, captura real. Nenhum desses pode ser divulgado como PASS.

## Bloqueios antes de chamar R7 de jogável

1. Importar Godot 4.6.2 Compatibility e corrigir todo erro real de script/shader. Antes, não é possível atestar instanciamento dos GLBs da Forja.
2. Medir, nas seeds 101/816204/707/18026, quantos sítios foram de fato aceitos, rejeitados e montados; verificar se uma cidade não perdeu densidade, acesso ou passagem fluvial; inspecionar região 78 e rios 14/26.
3. Fazer dois percursos E→salão→E→exterior, salvar dentro, reiniciar, morrer e testar falha injetada de gravação. Validar ambos os yaw rotacionados e cápsula física.
4. Confirmar acessibilidade dos portais a partir das ruas com navegação real, assim como colisões das fachadas e ornamentação da Cidade Viva. A checagem estática geométrica não é pathfinding de personagem.
5. Encaixar a disponibilidade das 62 estações nas rotinas efetivas de NPCs, sem usurpar o domínio das atividades; integrar Mestres R2 depois que a navegação física estiver provada.
6. Reexecutar testes nativos e adversos de Dungeon R6/Itens R3 e fauna R5. Medir performance em Ryzen 3200GE/Vega 8.

## Continuidade recomendada

R8 deve partir **deste ZIP R7**, jamais de R6 ou Cidade Viva como nova base; executar primeiro parser/QA nativo e corrigir rotas físicas e persistência. Após estabilidade, completar NPC station routing e fluxo de discipulado. Preservar todos os recursos herdados até auditoria de dependência/proveniência.
