# EXO Haneul — Caminho do cultivo 04

## Implementado

- `C` inicia/interrompe cultivo nos dois círculos HWA-02 existentes, após conversar com Ji Wol e um mestre. Exige solo, concentração, espada guardada e fadiga recuperada.
- A mesma malha e rig V4 executam Gather_Qi, Circulate_Qi e Cultivate. O cultivo para a locomoção e restaura o AnimationTree no fim. O VFX de Qi surge apenas após o despertar.
- Ciclos de nove segundos, fadiga com recuperação, avanço contextual `X`, jornada/catálogo `J`, pequenos bônus de HP/Qi e estado por slot. Novo jogo zera a progressão.
- Reinos canônicos da seção 4.1 da bíblia, sem confundir os 12 estratos do mundo. Jogáveis: Comum, três estágios de Terceira Classe e até Segundo Classe intermediário. O restante aparece como horizonte bloqueado.

## Testes executados

- Godot 4.6.3 Standard, Compatibility, Linux: importação do projeto e inicialização da cena V11 sem erros de script/recurso, logs em `test.log` e `capture.log`.
- `test_cultivation.gd`: 18 verificações, todas passaram. Incluem começo Comum, missão Ji Wol/mestre, detecção de área, início e fim de ciclo, retorno da locomoção, avanços e bloqueio do próximo reino.
- Renderização real em Xorg/software: `player_before.png`, `player_cultivating.png`, `player_after.png`, mesma câmera e iluminação. Diferença média antes/depois 0,031 níveis RGB; na região central 0,213. A diferença residual vem de fundo animado/posição no quadro, sem alteração dos arquivos V4.
- FPS amostral da captura: 7 FPS no renderizador software desta máquina; não representa desempenho em PC com GPU.
- SHA-256 do GLB V4 preservado: `fc8af84dc28bd3c5e1a308df7a72efe702558824e924b52ac5d49ea75d11e557`.

## Não testado / limites

- Godot 4.7.2 não está instalado neste ambiente. A prova foi em Godot 4.6.3. Nenhum teste Android foi realizado; Android foi retirado do escopo pelo usuário.
- Não há missões e provas das regiões futuras para Primeira Classe e acima. Esses reinos permanecem bloqueados. A missão atual é uma base jogável do primeiro arco, não a campanha completa.
- Capturas verificam aparência e pose; a prova de input e estado vem do script de teste, não de uma sessão humana extensa.
