# Ordem de merge planejada — NÃO EXECUTADA

Base: `EXO-Murim-Cidade-Viva-01-R2-PROJETO.zip`, SHA `1ef340db3f3ff0f133ec07808ee38d553ca4de7c48810f53b2cedc41cfde0b84`.

Os checkpoints abaixo devem conter commit do código, hashes da árvore/ZIP, inventário de domínios/schemas, saves de teste pareados, log de importação, testes e pendências. Sem aprovação do gate, não prosseguir para fases dependentes. Ramo de auditoria não contém jogo integrado.

| Fase | Ação futura / owner | Dependências | Gate de saída | Checkpoint / rollback |
|---|---|---|---|---|
| C00 | Congelar ZIP, saves e evidências; abrir branch isolado / Integrador | Hashes desta auditoria | ZIP íntegro; saves copiados byte a byte; namespace de QA isolado; Godot 4.6.2 identificado | C00 origem imutável; rollback copia código+saves, nunca só schema |
| C01 | Reproduzir base Cidade Viva R2 / QA | C00 | Import sem erros, 23 suítes históricas reexecutadas ou exceções justificadas; capturar cidade 78 e rios 14/26 | C01 sem módulos novos; se falhar investigar ambiente/base antes de patches |
| C02 | Corrigir lacuna do backup e adotar Core 01-P integral / Core Persistence | C01; 17 preimages conferidos | Parser; v1/v2; backup válido e inválido não vazio; replay; falha I/O; reopen; 10k/100k instrumentados | C02; voltar código C01 + snapshot pré-01P da mesma campanha, conservar save v2 separado |
| C03 | Conciliar HUD e entrada procedural / HUD+Flow+World | C02 | HUD e settings Visual R2 sem regressão; criação leva direto à região seed; sem passagem pela vila legada; I/TAB/F/E/R/P corretos | C03; reverter somente commit+save de teste correspondente; não apagar legado antes do grafo de dependências |
| C04 | Instalar NPC System R1 por blocos e depois R2 / NPC+Living World | C03; hashes R1/R2 | IDs e snapshots preservados, lógica nativa, dia real, patrulha/conversa/perigo, colisão/visibilidade, reopen | C04; voltar Director/resident/bridge e metadados de teste pareados, preservar saves posteriores |
| C05 | Reserva monumental e dungeons exteriores no WorldGenesis ANTES dos lotes pequenos / World+Cidade Viva+Forja | C04; contrato de reservas decidido | Footprints/rotações reais 14/26/78, sem rio/portão/lot/rota sobreposto; 62 estações semânticas vinculadas, idempotência | C05; restaurar código e plano regional/snapshot pré-reserva; não regerar campanha usada silenciosamente |
| C06 | Registrar Dungeon R2 e transições seguras; preparar salões / Host+Dungeon | C02,C05 | Checkpoint bound; snapshot guard; recovery boot; entrada/saída/morte/save falho; versões 2/3 pinadas e 4 nova; player único | C06; restaurar código/domínio dungeon/posição exterior juntos; visita interrompida preservada até recovery |
| C07 | Resolver contrato atômico e hook R3 / Inventário+Core+Dungeon+Jornada | C02,C06; contrato staged aprovado pelos owners | Um commit itens+claim+quest+dungeon; 23/24 slots; replay/UID/corrupção/falha; sem efeitos fora do rollback | C07; desativar hook; restaurar C06+save pré-ativação; guardar evidências e drops pendentes; nunca apagar recibos entregues |
| C08 | Ligar Bestiário aos atores/ecologia/combate e visuals harmonizados / Ecologia+Combate+Arte | C04,C05,C07 | Um spawn authority; dano real e janelas; XP/loot por geração; espécies ausentes explicitamente não instanciadas; escala/colisão | C08; reverter adaptadores por feature e save pareado, sem duplicar atores antigos/novos |
| C09 | API narrativa pública e integração Mestres R2 / Narrativo+Marcial+Progressão | C02,C04,C05,C07; API e provas trusted | Matrícula/saída/transferência autorizadas; mestre indisponível; Qi/stamina reais; tickets→reveal/learn; save/reopen; sem mocks | C09; restaurar Narrativo+exo_martial+progressão do mesmo checkpoint; nunca deixar duas relações principais |
| C10 | Humanoides R2, equipamentos/poses e arte liberada / Rig+Wardrobe+Arsenal+Arte | C04,C08,C09; recursos com proveniência aceita | Classic/slim; outer layer; roll/2M/bainha; persistência visual; sem duplicar armadura; skins em quarentena fora do pacote comercial | C10; remover somente nós/feature R2 e restaurar seleção compatível; nunca trocar rig por humanoide genérico |
| C11 | Limpeza por prova, regressão final e benchmark pareado / Integrador+QA | Todos os gates anteriores ou escopo formalmente reduzido | PLANO-QA completo, regressão/métricas no PC, nenhum asset não liberado em build comercial; relatório humano | C11 candidato da Convergência 03; promoção exige evidência, não só compilação |

## Regras de implementação da sequência

1. Não extrair ZIPs integrais independentes sobre a base. Copiar somente pastas exclusivas de módulos, depois conciliar cada script compartilhado por função/hunk e hash. O CSV e DIFFS-AUDITADOS mostram diferenças, não um patch universal pronto para aplicar.
2. Core 01-P altera 17 arquivos em conjunto, inclusive testes; nenhum teste ou ferramenta deve continuar supondo `collected` dentro de `world.events`. Os 15 preimages atuais coincidem, mas os hashes devem ser conferidos novamente imediatamente antes da futura aplicação.
3. O HUD patch contém `ui/pages/settings.gd`; preservar os consertos de Visual na Cidade Viva. Nenhum `project.godot` laboratorial deve substituir o principal. Registrar módulos usando a pipeline real, manter um único serviço por owner.
4. NPC R2 não substitui R1. Se C03 já mudou `convergence/game.gd`, o instalador R1 pode recusar hash corretamente; portar o diff sob revisão, sem `--force` ou ignorar guardas. Mesmo método em resident/bridge.
5. C05 organiza reserva em primeiro lugar DENTRO do pipeline regional futuro, mesmo que a implementação da Forja entre depois do módulo NPC. Reutilizar planos/IDs persistidos. Se mudar layout exige versão/snapshot explícito, não reroll de cidades já visitadas.
6. C06 pode testar transições sem loot real. C07 não é liberado apenas porque a entrada funciona. Instituições exigem rota específica de interior geral; não duplicar player ou save. Manter exterior em RAM até snapshot/unload provado.
7. C08 e C09 podem ser desenvolvidos em commits separados após suas dependências, com validação sequencial na integração. Este documento não autoriza agentes paralelos nem novos geradores.
8. C10 pode testar geometria própria com recursos autorizados sem liberar as skins em quarentena. Se a autoria não for resolvida, a distribuição comercial exclui/substitui esses assets; não presumir licença pelo nome EXO.
9. Rollback sempre corresponde a um par código+save. Migração world/schema 2 não se desfaz editando o número do schema. Copiar saves reais só como backup/fixture e manter intactos os originais.

## Bloqueios que não podem virar “compatibilidade futura” indefinida

O dono de cada gate deve registrar arquivo/função implementada, teste nativo, retorno no erro e evidência de reopen. Atomicidade Dungeon×R3, API narrativa e backup válido são correções de contrato/código; parser e benchmark são validações ainda não executadas. Separar os dois tipos no relatório de integração. Se faltar orçamento para concluir uma fase, entregar checkpoint completo e manter a função desativada com limitação explícita.
