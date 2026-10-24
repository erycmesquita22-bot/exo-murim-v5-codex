# EXO-Murim — Validação V11 + Combate + Clima 01

## Pacotes efetivamente recebidos

Pasta Drive Murim baiano: Haneul V11 / Sprint07 Rota Haneul–Yunseong (123.978.650 bytes) e Climate & Atmosphere Forge 01 (6.626 bytes). Foram baixados integralmente, extraídos e inspecionados; CRC e SHA-256 registrados em `qa/integration_v11/preservation.json`. O original compactado/extráido foi mantido separado da cópia de trabalho.

O V11 recebido ainda usava Character Core V3, com 15 clipes e Espaço ligado a ataque. Os módulos de combate/habilidades desta conversa não estavam nesse ZIP. As texturas, arquitetura, props, interiores e estrada são os novos arquivos do V11, não uma substituição pelo cenário antigo.

## Resultado

Foi montada e testada uma cópia cumulativa com o Character Core 4.4, Motion Core 03, Combate baiano, Artes Ativas 01, Murim Footwork 01, Sword Frenzy 01 e o clima recebido, ligado por um adaptador específico ao V11. O personagem tem 25 ossos e 44 clipes na cena integrada.

O V11 isolado passou primeiro nas suas próprias suítes de portas/rota, nas famílias WONG e WUDONG. Na cópia combinada passaram:

- 30 entradas/saídas de interiores: as 15 cenas nas duas famílias, verificando identificadores, colisões, piso e preservação da família.
- Portais da vila/estrada e chegada aos arredores de Yunseong, com nove amostras físicas da estrada por família.
- Travessia automatizada de ida e volta por controles de movimento e modo V. Durante cada perna não houve teletransporte: cerca de 650,95 m na ida e 647,21 m na volta, 40,13 s e 39,90 s de simulação; velocidade máxima cerca de 16,51 m/s. Zero frames sem apoio no chão e cápsula sempre acima do piso nos dois trajetos. O início do teste é posicionado no portão para exercitar a transição.
- Combo com input segurado: três cortes em 1,983 s, 22 por corte/66 no alvo e avanço máximo de 1,450 m em caminho livre; sem cruzamentos de superfície corporal nos casos de combo amostrados pelo verificador anterior.
- Rival: nove acertos físicos em oito segundos do ensaio passivo; a vida do jogador foi ampliada apenas nesse ensaio para não interromper a observação. O jogo normal mantém 120/160.
- F contextual, suspensão do rival na estrada/interiores, suspensão do clima dentro das casas, retorno ao exterior e R sem deixar o personagem numa região invisível.
- Seis presets do clima, restauração da iluminação de dia, névoa acompanhando a região atual e ausência de uma varredura completa de materiais a cada frame.
- Instalação numa cópia limpa independente do V11, seguida novamente de testes de combate, portais e clima/contexto.

Os testes são automatizados e reais no Godot disponível, 4.6.3 oficial em Linux. O nome dos arquivos recebidos contém Godot472, mas não se declara aqui uma execução em 4.7.2. Não houve sessão humana prolongada de exploração ou benchmark em GPU de jogo.

## Conflitos encontrados e adaptação

### Herança de cenas

O combate antigo derivava diretamente do adaptador HWA02 e por isso não carregaria os controladores de interiores Sprint06 e rota Sprint07 ao simplesmente copiar a cena do combate.

A ponte agora é: integração → Sword Frenzy → Footwork → Artes Ativas → Combate → Sprint07 → Sprint06 → HWA02 V11 → Character Core atual. No arquivo de combate fornecido por esta conversa, a linha `extends` foi ligada ao controlador Sprint07. Os scripts HWA02/Sprint06/Sprint07 recebidos permanecem byte a byte iguais.

### Tecla F, transições e rival

F já era a tecla de portas/portões e também a de defesa do combate. A prioridade agora é: onde houver uma interação válida, F interage; fora dessas áreas, F defende. A interação encerra a ação atual e limpa buffers/projéteis antes da transição.

O rival deixa de processar IA, colisões e área de dano fora da vila. Não acompanha o jogador para a dimensão dos interiores nem fica como alvo invisível na estrada. F9 permite suspender/reativar o rival para explorar o cenário. R preserva a região remota atual ao reiniciar os estados de teste, evitando retornar para uma vila que esteja oculta.

### Clima original versus adaptação

A API original anexou sem Shader Forge, mas a inspeção e a execução confirmaram:

- `night` mantinha a energia do sol em 0,78, igual ao dia.
- Névoa fixada perto da origem ficava aproximadamente 62 m distante da câmera no ponto de teste.
- Partículas de névoa e folhas eram quads uniformes com bordas retangulares visíveis.
- A cachoeira de demonstração e os postes eram criados em coordenadas fixas sem ligação com os pontos autorados do V11; o conjunto inteiro da cachoeira girava continuamente.
- O código percorria toda a árvore de materiais em `_process`, mesmo sem mudança de clima.

O módulo recebido não foi reescrito. Uma subclasse faz a ligação com o mapa:

- Névoa acompanha câmera/altura local do personagem e é suspensa em interiores.
- Chuva tem gotas mais finas, com transparência suave. Névoa usa máscara radial e folhas têm silhueta pontuda menor. São efeitos transitórios; nenhuma textura do cenário ou do personagem foi substituída.
- Noite reduz sol e ambiente, escurece fundo/névoa e acende luzes em 11 lanternas já existentes no cenário. Dia restaura os valores recebidos. A luminância amostrada do céu noturno ficou em cerca de 13,8% da captura diurna, sob o mesmo enquadramento.
- Materiais com uniforms realmente compatíveis são indexados nas mudanças de região, em vez de percorrer o cenário todo a cada frame.
- A geometria de demonstração da cachoeira e dos postes não é colocada por cima do mapa autorado. O código original continua no pacote, para receber um posicionamento e revisão próprios.

**Pendente:** o pacote `exo_shader_forge_01`, declarado como dependência, não veio na pasta. O runtime aceita o vínculo opcional nulo, usado neste teste; chuva, folhas, névoa e iluminação funcionam pelo Godot. Céu/nuvens, água e vento em materiais de vegetação do Shader Forge não foram validados. O cenário atual usa materiais sem os uniforms de vento compatíveis encontrados pelo adaptador (contagem: zero); não se afirma que as árvores recebidas estejam animadas pelo Shader Forge.

A cachoeira não está integrada ao Rio Hwa; precisa de uma localização/revisão autorada, em vez do bloco demonstrativo. Yunseong continua sendo apenas os arredores/portão preparados pelo Sprint07; nenhuma cidade falsa foi acrescentada.

## Preservação

325 arquivos preexistentes do ZIP V11 permanecem iguais. As únicas substituições entre os arquivos originais são:

1. `modules/character_core_v3/V3_Controller.gd`: do V3 antigo para o Core atual já validado nesta conversa (Espaço pula, V viagem e suporte às bibliotecas atuais).
2. `project.godot`: cena principal aponta para a cena integrada.
3. `module.json`: registra os módulos efetivamente carregados.

Todos os demais arquivos do V11, incluindo GLBs, PNGs, IDs, fontes de terreno/arquitetura e controladores da vila/interiores/rota, permanecem iguais. O GLB-base do personagem continua `fc8af84dc28bd3c5e1a308df7a72efe702558824e924b52ac5d49ea75d11e557`. O módulo de clima recebido também permanece com seus arquivos originais intactos; a adaptação fica em `modules/integration_v11`.

O instalador cumulativo confirmou 182 arquivos originais de assets preservados. Não copia os modelos/texturas da vila antiga para cima do progresso novo. As curvas de espada foram reutilizadas, não reautoradas nesta etapa; Blender não foi modificado.

## Desempenho medido

Renderização normal, sem Movie Maker, 1280×800, câmera comparável com FOV fixado em 64, 90 frames renderizados por amostra após aquecimento. Dispositivo: Mesa llvmpipe (LLVM 19.1.7, 256 bits), renderizador por software.

| Caso | FPS médio observado | P50 | P95 |
| --- | --- | --- | --- |
| V11 original, tempo limpo | 10,69 | 93,16 ms | 108,01 ms |
| Integração, tempo limpo | 10,43 | 95,49 ms | 107,85 ms |
| Integração, tempestade | 9,58 | 102,71 ms | 128,65 ms |
| Integração, noite | 9,92 | 98,63 ms | 112,89 ms |

São amostras desse ambiente, não uma garantia de FPS no computador do jogador. Não há medição de GPU dedicada. Os valores incluem a cena e os efeitos realmente renderizados, com as sombras normais mantidas. Os JSONs contêm tempo de parede e número de frames para verificação.

## Evidências

`qa/integration_v11` reúne logs originais/importação, testes, preservação, trajetos, benchmark, capturas reais de tempo limpo/chuva/tempestade/noite/estrada e o vídeo `V11_CombatClimate_Test.mp4`.

O vídeo tem 20 s e foi gravado no Godot em passo fixo de 60 Hz. Mostra combate na vila nova sob chuva, entrada/saída de interior, trecho de viagem V na estrada e retorno noturno. Há posicionamentos de QA entre locais e reinício do duelo entre cenários; ele não é uma gravação contínua dos 1,3 km. A travessia completa está no teste separado `route_drive.json`.

O Movie Maker registrou 1204 frames em cerca de 232 s neste renderizador de software e o MP4 foi aparado a 20 s. O passo fixo do vídeo não comprova 60 FPS em jogo. Câmera, sombras e efeitos vêm da cena real. Uma revisão final do texto de estado do HUD foi feita após a gravação, sem mudar o comportamento testado.

## Uso e instalação

Projeto completo: abrir `project.godot` e executar. A cena é `modules/integration_v11/Integrated_V11.tscn`. Os READMEs originais recebidos foram preservados como histórico; este relatório descreve a cópia integrada.

Módulo cumulativo sobre o V11 recebido:

```sh
python install.py /caminho/do/seu/V11 --activate
```

Não é necessário aplicar separadamente cada módulo antigo de combate. Sem `--activate`, a cena principal é preservada; abra a cena integrada e use F6. O instalador verifica os contratos V11 e hashes do pacote, guarda backup e rejeita código local desconhecido antes de escrever. Uma cena principal personalizada exige adaptar sua cadeia, e não substituí-la silenciosamente.

Controles principais: WASD mover, Espaço pular, clique para combo, E espada, Q esquiva, F interação/defesa, V viagem, K catálogo, B legado; F7 alterna clima e F9 suspende/reativa rival. Os demais slots e controles anteriores continuam disponíveis.

O projeto completo é uma cópia de teste do material recebido. Para manter atualizações paralelas de texturas, use a atualização cumulativa e confira o relatório/hashes, em vez de substituir uma versão de trabalho desconhecida. Não foram alterados os arquivos originais na pasta Drive.
