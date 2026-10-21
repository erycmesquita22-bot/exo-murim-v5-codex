# EXO-MURIM — RELATÓRIO DE ARTE DAS CRIATURAS 02

**Status:** CANDIDATO OFFLINE (não aprovado como arte final nem integrado). **Godot 4.6.2 Compatibility:** executável não encontrado no ambiente; testes nativos NOT_RUN.

## Contagem por ID (sem inflar espécies)

- **20 GLBs / variantes reais** auditadas e preservadas (12 Forge 01 + 8 Art 02).
- **17 identidades canônicas únicas**; **3 duplicatas** (lobo, javali, tigre).
- **13/16 espécies com IDs do Bestiário 02 possuem GLB**; 3 estão sem modelo específico (`wild_ox`, `wild_buffalo`, `qi_serpent`).
- **21 dos 33 conceitos originais do Creature Forge 01 continuam pendentes** por correspondência exata; as novas identidades do Art 02 não reduzem esta contagem sem aprovação.
- 4 identidades visuais sem perfil canônico próprio no Bestiário 02: `desert_monitor`, `desert_scorpion`, `demon_boar`, `kitsune`.

## Auditoria e harmonização aplicada

1. Gerado catálogo por ID canônico, fonte, GLB, SHA-256 antes/depois, atlas, rig, juntas, 6 clipes, triângulos, bounds, cenas, sockets e perfil de colisão.
2. Lobo, javali e tigre: priorizada a versão Art 02 como **recomendação provisória por detalhe de silhueta**, com variante Forge preservada. Modelo recomendado não equivale a aprovação artística.
3. Criadas cenas Godot com escala proposta por espécie (protagonista = aproximadamente 2 unidades) e rotação +90° em Y para padronizar -Z à frente; valores ainda não medidos em jogo.
4. Adicionados 3 sockets por GLB (origem de ataque, centro de VFX e suporte) com parentesco ósseo e metadados. Sem instanciar colisores autoritativos.
5. Mantida a geometria de todos os 20 modelos. **Não houve reconstrução anatômica profunda, escultura manual ou produção de novas texturas**: seria incorreto declarar que a arte passou a cumprir integralmente a prancha aprovada.
6. Modificados **335 canais/casos de animação** nas cópias harmonizadas: marcha com fases e balanço adaptados à família, impulso visual diferenciado no ataque e membros dianteiros com gesto adicional em felinos/feras grandes. Animações de serpente foram preservadas como cadeia própria; movimentos da aranha/escorpião mantêm rig especializado. O sistema usa curvas e **não faz IK/contact lock**; patinagem precisa de verificação nativa.
7. Não foi introduzida variação procedural de anatomia. Variantes de aparência são modelos fixos com IDs estáveis.

## QA REAL realizado (offline)

| Verificação | Resultado | Limite |
|---|---|---|
| 20 arquivos GLB v2, chunks JSON/BIN e SHA-256 | PASS | Não substitui importação Godot |
| Accessors finitos, skins e matrizes de bind, animações com timeline monotônica | PASS 20/20 | QA numérico sem colisão física |
| 6 clips nomeados, sockets vinculados a nós reais | PASS 20/20 | Retarget Godot pendente |
| Assinatura original preservada no catálogo; geometria original não remodelada | PASS | Proveniência comercial herdada exige confirmação |
| Render 3D dos 17 recomendados e 8 espécies em 3 ângulos | EXPORTADO | Render CPU do GLB; não é captura do jogo |
| GIFs pós-modificação de lobo walk, javali walk, tigre attack e serpente walk | EXPORTADOS | Avaliação raster/skinning offline; não comprova contato com chão |
| Godot Parser/Import Compatibility, shaders, FPS/RAM 4/8/16 e combate | **NOT_RUN** | Godot indisponível |
| Escala com protagonista, articulação visual, luz ambiente e sombras | **NOT_RUN** | Necessita base real e engine |

**Métricas geométricas medidas:** triângulos de 456 a 5,920 por GLB; mediana 960. Tamanho dos 20 GLBs harmonizados somados: 6.29 MiB. Atlas de textura embutido e 1 material em cada GLB; compartilhamento/material instancing entre espécies não foi implementado nesta rodada.

## Problemas/limitações ainda abertos

- Modelos de Forge 01 mantêm baixa resolução geométrica e visual distante da direção artística final; a escolha de Art 02 para os três duplicados não resolve o conjunto.
- Silhuetas e materiais precisam revisão *na câmera e iluminação reais*. O design do Guardião de Pedra precisa checagem de correspondência estética com seu papel.
- O retiming proposto não garante ausência de patinagem: sem IK, sincronização de velocidade com CharacterBody3D, curva de solo ou marcadores verificáveis na física.
- Colisão simplificada é apenas descritor; não foi construída hitbox ativa nem medida em jogo.
- Qualidade/completude comercial: 21 criaturas do plano inicial faltam, mais 3 IDs de Bestiário 02. Propostas de deserto não têm gameplay cadastrado; **não acrescentar spawn** nesta camada.
- O laboratório GDScript exige execução real; nenhuma captura da Godot nem medição de FPS foi alegada.

## Decisão de entrega

**Pronto como CANDIDATO para QA/integrador da próxima Convergência**, não pronto como arte final ou integração autorizada. Recomenda-se validar lobo/javali/tigre/serpente e as condições reais de escala antes de expandir ou incorporar centenas de instâncias.
