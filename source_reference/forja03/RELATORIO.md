# RELATÓRIO DE ENGENHARIA — EXO Forja 03

**Estado: candidato à validação real do motor Godot.** A execução disponível aqui cobre geração de GLBs, inspeção geométrica offline, integridade, testes de limites e regressão; a máquina não tem Godot instalado e não resolve o domínio da distribuição para baixá-lo. Não foram produzidos prints reais da Godot nesta rodada.

## Alterações auditadas

- Catálogo V02: 121 GLBs. Novo catálogo V03: **163**; os **42 GLBs adicionais** contêm **5.148 triângulos** e ocupam cerca de 203 KB juntos. Criados e exportados localmente a partir de blocos voxel com materiais GLB; sem modelos baixados da internet.
- Preservação: **467 arquivos herdados byte a byte idênticos** do ZIP da V02, verificados por SHA-256 com `docs/BASELINE-02-SHA256.json`. Os quatro arquivos alterados intencionalmente são catálogo, `project.godot`, README e relatório.
- Novos sistemas: composição de muralhas, seis papéis cívicos, um gerador de faixas ambientais, clã murado, adaptador de lotes atômico e laboratório 1–9.
- As casas V02 mantêm `schema_version=2`; planos V03 de novos tipos usam `schema_version=3`. O planejamento V02 não foi reescrito.

## QA offline executado, após correções

| Grupo | Evidência | Estado |
|---|---|---|
| Imports de GLBs | 163 arquivos reabertos em parser glTF/GLB | OK |
| Geometria nova | 42 modelos, 5.148 triângulos, bounds comparados ao catálogo | OK |
| Integridade | hashes de 467 arquivos da versão 02 | OK |
| Arranjos cívicos | seis papéis, dimensões mínimas, corredor externo | OK |
| Perímetros murados | 1.521 combinações de largura/profundidade, células do portão, limites e torres | OK |
| Transformações | 40.000 reservas com rotações 0/90/180/270° | OK |
| Faixas verdes | 12.000 combinações de largura/profundidade e reserva de copa | OK |
| Análise estática | paths `preload`, módulos, identificação de scripts, seeds 64 bits nos novos planners | OK |
| **Total no `qa/results_v3_offline.json`** | **62.215 checks, 0 falhas** | **OK (offline)** |

Os volumes novos usam cores de materiais PBR simples, não as texturas complexas do terreno aprovado; o visual final das peças e da cena combinada exige inspeção do Work. `previews/forja03-20-glbs-projecao-offline.png` é uma **visualização de faces dos GLBs, não screenshot in-game**.

### Problemas detectados e resolvidos durante a construção

1. O primeiro ID `wall_stone_2m` já existia no catálogo da V02. O novo modelo foi corretamente renomeado para `city_wall_stone_2m`, evitando colisão de identidade.
2. A ponte/passarela em madeira tinha apenas um grupo de material; recebeu suportes estruturais distintos.
3. Dois módulos de jardim haviam sido gerados com geometria equivalente; foram redesenhados para produzir plantas diferentes.
4. O primeiro portão da horta possuía travessa a altura inadequada para o personagem; a travessa foi elevada para 2,7m e sua abertura foi conferida sobre os vértices GLB.
5. A primeira conta da suíte offline superestimava as peças dos muros laterais; o cálculo de conferência foi corrigido e a suíte integral foi repetida. A diferença era no **teste**, não no gerador da Godot.
6. Os novos planners mantêm o seed 64-bit em vez de truncá-lo para 31 bits, para evitar colisões fáceis de identidade entre seeds altas.

## Pendências reais (não aprovadas)

- **Godot:** importação, parser GDScript, recursos, tempos de construção e FPS. Scripts de teste preparados: `qa/run_headless.gd`, `qa/run_headless_v3.gd` e `qa/benchmark_v3.gd`. Nenhum foi executado aqui.
- **Física:** portas do hall, passagem útil dos portões, colisores laterais, degraus, encaixes com terreno de verdade, testes com personagem real e física de mobs/NPCs.
- **NavMesh:** a reserva geométrica de corredor não demonstra que agentes de IA navegarão até o prédio.
- **Muralhas grandes:** perímetro atual é retangular e exige terreno nivelado; cidades irregulares precisam de sistema de trechos adaptado às cotas amostradas pelo Genesis. Torres ainda não possuem interiores visitáveis.
- **Desempenho visual:** geometria estática, sem geração de lightmaps/occlusion/HLOD, sem mesh batching global, sem medição real de drawcalls/FPS neste ambiente. A biblioteca original de casas conserva colisores trimesh da V02.
- **Integração:** nenhum arquivo do Genesis ou do EXO principal foi alterado. Requer aprovação de QA antes de merge.

**Decisão:** disponibilizar a Forja 03 como laboratório independente pronto para o Work testar, registrar resultados e corrigir falhas reais. Não indicar 100% de sucesso nem integração em produção.
