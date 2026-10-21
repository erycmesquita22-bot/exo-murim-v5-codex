# EXO-MURIM — CIDADE VIVA 01 R2

Data: 19/10/2026. Engine: Godot 4.6.2 Standard, Compatibility.

**Estado: CANDIDATO DE CHECKPOINT — sem aprovação definitiva.** Integração executada e verificada automaticamente na Godot. Revisão artística e caminhada humana no computador do proprietário continuam pendentes. Nenhum novo sistema ou teste demorado foi iniciado para este checkpoint.

## Entrega e base

Projeto completo baseado em EXO-Murim-EXO-Visual-01-CANDIDATO.zip, que já contém EXO Core 01 corrigido e Fortificações 02 R2. Aplicado Cidade Viva 01 e realizado o polimento R2. A cena principal continua convergence/game.tscn; não é necessário combinar os pacotes manualmente.

Os documentos antigos no projeto são históricos. Este relatório, cidade_viva/validation/RESULTADOS-CIDADE-VIVA-01-R2.json e os logs desta rodada descrevem a entrega atual.

## Mudanças reais

- Corrigida a leitura do polígono das muralhas. O teste inicial recusava a camada urbana das 16 cidades examinadas; o planejador agora aceita tanto o contrato direto da fortificação quanto o relatório do adaptador central.
- Raios calculados a partir dos bounds reais do catálogo. Reservados os retângulos das edificações, pátios ampliados, estações de fachada dos moradores, acessos, vias e margens de rios/muralhas.
- Tentativas locais por seed e lote, densidade por função, anexos comerciais/marciais e agrupamentos junto às ruas de mercado. Tetos: aldeia 24, vila 86 e cidade 180 objetos adicionais. Um teto não é uma obrigação de preencher espaço inseguro.
- Jardins, hortas, pomares, bambus, pavilhões e anexos do santuário usam os modelos existentes. A grama aprovada é aplicada em pequenas malhas conformadas à altura real do solo; os arquivos de textura originais foram preservados.
- Interação por E prioriza o morador visível mais próximo, alinhando seleção e aproximação em grupos.
- Iluminação urbana acompanha o relógio persistido do EXO. Limites de 2/5/12 luzes locais para aldeia/vila/cidade; lanternas sem sombras dinâmicas.
- Colisão dos objetos usa bounds reais. Árvores colidem pelo tronco; pavilhões têm colisão nos pilares e espaço central livre. Cultivo baixo permite passagem.
- Colisão de terreno: trechos estritamente planos usam BoxShape3D com a mesma superfície superior; relevo e canais não planos mantêm os triângulos originais. Na cidade 78, foram simplificados 76 trechos, com 331 amostras de altura aprovadas, inclusive nas emendas, sob tolerância de 1 mm. A malha renderizada e o algoritmo de geração não foram alterados.
- Geometria estática agrupada por material e material de jardim compartilhado. Reaplicar a camada não duplica objetos, moradores ou estado de save.
- Corrigidos problemas herdados do EXO Visual: chamada de API do renderizador inexistente na versão alvo, indentação inválida na página de configurações e acesso fora do array na prévia do personagem ao selecionar os novos perfis.

## Cidade de referência executada

Seed 101, região 78: **43 construções originais, 65 moradores e 167 objetos urbanos adicionais**, com 12 lanternas locais. O teto configurado é 180. Não foram criadas identidades de NPCs para inflar artificialmente a população.

A camada anterior do Cidade Viva colocava 60 objetos nessa cidade após corrigir a leitura da muralha. O R2 aumenta a ocupação com vegetação produtiva e instalações contextuais. As imagens 01/02 usam a mesma câmera e cidade, com a camada urbana desligada/ligada.

## Verificação executada

- **23 suítes nativas passaram**, sem SCRIPT ERROR, ERROR ou asserção FAIL nos logs finais. Incluem as 13 suítes legadas obrigatórias, Core, extensão de módulos, fortificações fluviais, EXO Visual, planejador urbano, circulação/colisão, portões, ciclo de NPCs e reabertura.
- Planejador GDScript: 92 assentamentos com planos válidos, em quatro seeds (101, 816204, 707 e 18026). Determinismo, não mutação dos lotes originais, limite e reservas de ocupação.
- Circulação: 2988 amostras físicas de cápsula ao longo de 2988 pontos únicos das rotas existentes; nenhum novo objeto sólido bloqueando os trajetos. Controle positivo detectou um colisor urbano real. Reaplicação manteve uma única camada e save idêntico.
- Rotinas: ciclo completo de um dia do relógio do jogo, em fixture acelerada a 5 Hz (passos de 0,2 s), após assentamento inicial a 60 Hz, movimento físico, deslocamentos, trabalho, convivência, descanso, interrupção por conversa e retomada. Resultados completos, inclusive profissões, constam do JSON. Sem simulação de tempo offline. O jogo normal permanece a 60 Hz; este é um teste de estresse contínuo das agendas, não uma sessão de gameplay a 60 Hz. A tentativa integral a 60 Hz foi interrompida pelo custo no host. Na fixture isolada, subárvores visuais dos moradores ficam destacadas, e atualizações do jogador/ecologia ficam suspensas; cada morador executa seu método step real, com locomoção física e colisões. Não é um teste de um dia inteiro de todos os sistemas simultaneamente.
- Persistência: outro processo Godot reabriu a cidade e verificou identidades, vínculos, população, conversas, trabalho e visitas. Sem duplicar os 65 moradores.
- Portões: testes físicos de passagem e apoio no chão. Fortificação fluvial: 52 verificações nativas, incluindo variantes pequena, média e monumental, e cidades reais com rio.
- Gráficos: abertura da página de configurações nos cinco presets e em Personalizado, preferências independentes, fallback de valores inválidos, materiais e preservação do estado de gameplay durante a troca.
- 12 capturas novas do viewport Godot, com seed, região e transformações da câmera registradas. Incluem cidade, serviços, moradias, noite e passagem fluvial.

Erros e tentativas anteriores foram preservados como histórico, identificados por before-fix. Não são apresentados como resultados aprovados. Um teste antigo foi atualizado para o índice atual do perfil Alto. A fixture gráfica suspende o relógio durante a comparação de saves; a fixture headless retira o limite de exibição para executar os mesmos passos físicos sem esperar o tempo de uma sessão humana.

## Desempenho e limites

O arquivo cidade_viva_benchmark.json registra amostras brutas, P95, memória e draw calls, com composição urbana desligada/ligada no mesmo processo gráfico. O benchmark não usa FPS fixo. A simulação fica congelada para isolar o custo de renderização; o host usa llvmpipe por CPU. Esses números **não representam FPS de gameplay, GPU real ou desempenho no computador do proprietário**.

As ruas, posições das casas e o perímetro não foram redesenhados. A cidade ganhou composição e ocupação, mas ainda conserva o traçado amplo anterior; não é uma reprodução exata dos quarteirões e grandes complexos da imagem conceitual. Bancas, cultivo e anexos novos não implementam outra economia, colheita ou interiores. Os moradores continuam usando as rotinas e serviços já existentes do Living World.

Não houve teste humano, cooperativo, Android ou Forward+. Compatibility foi mantido.

## Pendências e problemas ainda não resolvidos

- Aprovação humana da arte, densidade e experiência murim: o traçado amplo e as pequenas casas da base ainda diferem da referência conceitual. Uma reformulação dos quarteirões não foi executada.
- Dia completo com todos os sistemas simultâneos a 60 Hz e sessão prolongada de gameplay: pendentes. A aprovação das agendas vem da fixture isolada descrita acima.
- Benchmark em GPU real, com câmera e simulação ativas: pendente. O ensaio disponível isola renderização em CPU llvmpipe.
- Android, Forward+ e cooperativo: não testados nesta rodada.
- Bancas e cultivos adicionais são ambientais; economia, colheita e interiores novos não foram implementados.
- Auditoria documental de procedência e direitos comerciais dos assets da base: pendente. Os binários originais foram preservados; isso não equivale a uma certificação de licença.
- Outros pacotes paralelos de HUD, mestres, itens, dungeons e bestiário não compõem este checkpoint. A base utilizada é exclusivamente a identificada neste relatório e por SHA-256 no manifesto.

## Falhas encontradas e tratamento

As recusas iniciais das cidades por polígono de muralha, os erros herdados de API/configuração gráfica e os bounds de colisão foram corrigidos conforme a lista de mudanças. O índice legado do perfil Alto foi atualizado no teste. No ensaio acelerado de NPCs, a inicialização grosseira a 5 Hz deixava cinco moradores sem apoio correto; a fixture foi corrigida para assentar os corpos a 60 Hz antes do estresse. A fixture de conversa passou a apoiar o jogador no solo real antes da interação. As tentativas interrompidas e os logs anteriores estão preservados como histórico, sem serem contados como aprovação final. A suíte final aprovou os 65 moradores.

## Abrir e reproduzir

Extraia o projeto completo, importe project.godot na Godot 4.6.2 e aguarde a importação. F5 inicia o jogo. Cidade Viva aparece nas regiões externas de assentamento; o recinto inicial legado continua separado.

Para as capturas: seed 101, cidade 78; cidades com rio 14 e 26. P abre a central, Tab abre o mapa, E interage, R alterna arma/mãos livres e F executa esquiva.

```sh
python3 cidade_viva/tests/run_validation.py /caminho/para/Godot
Godot --path . --script cidade_viva/tests/capture_live.gd
Godot --path . --script cidade_viva/tests/benchmark_urban.gd
```

Capturas podem usar FPS fixo para reprodução. O benchmark deve ser executado sem esse parâmetro, sozinho, sem suítes concorrentes.
