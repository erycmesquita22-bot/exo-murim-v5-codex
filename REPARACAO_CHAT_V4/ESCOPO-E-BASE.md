# Reparo Chat C02 — continuidade da V4

Fonte fornecida pelo diretor: https://chatgpt.com/share/6ad80128-9224-83e9-9892-50fc27948ffd?ogimg=plain — “Coletânea de bugs”. A última resposta entrega três patches candidatos, explicitamente ainda não aplicados nem homologados na Godot.

Base integral recuperada: EXO-MURIM-CONVERGENCIA-V4-CONSOLIDADO-C01.zip, 314611172 bytes, SHA-256 `8796e58d3f8905f0edb37bac6344481a6a173342269f874cf8b993eb7b53522e`. CRC de 6588 entradas e SHA-256 dos 6587 arquivos do manifesto: PASS. ZIP original preservado separadamente. Os relatórios R01–R07 foram encontrados, mas seus ZIPs integrais não foram recuperados; não são usados como prova de código instalado. Esta entrega deriva da C01, sem reconstrução da C3.

## Reconciliação dos patches

1. A C01 não contém o recorte R01. Implementado recorte da linha central em um quadrado reduzido por meia largura da rua, com margem de 0,25 m. Rejeita NaN, infinito, degeneração, dimensões inválidas, altura inválida e malha excessiva. Mantém materiais Terrain R3 e o consumidor da Biblioteca existente. Recorte visual não equivale a corrigir pontes ou rios.
2. Os NPCs reais não usam simplesmente PNGs clássicos de 64×64: Wardrobe/EXO Identity produzem texturas de 256×256. O host copia os pixels finais de `Resident.rig.skin.albedo_texture` para um atlas 2048×2048, 64 slots, sem redução de resolução, repintura ou alteração das fontes. Slots excedentes repetem somente essas mesmas imagens. Recibo da cena registra IDs e SHA-256 RGBA. Atlas ausente ou inválido bloqueia o Crowd; sem fallback demonstrativo. O importador offline de skins 64×64 também foi corrigido para preencher todos os slots, mas não gera o atlas de produção desta integração.
3. O host certifica quatro faixas de 12 m, cada uma com 49 amostras; exigir um segmento consecutivo de 16 m bloquearia todos os figurantes. O planejador passa a usar comprimento acumulado e preservar pontos intermediários, com trajetos de 9 até min(16, comprimento certificado) m. Sem reduzir a exigência física do host. O renderizador percorre o trajeto uma vez e para no destino; o diretor mantém o replanejamento existente. Ajustados pivôs de ombros/quadris e altura das pernas, que antes deixavam os pés suspensos. Crowd continua decorativo, sem inventário, colisão, combate ou save individual.
4. Conferido diretamente `convergence/game.gd`: o fallback persistente “Siga as trilhas…” ainda estava presente na base recuperada. Agora retorna vazio quando não há alvo. Dicas contextuais existentes preservadas.

## Limites deliberados

Ainda não há circulação urbana com destinos de mercado/casa/instituição: ao terminar o percurso o figurante espera pelo replanejamento existente, que pode reposicioná-lo. Texturas são compartilhadas; cabelos volumétricos, vestuário 3D, outer layers, corpos slim e equivalência completa de malha ainda não são compartilhados. Não anunciar aparência idêntica ao NPC completo.

Água/pontes, distribuição de vegetação, regiões vazias, regressão arquitetônica, Forja V4, ciclo completo das dungeons, diálogo com IDs técnicos e demais pendências da apuração não são declarados corrigidos por estes patches. A arquitetura e os assets C01 não foram substituídos nesta rodada. Versões descritas apenas em relatórios R02–R07 não foram reconstituídas às cegas.

A aprovação numérica, visual automatizada e funcional deve ser lida no relatório de testes desta rodada, distinguindo PASS, FAIL, BLOCKED e NOT_RUN. Nenhuma evidência é apresentada como sessão humana ou aprovação artística.
