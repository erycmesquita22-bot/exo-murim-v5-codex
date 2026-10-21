# Abrir, testar e recuperar

Extrair o ZIP integral numa pasta nova. Abrir project.godot com Godot 4.6.2 Standard / Compatibility. Cena canônica: convergence/game.tscn.

Campanhas novas pelo criador usam WG4 com a flag exo_murim/worldgen_v4/new_campaigns_enabled=true. O save fixa convergence.worldgen_v4 schema 1/generator 4, regional_version 7 e atlas completo. Dados são normalizados pelo formato JSON do salvamento existente antes da primeira geometria, evitando diferenças no reload de seeds nativas.

Saves antigos sem marcador continuam C3. Flag false escolhe C3 apenas para campanhas futuras; não converte saves V4. Remover marcadores manualmente produz contrato inválido, não um downgrade seguro.

Rollback: extrair o checkpoint anterior em pasta isolada e recuperar também a cópia do save compatível. O checkpoint pré-WG não deve receber saves regionais 7. Copiar user:// antes de abrir versões diferentes. Não há sistema de persistência paralelo.

Testes, usando diretório de usuário descartável:

```bash
export XDG_DATA_HOME=/tmp/exo-wg4-qa
python3 tools/run_worldgen_v4_checks.py /caminho/Godot
python3 tools/run_work_checkpoint_checks.py /caminho/Godot
python3 tools/run_checks.py /caminho/Godot
```

Validação gráfica: executar playable_validation.gd e genesis/v4/capture_compare.gd em display real. Benchmarks em processos gráficos sequenciais, sem --fixed-fps e sem outros testes simultâneos. Fixtures usam entrada automatizada e fundos apenas de QA; não são caminhada humana nem economia inicial do jogo.
