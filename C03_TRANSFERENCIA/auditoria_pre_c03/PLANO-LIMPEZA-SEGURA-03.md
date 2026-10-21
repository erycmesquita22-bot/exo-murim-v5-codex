# Plano de limpeza segura — nenhuma exclusão executada

Critério: só classificar REMOVÍVEL COM PROVA quando não houver referência estática, caminho dinâmico, import/export, dependência de save, teste necessário nem decisão artística pendente. A busca por texto sozinha não prova ausência de caminhos construídos dinamicamente. Nesta auditoria, não se demonstrou removibilidade definitiva de nenhum arquivo de gameplay.

| Caminho real / conjunto | Classe atual | Evidência e motivo | Prova necessária / momento |
|---|---|---|---|
| `convergence/game.gd::HOME_GATE`, `legacy_active`, `return_home`, placa RECINTO INICIAL | SUBSTITUIR | Código ativo; retorno e entrada usam recinto legado | C03 criação→região e retorno seguro; varrer callers e testes antes de retirar blocos em C11 |
| `murim_flow.gd` (LEGACY_BED/MAT, PATROL, RUIN_SURVEY, criação) | PRESERVAR / SUBSTITUIR blocos | Serviços, missão, prólogo e criação compartilham arquivo | Desacoplar aventura procedural de coordenadas fixas; testar treino, descanso, ruínas, morte; não apagar arquivo inteiro |
| `main.gd`, `world/biome_plan.gd`, geradores da região inicial | PRESERVAR até separar | `create_character` chama rebuild_region e resume_checkpoint | Grafo de boot/spawn/prologue; cenas de treino/lab podem continuar usando partes |
| `exo_dungeon/generator/generator_v3.gd::generate` e geração V2 | PRESERVAR | Dungeons pinadas V2/V3 e digests persistidos dependem deles | Nunca remover por serem antigos; QA por versão e fixtures persistidas |
| `exo_dungeon/docs/historico_r2/` e manifestos antigos | PRESERVAR como evidência / candidato a excluir só da exportação | São históricos, não fonte atual; não são “módulo ativo duplicado” | Separar documentação da export com lista verificável; manter histórico no checkpoint |
| Forja `MANIFESTO-SHA256.json` antigo | SUBSTITUIR metadado / preservar histórico | 14 divergências após revisão; ADENDO-FILE-SHA256 cobre 61 membros atuais | Renomear/rotular histórico e emitir manifesto de release novo pelo owner, sem reescrever prova antiga |
| `exo_martial/integration/mock_narrative_r2.gd` | QUARENTENA de produção | Mock só laboratório; API narrativa real ainda ausente | Não registrar serviço/empacotar como implementação; testes podem retê-lo fora do runtime |
| `npc_system02/tests/`, `exo_items/tests/`, labs Forja e Dungeon | PRESERVAR para QA; exclusão futura da distribuição se provada | Fixtures e suítes necessárias | Confirmar que manifesto de export usa somente runtime; não substituir project.godot principal pelo de lab |
| `source_reference/`, `logs-validacao/`, `validation_r3/`, relatórios/evidências | PRESERVAR no arquivo de desenvolvimento; candidato de exportação | Histórico e reprodução do QA | Provar não leitura em runtime e excluir só do pacote exportado em C11; não apagar backups de trabalho |
| `exo_humanoids03/assets/` PNGs herdados da distribuição Humanoides 03 | QUARENTENA comercial | 480 PNGs 64×64, origem técnica sem titularidade demonstrada | Matriz por asset/hash/autor/cessão/revisor; substituir por arte própria autorizada se não liberados |
| `exo_creature_harmonizacao02/` e fontes Forge/Art | PRESERVAR / deduplicação pendente | 20 variantes GLB representam 17 identidades, algumas variantes são intencionais | Comparar SHA binário, usos em tscn/catálogos e decisão de variante; não remover por contar 2 arquivos da mesma espécie |
| Materiais/texturas repetidos no Core/Forja/Visual | PRESERVAR até prova | Nenhum grupo foi declarado redundante só por nome | Agrupar hashes binários idênticos, mapear recursos e imports, atualizar referências em branch, reimportar e testar PCK |
| Sons/skins/models/fontes herdados sem evidência de direitos | QUARENTENA do componente relevante | Origem em pacote EXO não prova titularidade | Inventário por hash e evidência comercial; sem apagar originais durante a auditoria |
| `exo_benchmark/benchmark_city78.gd` do KIT CORRECAO-03 | SUBSTITUIR no kit | Falha real de indentação linha 70 em log PC | Owner QA corrige kit e roda parse; não alterar jogo como suposta solução desse erro |
| Instrumentos debug, IDs `r10_l000` na UI, marcadores visíveis/sonoros | SUBSTITUIR UX; preservar internamente IDs | IDs são identidade de jogo; exposição indevida é problema de apresentação | Alterar labels/debug gating e testar, não renomear chaves persistidas |
| `journey.json`, `.bak`, `.tmp`, `.pre-corep01.json` e fixtures | PRESERVAR | Autoridade, recovery e rollback | Avaliar caso individual; nunca limpar automaticamente nem testar contra user-dir de campanha real |

## Protocolo para promover um item a REMOVÍVEL COM PROVA

Gerar grafo de `preload/load/ResourceLoader`, cenas e imports, export presets, catálogos JSON, caminhos concatenados e referências em scripts de teste. Identificar a cena de boot real e chamadas herdadas. Fazer busca de IDs em fixtures/saves de teste sem editar os originais. Para mídia, verificar SHA e não somente nome/tamanho. Listar callers encontrados e decisão do owner. Somente em cópia, retirar do conjunto exportado ou substituir referências; importar sem cache e executar build/PCK e regressões. Guardar diff, hash e rollback. A exclusão física de fonte, se necessária, acontece em commit próprio posterior.

“Não encontrado em busca” permanece evidência insuficiente se o caminho for dinâmico. “Antigo” não equivale a morto. A vila legada deve sair do fluxo de aventura, mas seus sistemas compartilhados não podem desaparecer antes da separação. Não reintroduzir o Wizard azul como fallback.
