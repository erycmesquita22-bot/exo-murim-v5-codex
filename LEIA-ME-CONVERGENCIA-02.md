# EXO-Murim — Convergência 02 / EXO Core 01

**Candidato funcional validado; ainda não aprovado como OFICIAL.** Leia RELATORIO-CONVERGENCIA-02.md para resultados e bloqueio de muralhas junto a rios.

Extraia tudo e importe `project.godot` na **Godot 4.6.2 Standard, Compatibility**. Aguarde a importação e execute F5. Este pacote contém o projeto completo; nenhum ZIP adicional é necessário para jogar. A biblioteca Forja 03, Skin 3D, Jornada, Narrativa, Mundo Vivo e Core estão incluídos.

O diretório de saves antigo e a raiz JSON v4 são preservados. Na primeira gravação de um save sem Core, o arquivo anterior é copiado para `.pre-exocore01.json`; o fluxo de `.bak` e `.tmp` continua ativo. PNGs de skins ficam em `user://exo_skins`.

Controles: WASD, Shift correr, mouse orientar, clique atacar, F esquivar, espaço saltar, R mãos livres/arma, E interagir e P menu. Para contratos regionais, converse com um morador e abra P > Missões próximo ao contratante. A aldeia 86 tem serviços rurais; Estrada dos Salteadores foi validada com um NPC da vila 15.

`source_reference/` contém relatórios e fontes auxiliares de auditoria. Não sobreponha esses scripts ao jogo. Relatórios 09.x/C01 herdados são históricos. Os resultados da presente execução estão em `RESULTADOS-QA-CONVERGENCIA-02.json` e no relatório C02.

Para módulos novos, siga EXO-CORE-CONTRATO-DE-MODULOS.md e o projeto-template em exo_core/module_template. O template separado é um harness de contratos, não outro jogo.
