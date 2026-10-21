# EXO World Genesis — Forjamento LAB 2 (18/10/2026)

**Objetivo:** investigar geração determinística de 88 regiões externas conectadas, com planejamento de clima, biomas, hidrologia macro, assentamentos, ruínas, masmorras e passagens; verificar também uma primeira síntese de relevo/estradas/fundações por região.

**Estado:** laboratório de pesquisa independente. **NÃO substitui a Godot e NÃO é um jogo.** É um gerador lógico em Python, com previews em VTK e uma exportação de malha de terreno para GLB.

## Rodar

Requer Python 3.11+ e bibliotecas em `requirements.txt`.

```bash
pip install -r requirements.txt
python world_genesis_v2.py --seed 816204 --output atlas_seed.json
python visualize_v2.py 816204
python region_synth_v2.py
python render_region_v2.py 101
python render_region_v2.py 707 0
python stress_test.py --count 1000
python stress_regions.py
python test_full88.py
```

## Arquivos importantes

- `world_genesis_v2.py`: planeja o **atlas das 88 regiões**; corrige situações que violam cotas, saída máxima, cobertura de serviços e separação/altura dos portais.
- `region_synth_v2.py`: gera uma região de 512 unidades em malha de amostragem configurável, traça estradas, corrige inclinação, cria bases de edifícios e regras de bloqueio das bordas.
- `render_region_v2.py`: prévia geométrica **fora da Godot** com 10 módulos GLB reais de vegetação, telhados e ruínas, mais quatro texturas originais do pacote EXO. `.glb` exportado contém **o terreno**, não a arquitetura da prévia.
- `visualize_v2.py`: mapa macro do mundo e biomas.
- `atlas_seed_816204.json`, `test_full88_results.json`, `stress_results.json`, `region_stress_results.json`: dados e evidências.
- `COMPARATIVO_ATLAS.png`, `COMPARATIVO_REGIAO.png`: comparações. **Imagens regionais usam escalas e renderizadores diferentes; não representam uma comparação visual controlada dos mesmos assets.**

## O que ainda falta para o EXO Godot

- Traduzir ou encapsular os algoritmos e testar compatibilidade e versão da Godot.
- Construir chunks de detalhe/collision adequados para o personagem. A malha de 112² amostras em 512m é apenas a **malha de planejamento de baixa resolução** (~4,6m/amostra), não colisão final jogável.
- Aplicar o Auto-Tiling 3D e texturas conectadas aos materiais em GPU.
- Construir rios navegáveis/reais; os rios do atlas são **proxies hidrográficos**.
- Integrar catálogo completo de GLBs e peças modulares, navmesh, colisões, spawn seguro, física, streaming e persistência de alterações.
- Testar níveis baixo/médio/alto, FPS, multiplayers, limites e iluminação na engine.
- Fazer a passagem entre regiões com regras de jogabilidade e os interiores.

**Sem falsas garantias:** testes lógicos passando não comprovam arte final, jogabilidade, performance ou robustez universal. Nem 3 mil mundos sem falha autorizam o valor de 99,999999% de sucesso.
