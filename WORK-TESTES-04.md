# Ordem para o Work — World Genesis 04 / assentamentos

**Não pedir novas features, não trocar engine e não redesenhar o jogo.** Executar, auditar e corrigir apenas o novo núcleo de assentamentos, em cópia do projeto. O pacote não está certificado.

1. Abrir `project.godot` com Godot 4.6.2 Standard Compatibility. Rodar importação headless e guardar erro de compilação GDScript completo (incluindo primeiro stacktrace, sem mascarar como teste de sucesso).
2. Executar `tests/settlement_core.gd` com seeds padrão. Se falhar, reduzir para um único ID/seed, corrigir o código e repetir até passar.
3. Executar `tests/settlement_geometry.gd` e verificar quantidade de instâncias, colisões básicas e estrutura de metadados para cada lote.
4. Executar `tests/settlement_core.gd -- 1000`. Registrar total de assentamentos, falhas por motivo, tamanho, bioma, seed, tempo e p95. **Não usar porcentagens sem denominador**.
5. Conferir conectividade física da porta à rua em 4 aldeias, 4 vilas, 4 cidades; terraços, rios, portais e limites de terreno.
6. Rodar regressão das sete regiões do piloto e comparar com `QA-GENESIS-03.md`. Separar mudanças intencionais nas regiões de assentamento dos defeitos reais. Não aceitar transição bloqueada ou redução silenciosa de lotes.
7. Registrar FPS/tempo de carga/memória com e sem preparação de região, mesmo hardware e roteiro do piloto, principalmente na cidade (35–48 lotes).
8. Só após correções, consolidar relatório com `PASS`, `FAIL`, `NOT_RUN`, evidências/prints reais da Godot, arquivos modificados e limites conhecidos.

O arquivo `SETTLEMENT-GENESIS-04.md` explica o contrato e os limites. Não declarar construções Murim I/L/U definitivas nem funcionalidades de NPC, interiores e streaming otimizados que não foram entregues.
