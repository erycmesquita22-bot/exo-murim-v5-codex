# EXO-Murim V5 — entrega técnica

Estado: BASE INTEGRADA, VALIDADA NOS FLUXOS ABAIXO; NÃO HOMOLOGADA COMO PRODUTO COMERCIAL COMPLETO.

## Resultado atual

- PASS: 11/11 partes da origem, SHA-256/tamanho/CRC conferidos; nenhuma sobreposição. Origem contém 6701 arquivos; divergência de uma entrada no manifesto recebido, cujo hash da parte 01 confere.
- PASS: importação Godot 4.6.2 oficial em cópia sem cache; importação limpa repetida no checkout de trabalho. SHA-512 da distribuição oficial conferido.
- PASS: 13 suítes nativas na cópia de entrega. Cada uma tem comando, exit code, resultado e diagnóstico em final-verified/summary.json. Sem erros de engine nessas execuções finais.
- PASS: carregamento de 1052 scripts/cenas/recursos; Core 20 checks; contratos Core 43; itens atômicos 16; economia 1068 verificações; artes marciais 1857 verificações unitárias. Estes testes unitários não substituem gameplay.
- PASS: campanha 37 checks: personagem, mundo, serviços, associações LivingWorld/edifícios, NPC04, movimento físico, interiores com física, save, recuperação pelo host, reabertura e troca de seed/campanha.
- PASS: gameplay 30 checks: cura/consumo, equipamento, técnica real/VFX autorizado, comerciante NPC04 físico, compra, saldo exato, idempotência, missão de conversa completa com recompensa não duplicável, combate recebendo dano, derrota, XP e loot.
- PASS: dungeon 12 checks: região/entrada física, E real, instanciação, piso após aterrissagem, checkpoint Core, saída e recuperação do exterior.
- PASS: portões de cidade 9 checks, incluindo 108 amostras de cápsula e suporte de piso.
- PASS: 18 regiões em três seeds (101, 707, 816204), aldeia/vila/cidade, áreas selvagens/ruínas/acessos; 211 ciclos de entrada/saída de portas e verificação de acesso por cápsula nas nove amostras urbanas.
- PASS: renderização real Compatibility/OpenGL por software, capturas de menu/criador/assentamento/interior. Mesa llvmpipe em Xorg virtual, áudio Dummy explícito; não representa GPU de jogador. Medição de 60 frames no log, sem extrapolação a Android/PC.
- PASS: replay determinístico de 1441 arquivos novos gerados, sem ler arte herdada. Primeiro replay normalizou literais numéricos de cenas; replay canônico subsequente foi byte a byte idêntico.

## Correções verificáveis

NPC02 e NPC03 retirados; ator/diretor NPC04 únicos. Interior Forge anterior e materializador urbano anterior retirados; Settlement assume os interiores urbanos. WorldGenesis/Settlement/NPC04 registrados no Core, com donos distintos. Identidades permanecem no LivingWorld; associações de moradores/trabalhadores nos edifícios são índices derivados reconstruídos, não outro banco ou escritor de save.

Corrigidos contrato de bounds dos props substitutos, precedência NPC/porta, evento de conversa perdido ao abrir comércio/treino, dependência indevida da interação em culling visual, reinicialização de serviços ao trocar campanha, restauração assíncrona continuando após descarte da região, validação do snapshot de interior, recuperação do portal pelo host, cutaway dos interiores e UV do retrato 256/64 no HUD. VFX passou a receber release do Techniques real com autorização em processo, sem duplicar dano/energia.

Logs anteriores que falharam estão em history/. Não são apresentados como PASS. A primeira tentativa de piso de dungeon verificou cedo demais a queda de entrada de 1,5 m; a checagem final aguarda aterrissagem e usa física real. Dano em assentamento é recusado pela zona segura; o teste não o contorna: testa a recusa e exercita separadamente o callback real de recuperação do host.

## Autoria e conteúdo

1676 arquivos criativos herdados foram excluídos ou substituídos; outros 58 registros tratam de metadados de localização/importação regeneráveis, não de arte de terceiros. O índice registra 1734 entradas históricas ao todo. Nenhum PNG/GLB/áudio/fonte/GIF/PDF herdado foi aprovado por nome ou licença comercial. Não foram mantidos os diretórios de assets vetados; caches antigos também foram removidos. A distribuição não inclui Git, caches, arquivos de usuário, fonte OTF vendorizada ou binários da engine.

A arte substituta é nova, gerada por código, simplificada. Sons são sinais sintetizados, não vozes/foley/trilha equivalentes. Layouts, materiais, shaders e código editáveis fornecidos possuem proveniência declarada separada; a auditoria técnica não inventa comprovação independente de autoria. A liberação comercial integral desses conteúdos declarados continua BLOQUEADA até evidência suficiente/revisão do proprietário. Não tratar o ZIP como release comercial homologada.

A biblioteca de 52 plantas foi preservada integralmente. O handoff recebido trabalha com dez plantas térreas por função: pisos superiores e todas as variantes do catálogo não foram homologados.

## NOT_RUN / BLOCKED

- NOT_RUN: exportação Windows/Steam, dispositivo Android, controle por toque, áudio em hardware e desempenho em GPU de jogador; testes humanos extensivos, todas as seeds e todo o catálogo de habilidades/mestres.
- BLOCKED: liberação comercial integral das fontes criativas declaradas, sem comprovação adicional. Arte/voz/trilha finais seguem a lista content-to-replace.md.
- BLOCKED por transferência: EXO-MURIM-CODEX-FONTES-DO-PROJETO-21-10-2026.zip, sediment file_0000000092a0820e88471e4744a17ac5, excede 32 MiB. Não foi necessário para executar a origem reconstruída das 11 partes; conteúdo adicional e equivalência desse ZIP permanecem desconhecidos.

Não há falha bloqueadora conhecida aberta nos fluxos que as suítes finais demonstram. Isso não equivale a afirmar ausência de todos os bugs ou conclusão de funcionalidades não cobertas.
