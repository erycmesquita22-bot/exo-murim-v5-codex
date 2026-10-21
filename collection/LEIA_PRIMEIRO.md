# EXO-MURIM — COLEÇÃO AMBIENTAL 02: FUNDAÇÃO DO MUNDO REGIONAL

**Estado: pacote autônomo de aprovação visual/técnica. Não modifica o jogo Godot.**

Esta coleção é cumulativa: inclui os **258 recursos da Coleção 01** e acrescenta
**237 recursos novos**. Assim, contém **495 recursos únicos**:

| Família | Coleção 01 | Novos | Total |
|---|---:|---:|---:|
| Texturas de solo | 24 | 12 | 36 |
| Texturas de paredes | 22 | 10 | 32 |
| Texturas de pisos | 14 | 8 | 22 |
| Máscaras MSC4 (RGBA 128×128) | 128 | 128 | 256 |
| Decalques transparentes | 16 | 8 | 24 |
| Modelos individuais GLB | 54 | 71 | 125 |
| **Total** | **258** | **237** | **495** |

Há **quatro GLBs de demonstração adicionais** em `13_CENAS_DEMO/`.
Esses são cenários montados com os modelos existentes, não assets únicos adicionais.
O catálogo PDF possui 14 páginas, feito a partir de renders dos próprios recursos.

## Avalie nesta ordem
1. `00_CATALOGO/PREVIA_GERAL.png` — visão geral.
2. `00_CATALOGO/PRANCHA_TRANSICOES_COMPARACAO.png` — solo antes/depois.
3. `00_CATALOGO/PRANCHA_10_ARQUITETURA_GLB.png` — paredes, telhados, portas e pilares.
4. `00_CATALOGO/PRANCHA_09_TOPOGRAFIA_GLB.png` — encostas e penhascos.
5. `00_CATALOGO/PRANCHA_11_RUINAS_GLB.png` — salas, muros e plataformas.
6. `00_CATALOGO/PRANCHA_CENARIOS_MONTADOS.png` — quatro composições reais.

## Terreno: sem trocas secas entre materiais

Todas as **90 texturas de superfície** são imagens RGB PNG com dimensões 128×128;
seus pixels de borda oposta são iguais, permitindo repetição sem cortes de cor.
As 256 máscaras MSC4 seguem o padrão de canto compartilhado: NW=1, NE=2, SE=4, SW=8.
Para gerar uma região, dois materiais são misturados com uma máscara apropriada;
os códigos de cantos devem coincidir entre tiles vizinhos.

As 128 máscaras adicionadas nesta coleção cobrem oito novos pares de solo.
O shader de referência está em `08_FONTES/terreno_mescla_msc4.gdshader`.
A máscara define a transição visual; o gerador do terreno precisa fornecer o
mapeamento de biomas e o UV de cada tile.

## Modelos e padronização

- GLB / glTF 2.0, eixo Y para cima, origem próxima ao solo (Y=0), cores por vértice.
- Módulos arquitetônicos/ruínas com grid nominal de 4 unidades, saliências de beiral
  podem passar da linha de encaixe. Consulte os limites reais no manifesto JSON.
- **Ainda não há `CollisionShape3D`, navegação, LODs ou prefabs finalizados na Godot.**
  O manifesto fornece pistas de colisão, mas não são colisores reais.
- Partes de portas e arcos devem usar colisões *compostas*, nunca uma caixa única
  cobrindo o vão. Vegetação macia pode ser atravessável; troncos e rochas não.
- Nenhuma variação de terreno/montanha é garantia de acessibilidade sem
  geração de navegação e validação da região.

## Limitações honestas

Os modelos são **protótipos geométricos low-poly**, exportados e verificados,
não modelos finais de estúdio. O pacote não contém um mundo de 88 regiões pronto.
As montagens em GLB/PDF não comprovam iluminação, colisão ou FPS dentro da Godot.
A arquitetura Murim e a anatomia Minecraft dos personagens continuam projetos separados.

Não adicionar este pacote ao jogo inteiro antes de aprovar as cenas demonstrativas e
validar escala/colisão em uma pequena região de teste. Nenhum asset foi integrado ao EXO 09.4.6.

## Direitos e procedência

As geometrias, texturas e pranchas foram geradas originalmente por código para este acervo.
Os arquivos da Coleção 01 foram derivados do pacote anterior do próprio projeto.
Não foram incluídos novos modelos ou texturas de terceiros.
Os arquivos podem ser usados, modificados e distribuídos com o projeto EXO-Murim,
inclusive comercialmente. As licenças e direitos de obras preexistentes dentro do projeto
continuam sendo responsabilidade de quem as distribui.

## Como regenerar as peças novas

O projeto é independente e não requer Godot para extrair e usar os PNG/GLB.
Os scripts ficam em `08_FONTES/` e requerem Python, Pillow, NumPy, trimesh,
OpenCV e ReportLab para regeneração do catálogo completo.

```
python 08_FONTES/gerar_colecao_02.py
python 08_FONTES/gerar_catalogo_02.py
```

Os modelos individuais podem ser abertos diretamente pela Godot 4 como GLB.
Abra `13_CENAS_DEMO/*.glb` para estudar as composições.
