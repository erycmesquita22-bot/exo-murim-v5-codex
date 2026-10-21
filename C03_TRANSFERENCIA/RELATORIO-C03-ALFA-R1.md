# EXO-MURIM — CONVERGENCIA 03 ALFA R1 — RELATÓRIO DE ENGENHARIA

Data: 19/10/2026. **CANDIDATO FONTE — NÃO HOMOLOGADO / QA NATIVO NOT_RUN**.

## O que foi efetivamente feito
- Base imutável conferida por SHA256 e CRC: `EXO-Murim-Cidade-Viva-01-R2-PROJETO.zip`.
- Aplicado Core Persistence 01-P nos 17 scripts do patch, em conjunto; acrescentada validação do backup pré-migração existente por JSON/schema/world ID/seed. **Sem prova de compilação, save/reopen ou recuperação real**.
- HUD 01 seletivo; preservada a página original de configuração EXO Visual. Tecla I para inventário e rótulo Qi.
- NPC System 02 R1 e R2: diretor, perfil, planner, rotinas, residentes e ponte com roster integrados no host. **Sem teste de rotina ao vivo**.
- Criador de personagem programa mudança para região procedural após criação; interação de retorno à vila legada desativada na aventura. Não apagamos dependências compartilhadas da base/prológo.
- Terreno R1: aplicação seletiva do shader e do decorador com billboards/rochas originais. Preservadas nove texturas aprovadas, colisões planas e pontes sobre rios.
- RIG-01: removida amostragem importada de animação externa aplicada somente ao deslocamento frontal. Substituída por animação procedural que considera a movimentação local nos dois eixos e curva os cotovelos no rig local. **Resultado visual ainda não demonstrado no Godot.**
- Modelo externo de animação `assets/kenney/character-a.glb` e import removidos como inutilizados após a alteração. Arquivos de licença/histórico preservados em `C03_TRANSFERENCIA/proveniencia/`.
- Incluídas fontes completas dos módulos Dungeon R2, Itens R3, Forja Monumental 04, Mestres R2, Bestiário 02, Creature Harmonização 02 e Humanoides R2 sob seus próprios namespaces. **ESTÃO EM STAGING E NÃO REGISTRADOS NO CORE ATIVO**, pois os contratos auditados ainda impedem gameplay seguro. Não instalar PNGs 480 skins herdadas em quarentena.

## Bloqueios e limites de aprovação
- Ainda é necessário executar C01 importação e 23 suítes Cidade Viva R2, C02 Core-P backup/schema/reopen, C03 criação+HUD, C04 24h NPC, C05 terreno e FPS.
- Dungeon × Itens: contrato de transação único pendente. Jamais ativar conceder loot usando verificador que retorna true artificialmente.
- Dungeon: proteção do snapshot, visita/retorno/recovery/host/loot real não integrado.
- Forja: reservas de lotes e transições de interiores não integradas no host.
- Mestres: API narrativa de escrita e treino real pendentes.
- Bestiário: spawn/dano/XP e integração visual não conectados. Arte com proveniência não certificada para venda.
- HUD e RIG-01 exigem inspeção visual. Os testes Python verificam somente código e invariantes estáticos, NÃO execução na Godot.
- Depuração de travamento no voo, missão explorar ruínas, mapa TAB e sistema de armas por categoria continuam pendentes de reprodução ou implementação específica.
- Assets externos sem prova de desuso não foram removidos; a base ainda possui materiais com autoria comercial pendente. Não distribuir comercialmente.

## Correções ainda necessárias ANTES de alegar versão jogável integrada
1. Abrir C03 Alfa num Godot 4.6.2 Standard com Compatibility e testar parser/import/shaders; corrigir erros por classe e registrar logs.
2. Testar fim-a-fim criação → região procedural → inventário I → NPC → combate → saves em diretório de QA.
3. Validar e instrumentar backup Core-P: arquivo inválido não vazio, mesmo ID/diferente seed, schema 1/2, primário corrompido, falha de I/O e reopen.
4. Registrar novos módulos SOMENTE por fases C05–C10 sob os contratos e QA do relatório de auditoria. Não substituir sistemas existentes e não construir autoridades duplicadas.
5. Fazer inspeção visual de oito direções de cotovelo e novas folhas 2D/rochas em pelo menos quatro seeds, além de FPS/frametime no PC real.

**O ZIP é um checkpoint real de código alterado e fontes incluídas, não uma Convergência 03 final.**
