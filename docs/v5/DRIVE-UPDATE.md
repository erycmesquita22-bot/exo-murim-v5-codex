# EXO-Murim V5 — atualização do Drive (21/10/2026)

IMPLEMENTADO E VALIDADO nos fluxos descritos. Não é homologação comercial nem garantia de ausência de todos os bugs.

## Resultado entregue

- 7 ZIPs acessíveis, CRC e SHA-256 registrados; 7915 arquivos de entrada inventariados em drive-input-files.json. Documento de pacote é evidência de origem/contrato, não instrução para sobrepor o host.
- 216 paletas FighterArt/EXO restauradas do projeto anterior; 113 texturas/atlas Terrain Forge restaurados. Código Terrain R3, lógica atual de campanha, colisões e persistência preservados.
- 91 OGG Sound Forge com hash conferido contra config/events.json e task IDs fornecidos. O mixer EXO existente continua sendo único dono de reprodução; aliases mapeiam combate, impactos, esquiva, equipamento, UI e fases existentes. Porta só toca após transição real. Eventos não mapeados não ganham gatilhos inventados. Passos multietapas não são tocados como um passo isolado.
- 42 modelos Forja reconstruídos do gerador editável recebido. Os bytes exportados não coincidem com os GLBs originais nesta versão das ferramentas; não se alega replay binário. Os novos arquivos são fonte gerada inspecionável. Catálogo atualizado; tochas são consumidas pelos edifícios reais, sem alterar a passagem da porta. Não se afirma que cada modelo do catálogo apareça em toda cidade.
- Criador organizado em traços, vestuário, acessórios e armaduras; estilos Discípulo, Andarilho, Guarda e Erudito; prévia parado/caminhando/ataque e personalização persistida. Importação PNG 64×64 e suporte classic/slim mantidos.
- Hive integrado com rig completo Rig/Wardrobe/Skin3D/VisualR10 e poses compartilhadas do NPC04. A seleção visual resolvida do NPC original é reaproveitada numa cópia; não se sorteia roupa inferior. Nenhum NPC03, corpo físico, carteira, missão ou save de figurante foi instalado.
- Adaptador Crowd agora reconhece o dono físico Settlement Forge; população só é criada após amostragem física dos corredores. O teste com câmera real do jogo observou 4 rigs visíveis em 2 zonas, com 8 figurantes planejados nesta amostra. Não é população prometida para toda seed/região.
- VFX Forge 03 já estava integrado; comparação de fontes e exposição do método de vínculo confiável concluídas. Não se copiaram o projeto standalone, prévias ou game.gd antigo.
- Proteções contra void, barreiras das casas, restauração segura de visita e resgate pelo marco/laboratório continuam ativos.

## Evidências desta revisão

- PASS: drive-final/summary.json, 15/15 suítes Godot 4.6.2 oficial: atualização do Drive, segurança de interiores, recursos, NPC04, WorldGenesis, Core, contratos Core, itens atômicos, economia, artes marciais, portões, campanha, gameplay, masmorra e regiões.
- PASS: drive-last-code/summary.json: atualização do Drive, campanha e gameplay repetidos após preservar exatamente a seleção de vestuário do NPC no figurante. O teste de atualização registra 32 verificações, incluindo os 42 modelos instanciados, 91 OGG decodificados pela engine, textura de terreno ligada ao shader real, callbacks dos botões, prévia animada, personalização salva/reaberta e figurantes visíveis. Callbacks de botões são acionados por seus sinais no teste; não são teste de toque Android nem validação de cada área clicável.
- PASS: segurança física das 52 plantas e 1860 bordas expostas; caminhada em +Z desde spawn por 120 frames por planta. Não é percurso exaustivo de todos os pontos e andares.
- PASS: 18 regiões, 3 seeds; 211 ciclos de entrada/saída e verificações de piso/rotas na suíte de regiões.
- PASS: capturas reais OpenGL/Mesa llvmpipe do menu, criador, estilos, assentamento e interior; conferência visual do vestuário. Medição é software em nuvem, não benchmark de GPU alvo.
- Histórico: drive-functional/ contém uma tentativa FAIL que revelou a exigência do dono City Forge antigo e uma asserção de teste que consultava a lista de roupas errada. O primeiro foi corrigido no adaptador; o segundo foi corrigido para consultar as instâncias Skin3D realmente usadas. Resultados posteriores PASS, sem ocultar o histórico.
- NOT_RUN: Windows/Steam e Android exportados/executados, áudio em hardware e aprovação perceptual dos 91 sons, sessões longas e benchmark em dispositivo alvo.
- BLOCKED para homologação comercial: fontes/histórico prometidos para as imagens autorizadas ainda não anexados. Não se inventaram certificados de titularidade ou resultados jurídicos.

## Proveniência e exclusões

O proprietário autorizou explicitamente: “Tenho, pode os usar e eu implemento a comprovação depois.” A exceção às exclusões históricas abrange os recursos listados em drive-owner-art.json. As 480 skins legadas, pack de vila de terceiros, fontes e foley externos continuam excluídos. As demais árvores do projeto antigo não foram sobrepostas. drive-provenance.json registra a decisão de cada pacote e content-to-replace.md identifica recursos/validações restantes.

Os 121 modelos herdados V3 e os 86 V4 não foram restaurados automaticamente: o ZIP recebido não contém o gerador base tools/build_assets.py citado nem tools/build_v4.py. O gerador efetivamente acessível é tools/build_assets_v3.py, usado para os 42 modelos. Não se declarou acesso aos arquivos ausentes.

A entrega é o projeto Godot completo com a atualização, manifestos, diff, capturas, hashes e logs de QA. Não é export executável Windows/Android.
