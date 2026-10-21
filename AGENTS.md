# EXO-MURIM — AGENTS.md PARA CODEX (21/10/2026)

## Identidade e baseline
- Engine: Godot **4.6.2 Standard**, GDScript, renderização **Compatibility**; plataformas alvo Windows/PC (Steam) e Android.
- A raiz deste repositório é o projeto real recuperado da V4. A V4 é fonte de código e arquitetura, **não uma build homologada**.
- Cena principal atual: `res://convergence/game.tscn`. Não aponte para outra sem auditar e executar.
- O arquivo `CODEX_HANDOFF/AGENTS-V4-ORIGINAL.md` mantém as instruções legadas para contexto. Em conflito, siga **este** documento.

## Regras obrigatórias de arquitetura
1. Módulos funcionam como mods: cada módulo é independente, tem manifesto/contratos, dependências e identidades de serviço, e é substituído sempre **integralmente** por sua nova versão; nunca fazer merge incremental sobre o módulo antigo. Remover a árvore ativa antiga em instalação transacional/rollback.
2. Nunca duplicar singleton, autoload, sinal, despachante, serviço, API, classe global ou autoridade de persistência para 'parecer' integrado. Fazer ponte real entre jogo/base e módulos.
3. Módulos novos **não estão incluídos neste pacote**: NPC System 04, Settlement Forge 01 e WorldGenesis V5. Não declarar integração deles antes de receber os ZIPs verificáveis e executar QA.
4. A biblioteca universal e o EXO Core devem manter contratos de autoridade. Não criar substitutos paralelos que contornam integrações.
5. Não preservar compatibilidade com saves legados pré-beta: o usuário autorizou quebrá-la para eliminar resíduos; preservar persistência **da versão atual** após estabilização.
6. Proceduralidade dirigida por conteúdos autorais (bibliotecas, tags, regras, variáveis); evitar repetição e geração vazia.

## Legal e comercial — P0
- O projeto será comercial. Excluir **da build ativa** todos os assets cuja origem própria/original e direitos comerciais não sejam demonstráveis, mesmo se deixar lacunas temporárias. Não reciclar assets externos por adaptação, não confiar apenas no nome de arquivo ou menção vaga de licença.
- Gerar inventário de asset, caminho, origem, licença/documento, hash, decisão (APROVADO / QUARENTENA / REMOVIDO / SUBSTITUIDO). Não classificar como aprovado sem evidência.
- Não usar essa cópia de projeto para lançamento público antes da homologação de direitos.

## QA: verdade por evidência
- Estados: PROPOSTO / IMPLEMENTADO-NAO-TESTADO / TESTE-FALHOU / VALIDADO / HOMOLOGADO / BLOQUEADO. Sem evidência: **NÃO HOMOLOGADO**.
- Para cada correção: (1) artefato verificável; (2) diff; (3) teste real de comportamento; (4) log/captura/reprodução.
- Testes estáticos e sintéticos são preliminares; abrir o projeto não é QA suficiente. Testar criar personagem, gerar mundo, viajar entre regiões, NPCs moverem/interagirem/combaterem, casas/interiores, inventário, economia, save/reload, combate, HUD e estabilidade FPS/Android.
- Verificar parser GDScript em Godot 4.6.2 e regressões. Erros conhecidos históricos incluem `wall_collision` com inferência falha e preload `res://npc_system02/planner.gd`.
- Manter manifesto-mestre para módulos com versão, pasta ZIP e SHA-256, dependências, dono, mudanças, testes, pendências e status.

## Direção visual/experiência
- Voxel puro, skins Minecraft 64x64 classic/slim, roupas e acessórios Murim modulares, cores vivas equilibradas, sem assets de terceiros não autorizados. Fluxo de criação de personagem antes da aventura.
- Não reescrever sistemas validados sem regressão; corrigir e integrar mediante testes reais.

## Ordem de trabalho inicial
1. Validar integridade do repositório extraído; catalogar scripts/cenas/autoloads e dependências; identificar fontes de assets e o que está no caminho crítico da cena principal.
2. Rodar Godot em modo editor/headless para capturar erros de import/parser. Corrigir P0 do boot/persistência e contratos sem misturar versões.
3. Executar roteiros reais de gameplay e atualizar estados por evidência.
4. Após obter os três pacotes faltantes, instalar módulo inteiro com troca atômica e testar leitura em runtime. Não inventar código que deveria estar nos pacotes reais.

## Estado desta cópia V5

Consulte README-CODEX.md e exo_core/modules.json para o estado atual; o texto acima descreve a origem V4. Os três pacotes foram recebidos e integrados nesta cópia. Não reinstale a origem por cima. QA atual: tools/v5/run_qa.py. Evidências históricas não são resultados atuais. Nunca reintroduza binários criativos excluídos. Os recursos novos são gerados por tools/v5/rebuild_generated_art.py e suas especificações. Não crie worktree: cada tarefa cloud já é isolada.
