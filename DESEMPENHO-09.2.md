# Desempenho 09.2 — medições executadas

Godot 4.6.2 Linux, Compatibility, Mesa llvmpipe LLVM 20.1.2 (renderização por
CPU), janela 960×600. Processos sequenciais, sem outros testes simultâneos.
Não é medição em PC com GPU dedicada ou Android. Resultados brutos em
logs-validacao/092. Não usar as gravações de FPS fixo como benchmark.

## Gerador de equipamentos

Após 100 itens de aquecimento, cinco lotes de 10.000 itens por geração pura:
271.675, 273.506, 262.402, 260.268, 273.406 ms.
Média **268.251 ms por 10.000**; mediana **271.675 ms**;
aproximadamente **26.83 µs por item** neste ambiente.

O trecho cronometrado não inclui validação, JSON de saves ou criação da cena.
Objetos são liberados a cada iteração. Em 50.000 gerações: delta de **0 nós**,
**0 recursos** e **336 bytes** de memória estática retida reportada pelo monitor.
Esse último número não mede pico de alocação ou consumo total do processo.
O teste separado de 2.000 itens também valida limites e ida/volta JSON;
seu tempo inclui validação e não é comparável à geração pura.

## Referência visual equivalente — perfil Médio

Mesmo roteiro externo em ambas as versões: personagem/espada iniciais, IA
suspensa, posição (0, 0.03, 28), câmera 15, sem saque gerado. Aquecimento de
120 quadros; depois 120 amostras por versão, VSync desativado. Roteiro em
tools/steady_benchmark.gd, idêntico nos dois processos.

| Monitor | 09.1 | 09.2 |
|---|---:|---:|
| Quadro médio (ms) | 57.471 | 54.645 |
| Mediana (ms) | 57.104 | 54.864 |
| P95 (ms) | 65.667 | 59.266 |
| Física, monitor médio (ms) | 1.564 | 1.357 |
| Processamento, monitor médio (ms) | 62.652 | 56.527 |
| Memória estática (MiB) | 54.692 | 55.315 |
| Memória de vídeo reportada (MiB) | 39.710 | 39.710 |
| Draw calls | 112 | 112 |
| Nós | 1558 | 1558 |
| Recursos | 208 | 216 |

Acréscimo estático observado: **0.623 MiB** (1.14%).
Os dois Ogg e os módulos/registros de dados são novos recursos; não há novos
nós permanentes na cena de referência. A diferença de tempo entre amostras
curtas não demonstra ganho de velocidade; o host e o renderizador por CPU têm
variação. Draw calls e nós ficaram iguais. O gerador não roda por quadro.

## Coleta inicial com três perfis

Também foi executado benchmark.gd herdado: 18 quadros de aquecimento e 80
amostras por perfil. Logs benchmark091/092 preservados. Baixo: 21,147 →
24,246 ms; Médio: 54,620 → 56,649 ms; Alto: 57,794 → 57,129 ms. Carregamento
até o primeiro quadro/personagem: 448,831 → 464,460 ms.

O monitor de física do primeiro perfil da 09.2 marcou 114,772 ms, discrepante
com os próprios intervalos entre quadros; não foi descartado do log. A coleta
acima, com aquecimento maior e perfil único, repetiu o monitor e obteve
1,564 → 1,357 ms. A discrepância não se manteve. Sem perfil de CPU por função
não é correto atribuir causalidade à geração ou declarar uma otimização.
Os números de carregamento incluem construção da cena, não medem importação
limpa de recursos no editor. Sombras, pós-processamento e malhas não mudaram.

## Áudio e evidências

Vídeo 092-ciclo-procedural.mp4: duas execuções reais concatenadas, com áudio
AAC capturado na Godot; 12,50 s. Volume máximo medido -10,4 dBFS e médio
-33,8 dBFS no arquivo final: sem clipping nessa sequência. Não é aprovação
estética de audição nem prova de todos os eventos sonoros possíveis.

Sem exportação/medição em hardware Android. Streaming, multidões e mundos
muito maiores precisam de perfis próprios; não são cargas desta atualização.

O ZIP inclui capturas, vídeo e documentação; seu tamanho não representa a
memória ou os recursos carregados pelo jogo. Os dois novos Ogg somam 14.059
bytes. Pastas de evidências/logs/fixtures têm .gdignore para não importar as
capturas como texturas do jogo. A base de modelos e áudios não foi duplicada.
