# Desempenho 09 → 09.1

Mesmo Godot 4.6.2/Compatibility, renderizador Mesa llvmpipe por CPU, janela
960×600, câmera 15, humano parado em (0,28), inimigos desativados. Uma execução
isolada por versão: 18 quadros de aquecimento e 80 amostras por perfil, sem FPS
fixo nem outro Godot concorrente nessa rodada. Rodada preliminar interrompida
foi descartada. Gravação de vídeo não foi usada como benchmark.

| Perfil | Quadro médio 09 → 09.1 (ms) | Mediana (ms) | P95 (ms) | Memória engine (MiB) | Draw calls |
|---|---:|---:|---:|---:|---:|
| Leve | 49.18 → 35.59 | 36.32 → 33.30 | 106.89 → 52.37 | 54.30 → 54.61 | 108.00 → 112.00 |
| Equilibrado | 102.73 → 99.10 | 93.07 → 93.08 | 173.69 → 125.44 | 54.39 → 54.69 | 108.00 → 112.00 |
| Alto | 95.33 → 93.81 | 93.26 → 91.46 | 114.20 → 116.87 | 54.39 → 54.69 | 108.00 → 112.00 |

Os 4 draw calls adicionais e 48 primitivas correspondem à bainha. Aumento
rastreado de memória: aproximadamente 0,3 MiB; 12 nós e 3 recursos adicionais.
Os arquivos de malha/textura/áudio são os mesmos da 09, conferidos por SHA256.
Não houve aumento de sombras, pós-processamento ou partículas.

Os tempos flutuam com a carga do host compartilhado. Uma rodada não demonstra
ganho estável de FPS; os números menores não são anunciados como otimização.
MEMORY_STATIC não é RSS total do processo. Dados de física, TIME_PROCESS,
memória de vídeo e carregamento constam no JSON; TIME_PROCESS não mede só lógica.
O teste parado não caracteriza o custo de vários personagens lutando.
PC com GPU real, Android e sessões longas permanecem sem medição neste ambiente.

## Contador de física (inclui o passe de animação na 09.1)

| Perfil | TIME_PHYSICS_PROCESS médio 09 → 09.1 (ms) |
|---|---:|
| Leve | 8.83 → 19.59 |
| Equilibrado | 3.21 → 10.88 |
| Alto | 1.55 → 4.24 |

Este contador aumentou na rodada. O esqueleto do jogador passou a ser composto
no passe de física, antes avaliado em _process. O contador inclui esse trabalho
e varia com o número de passos por quadro; precisa de perfil em hardware real
antes de ampliar o elenco. Há custo de CPU adicional na composição, apesar do
pequeno aumento de memória e da ausência de novas texturas/modelos.
