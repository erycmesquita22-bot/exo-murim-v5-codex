# Atualização de cidades, casas Forja e terreno

Implementação solicitada nas três referências do proprietário: casa Forja de telhado azul escuro, acabamento vivo e cidade panorâmica como direção urbana. As referências são conceitos visuais, não texturas recortadas para o jogo. Seus hashes estão em city-visual-reference.json.

## Alterações

- Casas: 14 peças GLB originais do pacote Forja restauradas com hashes em city-forja-assets.json; montagem modular de dois pavimentos visuais, paredes claras, madeira aparente, janelas e telhado inclinado azul escuro. Nenhuma sobreposição com um segundo construtor de cidade: Settlement Forge mantém registros, colisão, portas, interiores e salvamento. O acesso interno continua no térreo habilitado; a fachada não cria andares acessíveis fictícios. Peças simplificadas antigas destas 14 responsabilidades foram removidas dos catálogos ativos e do gerador de substitutos.
- Geometria estática das casas agrupada por material e compartilhada entre instâncias do mesmo modelo. As dimensões horizontais seguem os lotes aprovados; varanda lateral não é adicionada no modo host para respeitar a circulação.
- Urbanismo: prioridade para distritos compactados a 0,62 da distribuição anterior, sem encolher as casas. Lotes residenciais adicionais ocupam trechos seguros da mesma malha. Metas máximas de 10/26/48 construções para aldeia/vila/cidade; obstáculos podem reduzir o total. Rios, monumentos, estradas, limites e outras construções continuam vetando locais inseguros.
- Terreno: ruas urbanas selecionam pedras de praça claras e quentes em escala de 6m por repetição, separadamente do tipo de rocha do bioma. Caminhos rurais continuam de terra. Máscaras existentes mask_grass_dirt, mask_dirt_stone e mask_stone_grass controlam a irregularidade nas bordas, com tiles de transição pedra/terra e pedra/grama. Amostragem em coordenadas contínuas do mundo e mesmos parâmetros nos três filtros visuais.
- Multidão: 4/8/12 vias verificadas no máximo, respectivamente, com capacidade proporcional à extensão de cada rua e espaçamento nominal de 9/6/4,5m. Horário, distrito, configurações e disponibilidade física reduzem a população. Corredores sobrepostos não recebem multidões duplicadas. Limites totais mantidos em 180 figurantes PC e 80 celular; estes limites não são uma promessa de FPS. Figurantes mantêm aparência completa dos NPC04, circuito contínuo e nenhuma autoridade de combate, persistência ou interação.
- Iluminação: os 42 modelos produzidos pelo gerador Forja agora exportam normais explícitas com faces planas. O montador também limita filtragem anisotrópica aos materiais que possuem textura: aplicá-la às peças sem UV/textura as tornava pretas no Compatibility 4.6.2. A comparação OpenGL direta antes/depois confirmou a correção; a geometria veio do mesmo gerador autoral recebido.

## Verificação real

Engine oficial 4.6.2.stable.official.71f334935. Consulte os logs e summary.json entregues no pacote QA; resultados históricos anteriores não substituem estes.

- city-final: execução integral das 16 suítes, seguida de regressões específicas após a deduplicação de corredores e a correção das normais.
- city-normals-regression: recursos, atualização Drive/modelos, bugs reportados, portões e regiões. Verifica normais dos 42 modelos e passa pelas portas de todas as construções amostradas.
- Regiões: três sementes (101, 707, 816204), aldeia/vila/cidade e áreas selvagens, ruínas e aproximações de masmorra. Os resultados contêm contagem de casas, distância ao vizinho, compactação e capacidade de figurantes antes dos redutores. Cápsulas, entrada/saída e contratos das rotas NPC04 são exercitados em runtime.
- Capturas reais OpenGL Compatibility via Mesa/llvmpipe mostram ruas e panoramas das três escalas. Renderização por software não mede desempenho na GPU do jogador.
- Importação e replay da extração final do ZIP constam no pacote QA. ZIP verificado por CRC e SHA-256 de cada arquivo.

## Limites e proveniência

O resultado usa as referências como direção; não é reprodução pixel a pixel da arte conceitual. Desempenho em Windows/Android, sessões prolongadas e todos os mundos possíveis não foram homologados nesta rodada. Os pavimentos superiores visuais não ampliam os interiores acessíveis.

As 14 peças foram reintegradas pelo pedido explícito do proprietário de usar suas casas Forja. O pacote declara geometria original por código, mas o arquivo tools/build_assets.py citado não foi recebido. Essa ausência e a comprovação individual pendente estão registradas; não foram substituídas por uma alegação de auditoria jurídica concluída. Mantida a autorização anterior para FighterArt e Terrain Forge, com documentos prometidos. As demais peças antigas sem comprovação não foram restauradas em bloco.

Extraia esta build em pasta nova e crie uma nova jornada para avaliar o novo plano urbano. Não misture os arquivos com a entrega anterior.
