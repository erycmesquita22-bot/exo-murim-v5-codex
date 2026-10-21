# Rollback pareado — Alfa R11

- R10 ZIP original permanece imutável: `b72301454d0ccc7a1d7634371ff4e4a01a26f28f11648f9a4ba0e535c5c357d0`.
- Antes de F5 ou conversão de saves: duplicar *código e pasta user:// inteira* como par de snapshot com versões/checksums, sem apagar os originais.
- Reversão visual R11 em tempo de execução: `Opções > Texturas > Terrain Forge > Desativado`. Para evitar criação de MultiMesh em sessões de teste, configuração avançada `exo_murim/terrain_forge/enabled=false` exige recarregar a região e não altera save.
- Se a mudança visual causar falha antes de abrir o menu, restaurar a cópia integral R10 e o snapshot de save pareado. Não copiar somente `project.godot` ou shaders da R6 sobre a R10.
- Nenhum schema/salvamento foi intencionalmente alterado por R11, mas o teste real de persistência está NOT_RUN.
