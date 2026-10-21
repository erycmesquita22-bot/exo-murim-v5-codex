# EXO-Murim — Assentamentos e NPCs 03

Base: **EXO-Murim-Convergencia-01.2-Refino-Visual-02.zip**. Continuação da Convergência 01.2, em Godot 4.6.2 Standard, Compatibility. Data: 18/10/2026.

## Correções implementadas

- **Moradores diante da fachada:** as antigas filas de duas pessoas, que cresciam em direção à rua, foram substituídas por uma linha lateral. Duas alas deixam 2,5 m livres entre seus primeiros pontos, preservando a porta. Pontos consecutivos da mesma ala ficam a 1,5 m; a profundidade diante da fachada é constante. A orientação vem da rotação real do lote, e cada ponto usa a altura do terreno. O passeio pode acomodar a extensão lateral de grupos maiores.
- **Aldeias e vilas mais compactas:** candidatos de lotes ao longo das ruas, grade de apoio de 18 m e ruas cívicas mais curtas. Os lotes continuam reservando a geometria completa. Contagens, funções, identificadores e determinismo por seed foram preservados. Cidades mantêm o desenho anterior. Rios, poço, acessos e passagens regionais continuam restrições do planejador.
- **NPCs somente na visão útil:** corpos e nomes são ocultados fora do enquadramento ou quando o corpo está obstruído. O teste usa raios ortográficos contra terreno e construções, mais os volumes reais das malhas dos telhados, que não possuem colisores de gameplay. A identidade, os horários e os deslocamentos continuam sendo simulados; oclusão não remove moradores do save. Interação exige corpo visível e proximidade.
- **Saves antigos:** versão regional 5 / planejador de assentamentos 4 / rotinas 3. O validador aceita versões regionais 4 e 5, incluindo números relidos de JSON. Coordenadas e índice de percurso de rotinas antigas são recalculados; nomes, atributos, moradia, trabalho, visitas e conversas são preservados. A estrutura raiz do save permanece na versão 4.

## Reprodução e ciclos de correção

1. Na base Refino Visual 02, região 78 / seed 101: hospedaria com 11 moradores e vários estabelecimentos com oito pontos em filas avançando para a rua. Medição registrada em `convergence/validation_frontage/before.log`.
2. Correção da linha de fachada e teste físico: nenhuma interseção entre as cápsulas estacionadas e os edifícios nas regiões 86, 15 e 78. Distância mínima medida entre pontos: aproximadamente 1,5 m. Variação de profundidade por fachada inferior a 0,01 m.
3. Compactação e revalidação do planejador, das superfícies, de todas as portas da amostra integrada e das travessias dos sete pilotos.
4. Captura real identificou NPCs parcialmente visíveis atrás de telhados sem colisores. Acrescentados testes de oclusão pelas malhas dos telhados e reexecutadas as verificações locais, a integração e as capturas.
5. O gate inicial terminou **FAIL, 35/38 grupos**, por recursos de áudio ainda em uso em `martial_qa`, `war_qa` e `encounter_qa`. As verificações funcionais desses três testes passaram, mas isso não foi considerado aprovação dos processos. A limpeza das fixtures foi corrigida com parada do mundo e/ou espera real para a fila de áudio, sem modificar o controlador de áudio. Os três processos foram executados novamente e terminaram com código zero, sem os alertas. A execução inicial permanece registrada.
6. `assets_qa` ainda procurava uma casa importada pelo nome antigo depois de o criador trocar para a vila procedural V2. A fixture agora instancia o asset real explicitamente para testar translucidez e recuperação de opacidade. As verificações foram mantidas: **30/30 PASS renderizadas**.

## Medições do posicionamento

Mesma seed 101, mesmo conjunto de construções. Raio = distância do centro do assentamento até o centro do lote mais distante; não é medida da área edificada.

| Região | Escala | Construções antes/depois | Raio antes | Raio depois | Vizinha mais próxima, média antes/depois |
|---|---|---:|---:|---:|---:|
| 86 | Aldeia | 4 / 4 | 44,55 m | 28,46 m | 31,50 / 27,08 m |
| 15 | Vila | 13 / 13 | 64,14 m | 55,91 m | 22,00 / 21,58 m |
| 78 | Cidade | 43 / 43 | 104,36 m | 104,36 m | 22,00 / 22,00 m |

A aldeia tem raio ocupado 36,1% menor; a vila, 12,8% menor. O resultado continua procedural. Não foram acrescentadas casas para preencher os espaços.

## Testes executados

| Verificação | Resultado |
|---|---|
| Importação, arranque e execução na Godot 4.6.2 | PASS |
| QA específico: linha única, separação, colisões, oclusão física e por telhado sem colisor, fora de tela, migração e versões JSON | **33/33 PASS** |
| Planejamento de 1.265 assentamentos / 20.910 lotes, incluindo determinismo e contrato JSON | PASS |
| Stress sintético na Godot, 10.000 casos | 9.997 planos completos; 3 rejeições explícitas; zero falhas das invariantes dos planos aceitos |
| Integração final: 13 regiões, seeds 101/707/816204 | **91/91 PASS** |
| Construções de assentamentos na amostra integrada | **171/171**, com varredura de cápsulas, suporte e entrada física pelas portas |
| Grafo, superfícies, declives e sete pilotos regionais | PASS |
| Rotinas, moradia/trabalho, comunidade, noite e recuperação de bloqueio | **27/27 PASS**; cidade: 42/42 deslocamentos profissionais concluídos |
| Reabertura em outro processo | PASS: 65 moradores, 65 IDs únicos, conversas preservadas, save válido |
| Gameplay renderizado: movimento, corrida, salto, esquiva, combate, técnicas, missão, inventário, menus e save | **14/14 PASS** |
| Assets e animações com renderização | **30/30 PASS** |
| Regressão marcial após limpeza da fixture | **41/41 PASS**, processo sem alertas de recursos |
| Prólogo e encontro/saque/inventário após limpeza das fixtures | PASS |
| Texturas aprovadas, verificação offline | **85/85 PASS** |
| Refinamento visual, verificação offline atualizada para a linha lateral | **62/62 PASS** |

O resumo consolidado tem **42 grupos concluídos PASS**, contando o gate original com as três revalidações, o QA local, duas execuções renderizadas e a captura. Isso não altera o resultado FAIL da primeira execução completa: consulte `final-summary.json` e `revalidations.json` para a origem de cada resultado.

Os três casos sintéticos rejeitados não foram instanciados nem aprovados como mapas: índices 2845, 8035 e 9577, vilas com reserva insuficiente para todos os lotes. A rejeição é explícita, sem descartar construções silenciosamente. Nenhum dos 1.265 assentamentos gerados por atlas no teste principal teve esse problema.

## Preservação

Comparação byte a byte com Refino Visual 02 confirmou preservação de `main.gd`, `rig.gd`, `arsenal.gd`, `animation_library.gd`, `wardrobe.gd`, `combat/player_combat.gd`, `catalog.gd`, `inventory.gd`, `journey_save.gd`, `murim_flow.gd`, `techniques.gd` e `exo_audio.gd`. Shader do terreno e geração visual da grama/trilhas também permanecem idênticos à atualização visual 02. Hashes em `preserved.json`.

Código de produção alterado: `convergence/region.gd`, `resident.gd`, `game.gd`, `state.gd`, `genesis/region_data.gd` e `genesis/settlements/settlement_planner.gd`. Demais alterações são testes, documentação e evidências.

## Evidências e reprodução

Seis PNGs reais em `convergence/evidence_frontage_final/`: aldeia e vila em detalhe e panorama, cidade com moradores na fachada e vista de visibilidade. A câmera normal do jogador foi usada nos detalhes, com zoom de inspeção; panoramas usam câmera afastada. Renderização de software Mesa/llvmpipe no Work. Não há imagens conceituais, montagem ou edição dos cenários.

Os deslocamentos das capturas foram simulados na própria Godot; o desenho de quadros intermediários foi suspenso para acelerar a espera, sendo reativado para cada captura. Não se trata de teste humano nem de benchmark.

Na pasta do projeto, substitua `godot` pelo executável Godot 4.6.2:

```bash
godot --headless --editor --import --quit
godot --headless --path . --script res://convergence/frontage_qa.gd
python3 tools/run_convergence012_checks.py /caminho/para/godot
godot --headless --fixed-fps 60 --path . --script res://martial_qa.gd
godot --headless --fixed-fps 60 --path . --script res://war_qa.gd
godot --headless --fixed-fps 60 --path . --script res://convergence/encounter_qa.gd
godot --headless --fixed-fps 60 --path . --script res://convergence/qa.gd
python3 tools/run_convergence012_checks.py /caminho/para/godot --rendered
```

As execuções renderizadas exigem um display. Logs atuais: `convergence/validation_frontage/`, complementados por `convergence/validation012/final/`. Os demais relatórios e logs herdados são históricos. O helper de captura grava no próprio projeto, não exige caminho do ambiente Work.

## Limites e pendências

- **Desempenho comparativo: NOT_RUN.** Não foi executado benchmark equivalente antes/depois. Os testes concorrentes e os quadros com FPS fixo não servem para essa comparação. Não há estimativa para o computador do proprietário.
- **Teste humano no PC/Android: NOT_RUN.** As verificações foram automatizadas na Godot do Work.
- Oclusão por telhados usa volumes conservadores das malhas, não visibilidade por pixel. Um NPC parcialmente coberto pode ser ocultado por inteiro, conforme o objetivo de não mostrar moradores atrás das casas.
- NPCs continuam com rotinas externas; descanso é proxy de entrada. Não foram acrescentados interiores, economia ou simulação social.
- Os três casos sintéticos recusados continuam registrados como não gerados; uma próxima revisão pode estudar reservas alternativas para essas restrições extremas, sem reduzir a contagem exigida.

## Instalação

Extraia o ZIP completo em uma pasta nova, abra `project.godot` em Godot 4.6.2 Standard, aguarde a importação e execute. A entrada continua `convergence/game.tscn`. Os saves existentes são compatíveis; a atualização reposiciona os moradores cujas coordenadas pertencem ao layout antigo, preservando seus dados.
