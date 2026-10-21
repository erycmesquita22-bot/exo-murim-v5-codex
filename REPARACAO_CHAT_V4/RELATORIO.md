# EXO-Murim V4 — Reparo Chat C02

Reparação incremental das três propostas finais de “Coletânea de bugs”, mais a remoção confirmada da dica persistente. **Entrega parcial; não é homologação global da V4.** Escopo, adaptação dos patches e limitações: ESCOPO-E-BASE.md.

Base integral C01: SHA-256 `8796e58d3f8905f0edb37bac6344481a6a173342269f874cf8b993eb7b53522e`. CRC e todos os 6587 hashes do manifesto: PASS. Não foram recuperados os ZIPs integrais R01–R07; os relatórios isolados não foram tratados como código instalado.

## Resultado antes × depois

| Componente | C01 observada | C02 efetivamente testada |
|---|---|---|
| Pavimentação | Sem recorte/validação numérica de entrada | Recorte considerando largura integral; rejeição de NaN/infinito, degeneração e altura inválida |
| Textura Crowd | `skins_demo_atlas.png` | Atlas de 64 slots copiando os pixels finais de NPCs reais da cena; 256×256 por slot |
| Trajetos, seed101/r78 | 0,46–1,35 m; inversões recorrentes | 9,02–11,61 m; pontos físicos preservados; percurso unilateral e parada |
| Observação renderizada | 157 amostras de inversão em 22,057 s | 0 em 181,781 s, 2873 amostras; 17 figurantes parados no destino |
| Replanejamento | Diretor existente | Mesmo diretor, mesmas faixas físicas; 17 figurantes recompostos sem duplicação de zonas |
| Pernas Crowd | Pés suspensos pela posição/pivô da malha | Pivô no quadril e pés alinhados ao caminho; transformação verificada com OpenGL |
| Dica sem alvo | “Siga as trilhas até as passagens regionais” | Texto vazio; dicas contextuais preservadas |
| Casas, água, pontes, dungeons | Problemas já apontados | Preservados nesta rodada, **não declarados corrigidos** |

O atlas é construído em memória a partir de `Resident.rig.skin.albedo_texture` após a criação dos NPCs. Sem textura canônica válida o Crowd fica bloqueado. Não cria nem substitui skins, não reduz resolução e não usa o atlas demonstrativo. Hashes RGBA e IDs dos fornecedores estão em `evidence/atlas-sources.json`; imagem em `evidence/atlas-npc-real.png`. Isso não significa equivalência de roupa 3D, cabelo, outer layers ou corpo slim.

O host continua aprovando até quatro faixas de 12 m por cena com 49 amostras e cápsulas. A proposta literal de exigir 16 m entre amostras bloquearia o módulo; foi substituída por comprimento acumulado, preservando os pontos intermediários. Não houve flexibilização da prova física. Ao chegar, o figurante espera o replanejamento existente; ainda não escolhe destinos urbanos semânticos e pode ser reposicionado no replanejamento.

## Cenas reais em Godot 4.6.2 Compatibility

Execução automatizada, OpenGL/Mesa llvmpipe, Xvfb, 1152×720, quatro CPUs disponíveis ao processo. Limite gráfico de 15 FPS apenas para QA; **não é benchmark nem medição de desempenho em PC/Android**. A observação de Crowd congelou física/relógio do host para manter a mesma população enquanto o renderizador continuou processando tempo real. Não é uma sessão humana de exploração.

| Seed / região urbana real | NPCs físicos | Crowd | Ruas / vértices examinados | Vértices inválidos ou fora | Slots iguais aos NPCs |
|---|---:|---:|---:|---:|---:|
| 101 / 78 | 48 | 17 | 35 / 3246 | 0 | 64/64 |
| 101 / 14 | 65 | 19 | 34 / 3498 | 0 | 64/64 |
| 707 / 7 | 71 | 16 | 60 / 4080 | 0 | 64/64 |
| 707 / 26 | 57 | 18 | 39 / 3588 | 0 | 64/64 |
| 2026 / 13 | 32 | 20 | 44 / 3420 | 0 | 64/64 |

Foram examinados 17832 vértices e os pontos dos trajetos contra o piso físico real. Os trajetos das cinco cenas ficaram entre 9,019 e 11,996 m. As quatro vias recortadas no r78 comprovam atuação do recorte; isso **não prova** que a imagem anterior da cidade aparentemente fora do mapa tinha essa causa exclusiva.

## Matriz de QA

| Teste | Estado | Evidência / alcance |
|---|---|---|
| Importação e boot gráfico finais | PASS | `import-final.log`, `boot-final.log` |
| Segurança numérica nativa | PASS | 23006 verificações, 3000 faixas candidatas, 2141 aceitas; seis caminhantes/300 s simulados |
| Crowd nativo e contrato R4 | PASS | `crowd-native-final.log`, `crowd-r4.log`; seis lotes de MultiMesh, densidade, horário, reentradas, eventos e detach |
| Transformações dos pés no renderizador real | PASS | `crowd-feet-rendered.log`; consulta GPU não disponível no backend dummy |
| Cinco cenas urbanas / três seeds | PASS | `scene.log`, `after/scene-results.json`; WorldGenesis V4 e City R4 confirmados |
| Observação temporal 181,781 s | PASS | Subteste completo anterior a erro de fixture em `scene-attempt01-fixture-fail.log`; condições descritas acima |
| Reabertura em outro processo | PASS | `reload.log`: três seeds, geração V4, cidade revisitada, atlas reconstruído e Crowd reautorizado |
| Interior físico, entrada e saída | PASS | `reload.log`, `functional.log`; não prova caminhada humana porta a porta ou saída restrita à porta |
| Combate / persistência diretamente afetados | PASS | `functional.log`: 70 técnicas já disponíveis, custos, executor, falhas de save/rollback e recarga |
| Nove de doze suítes históricas obrigatórias | PASS | release, discovery, fidelity, ruins_martial, assets, stabilization, quality09, martial e procedural |
| Três suítes históricas | FAIL, herdado | `tests`, `consolidation_qa`, `legacy_audio_qa`; mesmas falhas reproduzidas na C01 original |
| Primeira matriz multi-seed | FAIL de fixture, corrigido | Presumia r78/r15 urbanas para todas as seeds; revisão escolhe cidades reais. Log da tentativa preservado |
| Primeira consulta de pés em headless | NOT_RUN no backend; tentativa FAIL preservada | Dummy não mantém essas transformações; teste movido ao backend gráfico e aprovado |
| QA humano, Android, desempenho comparativo | NOT_RUN | Sem inferência de homologação |

As 70 técnicas foram exercitadas novamente com a fixture explícita de progressão/equipamento da C01; não significa obtenção natural de todas numa campanha. As falhas históricas não foram apagadas: `tests` instancia main.gd sem o Core esperado; consolidation e legacy_audio têm asserções de catálogo anteriores à V4. Os logs da base e da entrega estão juntos. Não são contadas como PASS.

## Matriz funcional e pendências

| Módulo/área | Estado nesta entrega |
|---|---|
| WorldGenesis V4, City Forge R4, EXO Core e save | Preservados; autoridades verificadas nas cenas e reaberturas |
| Terrain R3 / pavimentação | Ativo, proteção geométrica adicionada; estética geral e pontes pendentes |
| NPC03 / aparência canônica | Preservados; texturas efetivamente consumidas pelo Crowd |
| Crowd Illusion | Parcialmente ativo: aparência/textura e percursos corrigidos; destinos semânticos, roupas/cabelo completos pendentes |
| Skill Forge / executor | 70 técnicas existentes revalidadas por fixture; sem novos desbloqueios |
| Biblioteca / Economia / Jornada | Autoridades e arquivos preservados; não anunciadas novas integrações |
| Interior Forge | Entrada/saída/regressão aprovadas no subconjunto existente; restrição de saída à porta e tipologias restantes pendentes |
| Forja Arquitetônica V4 / casas melhores | BLOCKED nesta rodada: substituição não executada nem homologada |
| Água/pontes, densidade natural, regiões vazias | Pendente, NOT_RUN como correção nesta rodada |
| Dungeons completas / diálogos com IDs técnicos | Pendente, NOT_RUN como correção nesta rodada |

Não houve limpeza geral de legado, mudança de combate, outro sistema de save, geração paralela ou substituição das casas. Os arquivos de evidência antigos continuam históricos; a evidência desta reparação fica exclusivamente neste diretório.

## Entregáveis e recuperação

- Projeto integral C02 com manifesto SHA-256 por arquivo e manifesto de alterações.
- Patches menores: pavimento; atlas; percurso/pivôs; dica de HUD; testes/documentação. Aplicar na ordem indicada sobre a C01 validada, em cópia. Não reaplicar sobre o projeto integral C02.
- CP01 integral de pavimento: SHA-256 `b5325f81b17252de764ddb5c7fab8e777ff395e05352c7728f603217510d51b8`. Contém só o pavimento novo sobre C01; seu ZIP isolado não teve boot separado, e essa limitação consta no próprio checkpoint.
- Rollback completo: ZIP C01 original, preservado. O diretório de dados V4 permanece o mesmo; guarde cópia antes de alternar candidatos.

Reprodução em uma máquina com Godot e display: `python3 tools/run_repair_chat_checks.py /caminho/Godot --rendered`. Para as suítes históricas: `python3 tools/run_checks.py /caminho/Godot`. Não interpretar mensagens PASS isoladas se houver erro de engine no mesmo teste.
