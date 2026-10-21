# Situação técnica do pacote — 21/10/2026

## Fonte que foi realmente incorporada

- `EXO-MURIM-PONTAS-SOLTAS-01-CANDIDATO.zip` — versão V4 candidata, original íntegro quanto a CRC. Todos os arquivos foram copiados para `EXO-MURIM/` (exceto a substituição documentada do `AGENTS.md`).
- O pacote contém `project.godot`, `convergence/game.tscn`, `exo_core/`, `WORLDGENESIS_V4/`, `exo_city_forge/`, bibliotecas e demais componentes da árvore do projeto real.
- O projeto pode conter cópias históricas, logs e backups já internos na V4. **Não** assumir que todo diretório é dependência ativa; fazer análise de entradas e dependências antes de excluir ou consolidar.

## BLOQUEADO — bytes não recuperáveis para este empacotamento

1. `EXO-NPC-SYSTEM-04-INDEPENDENTE.zip` (a V4 mantém versão anterior; não considerar NPC04 integrado)
2. `EXO-SETTLEMENT-FORGE-01.zip` (City Forge + Forja Arquitetônica + Interior Forge reestruturados)
3. `EXO-WORLDGENESIS-V5.zip` (não usar a existência de `WORLDGENESIS_V4/` como prova de V5)

Os nomes e tamanhos dos três pacotes foram localizados na Biblioteca, porém o serviço negou o materialização dos bytes. Não criamos substitutos vazios nem remontamos por suposição. É necessário inserir os próprios pacotes reais para avançar integração nova.

## Testes deste empacotamento

- `ZipFile.testzip()` na origem: PASS (somente CRC de todos os membros).
- Verificadas existência de `project.godot`, `convergence/game.tscn`, `tools/run_checks.py`: PASS.
- Executar jogo com Godot 4.6.2: **NOT_RUN**.
- Teste integrado NPC04 + Settlement01 + WG5: **NOT_RUN**, pois pacotes ausentes.
- Direitos comerciais por arquivo e quarentena P0: **NÃO AUDITADO**, requer análise.

## Prioridade sugerida para Codex

P0: proveniência de assets, boot/parser, integridade dos módulos e persistência;
P1: contratos, serviços autênticos, cenas/atores, viagens/interiores, NPCs;
P2: combate/armas/UX/otimização, com QA de regressão e benchmarks reais.
