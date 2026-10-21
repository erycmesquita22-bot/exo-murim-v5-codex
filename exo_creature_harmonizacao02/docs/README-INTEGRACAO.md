# Instalação e QA do Creature Harmonização 02

**Não instalar sobre EXO Core diretamente.** O ZIP contém apenas `exo_creature_harmonizacao02/`. Colar esta pasta de maneira isolada em um clone de testes Godot 4.6.2 Standard Compatibility (Convergência 03 é responsabilidade de outra rodada).

- Cada identidade canônica tem uma cena recomendada e, quando houver duplicata, a alternativa preservada. Todas as escalas propostas são wrappers, sem modificar a malha do GLB.
- `integration/visual_catalog.gd` expõe dados de caminhos apenas. `lab/harmonizacao_lab.tscn` foi preparado para testes visuais, com teclas `1/2/3` (4, 8 e 16 atores), `SPACE` (walk) e `T` (attack). Não foi executado no Godot neste ambiente.
- QA offline: `python exo_creature_harmonizacao02/tests/qa_harmonizacao.py` (exige `numpy`).
- Todas as `evidencias` são renderizações derivadas diretamente das malhas/glTFs em software CPU, não capturas da engine. GIFs avaliam matriz de pele e rotação de juntas dos próprios GLBs.
- Colisores propostos e sockets são **metadados descritivos** sem gerar dano ou duplicar colisão física. Verificar no runtime antes de integrar.
