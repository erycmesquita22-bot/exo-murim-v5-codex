# Comparação Terrain Forge ligado/desligado — R11

| Aspecto | Desligado | Ligado | Evidência |
|---|---|---|---|
| Cálculo original de ground/road | Mantido | Mistura condicional nova | Igualdade textual verificada offline, render real NOT_RUN |
| Geometria e colisões | R10 | R10 | diff estrutural do WorldGenesis/region_data preservado |
| Rios, ruas, reservas R7 | Inalterados | Inalterados | scripts autoridade R10 SHA idêntico |
| Vegetação extra MultiMesh | Ocultada via controle | Até 170 instâncias / região, visibilidade variável | código static PASS; aparição na cena NOT_RUN |
| Filtragem pixel / mips / linear | Shader original com branch falso | Mesmo perfil mais uniforms e mistura | uniform transfer estático PASS, compilação NOT_RUN |
| FPS / drawcalls / RAM | Não medido | Não medido | NÃO EXECUTADO (sem Godot/GPU alvo) |

Observação: os JPG incluídos no pacote são amostras offline, não resultados de F5 da R11.
