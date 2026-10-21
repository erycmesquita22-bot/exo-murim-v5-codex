# EXO-Murim — Convergência 02 / EXO Core 01

**Status: CANDIDATO FUNCIONAL VALIDADO. Promoção a OFICIAL estável bloqueada.**

O projeto real foi integrado, importado e executado na Godot 4.6.2 Standard Compatibility. A infraestrutura e o ciclo jogável passaram; a entrega não recebe o nome OFICIAL porque a implantação de muralhas em cidades com travessias de rios ainda é recusada. Não foram inventados fechamentos de perímetro nem capturas conceituais.

## Resultado entregue

Registro central com nove módulos, serviços reais, eventos normalizados, IDs qualificados compatíveis com os IDs existentes, ciclo de inicialização, coordenador único de save, migração opcional mantendo v4 e template executável. Merge do Núcleo Narrativo com os diferenciais da Skin e biblioteca Forja 03, sem sobrepor ZIPs. Casas e controladores aprovados permanecem; novos anéis urbanos usam GLBs V03.

O contrato Estrada dos Salteadores foi aceito de um NPC da vila 15. O roteiro viajou pela ligação real para a região 6, recebeu dano e derrotou inimigos com PV/IA originais, coletou loot, alcançou nível 2 por combate e retornou ao mesmo contratante. Recebeu XP/bronze/reputação e memória social, equipou arma, esquivou, salvou e encerrou o processo. O segundo processo confirmou os estados e a recusa de recompensa repetida. Foram usadas entradas de ataque e movimento reais; posições de observação/entre etapas foram controladas pelo roteiro e houve cura de segurança quando necessário. Não foi sessão humana.

## Testes desta execução

| Suíte | Resultado | Escopo |
|---|---|---|
| core | PASS | 20 verificações |
| jornada | PASS | 4.053 verificações |
| narrativa | PASS | 2.539 verificações |
| narrativa_reopen | PASS | processo novo |
| skin3d_rendered | PASS | 146 resultados |
| forja03 | PASS | 15.032 verificações |
| fortifications | PASS | 36.029 verificações |
| persistencia_interrupcao | PASS | 8 verificações |
| falha_escrita_derrota | PASS | 8 verificações |
| module_template | PASS | harness nativo |
| modulo_novo_opcional | PASS | 12 verificações |
| aceitacao_A | PASS | 53 verificações |
| aceitacao_B | PASS | 11 verificações |
| integracao_fisica | PASS | 8 verificações / 378 cápsulas |
| assets_rendered | PASS | 30 verificações |
| playable_legacy | PASS | 14 verificações |

Regressão herdada: 38 suítes, 38 PASS após a correção do teste multi-seed; logs da tentativa que falhou foram preservados. Mundo Vivo R3: 7 processos/suítes PASS, incluindo A/B/C de persistência, repetição de combate, inventário, dia completo de NPCs e reabertura.

A primeira execução revelou falhas reais nas fontes que só tinham testes offline: parse/estado inicial da Narrativa, declaração de variável na Skin e normalização cosmética após JSON. Foram corrigidas e reexecutadas. O teste offline da Skin foi atualizado para conferir o manifesto auditado da integração e hashes protegidos; a lista fixa antiga de sete arquivos só descrevia o ramo Skin sobre R3. Também foi retirado o caminho fixo /mnt/data do relatório do teste, usando saída relativa ao projeto.

O teste de interrupção encerrou abruptamente um processo Godot na janela entre backup e rename; outro processo recuperou o commit anterior. O teste de falha de escrita usa um caminho de teste inexistente: a derrota reverte estado, loot, XP e recibos, mantém o inimigo válido e confirma uma única recompensa ao repetir com escrita funcional. O relógio do encontro legado foi suspenso somente no roteiro desse teste para comparar o documento transacional sem avanço temporal independente.

## Desempenho medido

Processos sequenciais, seed 101, 1152×720, perfil Equilibrado, sem FPS fixo, 20 quadros de aquecimento e 90 amostras por região. Host AMD EPYC 9V74, 9 vCPU; renderização OpenGL Compatibility por CPU llvmpipe. Não extrapolar esses FPS para o PC do proprietário. Amostra curta, sem alegação de ganho estatisticamente significativo.

| Cena / versão | FPS médio | P95 quadro (ms) | Memória (MiB) | Nós | Carga (ms) |
|---|---:|---:|---:|---:|---:|
| Região 78 / R3 | 17.0 | 66.95 | 262.0 | 26157 | 5152.0 |
| Região 52 / R3 | 20.1 | 63.47 | 133.2 | 4387 | 1287.9 |
| Região 86 / R3 | 13.3 | 79.92 | 145.8 | 6064 | 1581.3 |
| Região 78 / CORE | 17.1 | 63.20 | 275.7 | 28662 | 4998.0 |
| Região 52 / CORE | 20.6 | 61.51 | 137.0 | 4470 | 1334.8 |
| Região 86 / CORE | 13.1 | 81.17 | 149.8 | 6165 | 1616.4 |

Os resultados brutos contêm tempos por quadro, geração/carga e contagens de NPCs, inimigos e casas. O delta integrado não isola o custo da Narrativa ou da Skin; esses ensaios por componente são NOT_RUN.

## Capturas reais

13 PNGs do viewport Godot, sem composição conceitual: criador, Skin 3D, aldeia em duas escalas, diálogo com NPC, diário/contrato, inimigos, combate/saque, recompensa/memória, vila, cidade, portão e reabertura. A captura adicional da cidade usa uma sessão de enquadramento própria com o mesmo projeto e seed. Não são prova de aprovação artística humana.

## Limites e bloqueio da versão oficial

- FAIL para implantação de anel urbano junto a rios sem solução física aprovada. O adaptador marca BLOCKED e conserva a cidade acessível, em vez de construir muralha parcial. A cidade 78 sem esse conflito foi construída e validada; não generalizar a todas as regiões.
- As 163 malhas estão na biblioteca. Novos halls/compounds maiores foram testados nos laboratórios da Forja, mas não substituem as parcelas pequenas das casas do Genesis. Construções anteriores e acessos foram preservados.
- Os três cenários narrativos continuam lógicos; não foram declarados missões físicas. O fato narrativo da aceitação é a conclusão de contrato e a memória de ajuda do contratante.
- Acessórios/UV/skin foram validados pelo teste e capturas; revisão humana de todo clipping/composições é NOT_RUN. Gatecapsule testa geometria, não uma nova rotina de NPC viajando para fora da cidade.
- Core/Narrativa têm limite de 12.000 recibos, com recusa explícita ao saturar. Necessária futura política de arquivo para campanhas que excedam esse limite.

Nenhuma falha crítica de parse, ausência de recurso ou regressão funcional ficou aceita como PASS. A pendência arquitetônica acima impede usar o nome OFICIAL solicitado para esta entrega.

## Reprodução

Extraia o pacote completo e importe project.godot com Godot 4.6.2 Standard Compatibility. Execute F5. O diretório de saves anterior foi preservado; para testes use os caminhos exclusivos dos roteiros, não o seu save pessoal.

Execute `--headless --path . --script res://exo_core/tests/qa_core.gd` e `qa_integration.gd`. A aceitação requer display Compatibility: `--path . --script res://exo_core/tests/qa_acceptance.gd`; encerra ao concluir. Em outro processo, repita com `-- reload`. O teste de persistência tem duas chamadas: `qa_persistence.gd -- crash` (saída por kill é esperada) e `qa_persistence.gd` para recuperação.

O PATCH aplica-se ao Núcleo Narrativo 01 completo e contém somente diferenças, com manifesto SHA-256. Não aplicá-lo cegamente à R3 ou Skin isoladas. O pacote completo é autocontido. Fontes de entrada e linhas auditadas foram mantidas separadas do checkout; commits/checkpoints constam nas evidências.

## Conferência do pacote completo

PASS: extração nova do ZIP, importação sem cache na Godot 4.6.2 e reexecução dos 20 testes do Core e oito testes de integração (incluindo 378 consultas de cápsula nos portões). Nenhum SCRIPT ERROR ou ERROR de importação. A lista SHA-256 de código permite conferir que o código entregue é o mesmo dessa extração; apenas documentação/evidências foram atualizadas depois desse gate.
