# EXO-Murim — WorldGenesis V4 integrado, candidato 03

20/10/2026. Projeto integral Godot 4.6.2 Standard / Compatibility. A Convergência V4 final não foi iniciada. A WG4 está efetivamente ativa na geração de campanhas novas; a entrega não declara todo o ecossistema V4 concluído.

## Base e preservação

Base obrigatória: EXO-MURIM-V4-PRE-WORLDGEN-COMPAT-01-CHECKPOINT.zip. CRC e 6.046 entradas verificados. SHA-256 `77fadde057e6e4c25bd9add9f2cabf9e1839e21bb203bcbb836185e19d108c8e`. A continuidade partiu do Candidato 01 integral recuperado, não de um novo merge; refinamentos posteriores foram reaplicados e todos os resultados abaixo repetidos sobre os arquivos recuperados.

Main, controlador, rig, inventário, combate, Techniques, JourneySave, SaveCoordinator, atlas LAB2 e texturas aprovadas permanecem byte a byte conforme o manifesto. O único callback novo no criador fixa a versão da geração antes do início da aventura. Não há segunda carteira, persistência, IA ou combate. QA histórico foi preservado nos caminhos originais; os resultados desta entrega estão em `evidence`.

## Comprovação de execução V4

O criador grava `convergence.worldgen_v4={schema:1,generator:4}`, `regional_version=7`, atlas completo, perfis e templates congelados. O RegionData da cena real entra no ramo WG4. O validador rejeita combinações incoerentes de marcador/versão, sem fallback silencioso. A normalização pelo mesmo JSON do JourneySave antes da primeira construção evita divergência de números nativos após reabertura.

Foram criadas campanhas reais 707 e 18026, carregadas regiões montanhosas 3 e 6, comparadas alturas com o ramo C3 e salvas/reabertas em outros processos. Digest físico e hash do atlas foram preservados. Mesmo com a flag global de novas campanhas desligada no reopen, ambas continuam WG4. Terrain Forge executou e o material real estava habilitado. O teste 101 aprovou 20 checagens físicas, 276 amostras de corredor sem bloqueio, 3/3 marcos com ray/cápsula e travessia real por E até vizinho conectado. Reabertura passou nas seis checagens.

Um save criado na base pré-WG foi aberto na nova versão: continuou C3 na cidade 78, com serviços preservados. A flag global false não faz downgrade de saves V4.

## Mundo gerado

O grafo de 88 regiões, os IDs, os pares de portais, os rios macro e as quotas 23 assentamentos/12 ruínas/10 acessos de dungeon/43 áreas abertas foram preservados. A comparação usa a representação JSON persistível dos contratos numéricos.

O gerador regional V4 aplica oito perfis autorais com relevo/vegetação próprios, orientação e largura/offset de cristas por seed, ruído macro, agrupamento de árvores, transições de bioma de 80m e hub/largura de rios em áreas abertas. Os 24 nomes autorais de relevo são vocabulário de apresentação; a variedade física vem dos parâmetros e do ruído dirigido, não de 24 algoritmos independentes.

Passagens interativas abertas ficam a 76% do raio e a chegada acompanha fisicamente. O exterior da região continua existente. A redução média centro→passagem aberta foi 62.10m; isso não representa encurtar todas as ruas urbanas nem reduzir todo percurso em 24%.

Quatro templates originais de marcos, com IDs locais estáveis, são colocados fora de rios/ruas/footprints e aprovados fisicamente antes da leitura por E. Foram propostos 586 marcos nos 352 planos; somente os marcos das cenas amostradas receberam aprovação física nesta rodada. Não foram concedidas recompensas/quests/fatos artificiais. A densidade útil aumenta por marcos e deslocamentos menores; não houve aumento global de árvores.

| Seed | Nomes de relevo usados | Árvores C3 → V4 | Diferença média de altura amostrada | Famílias R7 materializáveis V4 |
|---|---:|---:|---:|---|
| 101 | 17 | 12.619 → 12.258 | 2,060m | 5 escolas médias / 2 templos |
| 816204 | 18 | 12.785 → 12.445 | 2,101m | 5 escolas médias / 2 templos |
| 707 | 17 | 13.286 → 12.895 | 1,730m | 4 escolas médias / 3 templos |
| 18026 | 15 | 14.793 → 14.246 | 1,537m | 2 escolas médias / 5 templos |

Valores agregados por 88 regiões de cada seed; altura em grade de 25 pontos/região. As propostas R7 respeitam o validador existente; grandes seitas que não cabem continuam rejeitadas. Não foram encontrados trechos submersos nas amostras centro→passagem; isso não é prova física exaustiva de todos os cursos d'água.

## Integração e limites

Biblioteca Universal foi efetivamente consultada (264 propostas no atlas 101), e apenas vocabulário compatível direciona famílias R7/templates físicos. City Forge compõe e enriquece semântica; traçados/lotes comuns continuam do host legado. Conflitos com rios/monumentos causam manutenção explícita do plano original, não aprovação artificial.

Crowd na cidade 78: 1.372 amostras de geometria, quatro zonas, 16 figurantes após commit; não criam UIDs de NPC. NPC03 fornece proposta de agenda, NPC02/LivingWorld continuam com identidade/movimento. Economia usa comerciante físico e três bens, carteira única e commit atômico. Interior Forge permanece catálogo/ticket; Jade/dungeon legados continuam funcionais. Terrain Forge R1 é físico; resolver R3 registrado não significa substituição visual R3. As fronteiras completas estão em [MATRIZ-C3-V4.md](MATRIZ-C3-V4.md).

## QA real e estados

PASS: importação final e parse 602 scripts, 12 suítes Work na base e 12 no candidato, 12 suítes legadas, 352 regiões de dados, três campanhas novas/visitas/reloads amostrados, travessia E, marcos, mercador/rollback/idempotência/inventário cheio, Crowd, dungeon/Jade e 14 verificações gráficas de movimento/combate/exploração/save/reload. O teste de salto mede o pico em 40 ticks físicos para não perder o salto entre frames lentos; limiar e controlador foram preservados.

FAIL atual: nenhum teste funcional executado acima. Houve tentativa gráfica bloqueada pela ausência de display antes de restaurar o compilador de teclado; o resultado inicial está registrado como tentativa, e a rodada válida foi repetida. Falhas antigas da sessão anterior não são apresentadas como evidência atual.

BLOCKED: City físico completo, NPC03 físico, novos interiores, Terrain R3 visual, 168 skills, VFX sem Bridge e histórias/recompensas sem autoridade. NOT_RUN: homologação Vega8/Android, caminhada humana, aprovação artística, campanha longa e todas as regiões físicas. [QA-WORLDGENESIS-V4.json](QA-WORLDGENESIS-V4.json) distingue cada caso.

## Desempenho — medição limitada

Processos gráficos sequenciais, cidade 78/seed101, ortho 15, 1152×720, 240 frames com entrada automatizada, 65 NPCs reais e 16 figurantes. Renderer Compatibility em Mesa llvmpipe (CPU), sem FPS fixo e sem outros testes simultâneos.

| Métrica | C3 | V4 |
|---|---:|---:|
| FPS médio | 14.55 | 15.25 |
| 1% low FPS | 9.05 | 6.88 |
| P95 frame, ms | 89.651 | 76.532 |
| P99 frame, ms | 106.497 | 95.085 |
| P95 monitor de processo Godot, ms | 88.649 | 216.658 |
| Draw calls P95 | 665 | 680 |
| Memória estática Godot pico, bytes | 321828251 | 320907675 |
| Caminhada automatizada, m | 58.71 | 55.83 |

A média/P95 melhoraram nesta rodada, mas o 1% low da V4 piorou. Não se declara ganho geral nem meta de PC modesto aprovada. Uma execução A/B em CPU não homologa Vega8 ou Android. A duração em frames gera distâncias diferentes conforme o FPS. Memória estática não é RSS total e o monitor Godot não é percentual de CPU. Consultas de altura em terraços planos foram otimizadas sem mudar a superfície; demais orçamentos e culling existentes foram mantidos.

## Entrega e recuperação

O ZIP é projeto integral, com project.godot na raiz, fontes, assets, relatórios, QA e dez capturas atuais. [ABRIR-E-ROLLBACK.md](ABRIR-E-ROLLBACK.md) contém execução, flag e recuperação. [PENDENCIAS-CONVERGENCIA.md](PENDENCIAS-CONVERGENCIA.md) registra a etapa futura. `MANIFESTO-ALTERACOES.json`, patch textual e inventário de evidências acompanham o projeto. Hash do próprio ZIP está no SHA256SUMS externo para evitar autorreferência.

Checkpoints integrais: Candidato 01, SHA `0f5e19314a4839e6d932ec8639a8e10fb628eb78cd83be2a6dc67833fdf967cd`; Candidato 02, SHA `1ce7733f8ea29fd1f062401cf1e17e0be7ea9a7903ccfb5be5a12e8a3050115b`. São recuperações de desenvolvimento; usar o Candidato 03 final desta entrega para avaliação. Sempre recuperar código e save compatíveis juntos.

Validação de reconstrução: o patch foi aplicado sobre cópia limpa da base; todos os 47 arquivos declarados coincidiram byte a byte. A cópia reconstruída importou sem erros e passou na criação da seed 707 e reabertura em outro processo, com digest físico e atlas preservados. Logs `patch-replay.json`, `replay-import.log`, `replay-new-seed.log` e `replay-reopen.log`.
