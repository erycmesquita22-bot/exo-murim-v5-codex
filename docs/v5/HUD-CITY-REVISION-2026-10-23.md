# HUD de combate e acabamento urbano — 23/10/2026

Base: commit abcf193, incluindo a revisão de menus, encaixes e áudio anterior.

## Alterações verificáveis

- HUD oficial redesenhado no mesmo proprietário (`exo_ui/hud_murim.gd`). Vida, Qi, fôlego, nome, nível e EXP; técnicas equipadas, custo e recarga; aviso de recursos insuficientes; esquiva e sua recarga; arma atual, moedas e quantidade de consumíveis; mapa regional/masmorra, orientação, ameaças próximas, contrato rastreado, alvo e canalização. Nenhum novo sistema de inventário, habilidades, XP ou persistência.
- Layout distribuído com escala limitada pela resolução; somente 3–6 espaços conforme o equipamento real. O painel anterior de localização e o prompt genérico ficam ocultos quando o HUD oficial assume essas responsabilidades. O modo compacto mantém o mapa e oculta o objetivo lateral. Opções de paleta/posição que pertencem aos estilos alternativos não aparecem para o layout oficial.
- Reboco, madeira, pedra e telhas preservam os materiais/peças autorais Forja. O atlas normaliza a luminosidade da textura de detalhe antes de aplicar a paleta, evitando multiplicar duas bases escuras. Telhado azul ardósia, paredes claras e estrutura de madeira permanecem distintos.
- A versão distante da casa escolhe as cores pelo papel do material, em vez de coordenadas fixas de atlas. O cubo distante agora respeita os índices de triângulos do BoxMesh: o caminho anterior emitia 24 vértices como triângulos independentes e deixava faces ausentes. A silhueta distante tem telhado inclinado e vigas; a casa próxima continua sendo a montagem Forja completa.
- Preenchimento urbano prioriza ruas internas e eleva os tetos de lotes para 12/32/64 (aldeia/vila/cidade). São tetos, não garantias: cada casa adicional ainda deve passar pela validação de rios, monumentos, ruas, limites e outras casas. Não há encolhimento das construções, segundo gerador de cidade, nem aumento dos limites globais de figurantes.
- A regressão detectou duas pendências da revisão anterior: cotovelos de arco/besta dobravam para o lado errado na solução IK; figurantes mudavam a textura da pele ao receber um identificador temporário. Corrigidos o polo do cotovelo e a identidade usada pela variação visual, mantendo identidades de cena distintas.

## Evidência e limites

Engine exigida: Godot 4.6.2 oficial, Compatibility. `qa/v5/hud_city.gd` verifica materiais próximos/distantes, triângulos, 24 combinações de resolução/escala/loadout, custo e recarga de uma técnica real e recusa por falta de recurso. `tools/v5/run_qa.py --suite hud_city` executa essa suíte. Capturas opcionais: engine com OpenGL, `--script res://qa/v5/hud_city.gd -- capture --output=<diretório>`.

As verificações de fachadas em `world_regions` e `drive_updates` foram atualizadas para a árvore A+C já existente nesta build (ForjaCompleteVisual/ForjaDistantLOD, com um único corpo de colisão). A verificação de passos aguarda o fade de saída antes de exigir silêncio.

Os resultados finais desta revisão ficam em `docs/v5/hud-city-evidence/summary.json` e nos logs correspondentes. Resultados anteriores com verificações desatualizadas não contam como PASS. Capturas de galeria mostram as duas distâncias lado a lado; não são uma promessa de desempenho em cidade completa.

A densidade continua limitada pelo plano seguro e não reproduz todas as construções da referência panorâmica. Desempenho em hardware Windows/Android e sessões prolongadas não foi homologado. Nenhum asset criativo externo novo foi acrescentado; permanece a situação de proveniência já registrada para as peças autorais autorizadas.

## Resultado final

PASS: world_regions (3 sementes, 18 regiões), reported_bugs, drive_updates, hud_city, encaixes de arma e importação/editor. Capturas nativas OpenGL disponíveis na pasta de evidências. Áudio na captura usa o driver Dummy; não foi feita avaliação auditiva nessa execução.

Ocupação medida: aldeias 12/12/12, vilas 29/32/31, cidades 47/64/64 (sementes 101/707/816204). Todas as portas amostradas foram atravessadas na ida e na volta; fachadas mantêm um único dono de colisão. As variações visuais agora usam a identidade de origem e sais por atributo, sem depender da serialização de metadados adicionados depois.
