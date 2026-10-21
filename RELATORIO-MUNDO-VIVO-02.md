# EXO-Murim — Mundo Vivo 02 (candidato técnico)

Base: `EXO-Murim-Convergencia-01.2-Assentamentos-NPCs-03.zip` (Godot 4.6.2 Standard, Compatibility).

**Estado: IMPLEMENTAÇÃO DE FONTE; VALIDAÇÃO GODOT PENDENTE.** O ambiente desta execução não dispõe do executável Godot. Nenhuma captura de jogo ou benchmark de gameplay foi produzida aqui. Não declarar a versão jogável aprovada até executar os testes nativos.

## Implementação

### Mundo e inimigos
- World Genesis permanece dono do relevo, bioma, lotes, portas e portais. `regional_ecology/territories.gd` gera áreas hostis determinísticas *somente* para `wild`, `ruins`, `dungeon_approach`, sem modificar dados de terreno.
- Regras de exclusão: raio mínimo ao centro da região, afastamento de estrada/portais, água e lotes, inclinação e 34m entre territórios. No máximo 3 territórios em áreas selvagens, 4 em ruínas e aproximações de masmorra.
- `regional_ecology/director.gd` materializa sob demanda (17–85m do jogador, fora do frustum, verificando suporte/colisão), até 8 inimigos simultâneos. Acampamentos possuem 1–2 membros e morte parcial persistente.
- `enemy.gd` mantém modo legado; no modo regional faz patrulha, reconhecimento por linha de visão, ataque e retorno ao território sem o limite fixo de coordenada Z do cenário antigo. Inicialmente reutiliza perfis *blade* e *mage*. Chefes legados permanecem preservados.
- Após eliminar todos os membros de um território, ele só renova depois de seis horas do tempo do jogo, fora da visão do jogador. A seed determina local inicial, mas mortes e gerações são persistidas.

### Recompensas
- `regional_ecology/rewards.gd` registra XP regional (banco separado da maestria, atributos e cultivo já aprovados), rank derivado da XP e queda diária de rendimento do mesmo tipo de inimigo na mesma região: 100% até 8, 80% até 16, 55% até 30, 35% depois. O redutor não afeta loot.
- Saque regional: 1–2 materiais ferro garantidos e 20% de chance determinística de arma procedural. ID da morte inclui território, membro e geração, prevenindo repetição do mesmo recibo.
- `journey_save.gd` aceita ID regional em `pending_loot` com limite de 210 entregas pendentes e limites de coordenadas apropriados. `world.events` permanece dentro do seu esquema original; recebimentos ecológicos já coletados são compactados em volumes grandes. Spawn fica pausado com 200 itens pendentes para evitar saturação.
- **XP ainda não altera os pontos/nível do personagem**; para não impor uma segunda progressão incompatível, está guardada e rastreável em `convergence.ecology.xp_total`. Falta conectar este banco ao modelo de progressão aprovado após testes e balanceamento.

### Moradores
- `ai_core/world_clock.gd`: dia de 36 min reais (90s/hora), com migração única da escala horária anterior e pausa normal da simulação.
- `convergence/region.gd` fornece pontos externos de atividade (`@activity`) separados das filas de entrada, reaproveitando rotas de moradia, trabalho e praça.
- `convergence/resident.gd` registra ciclos de trabalho e animações contextuais básicas para plantio, colheita, treino e meditação. Ciclos seguem lógicos quando fora da câmera; não alteram economia/itens.
- **Não incluído:** combate de guardas, trabalhos com produção econômica, famílias, interiores físicos, grandes eventos de facção e integração definitiva do banco de XP ao nível do personagem.

## Testes executados neste ambiente

`QA-MUNDO-VIVO-02-OFFLINE.json`: **16.000 planos de referência**, 44.000 territórios sintéticos, 79.200 eventos de XP, 45.760 IDs de recompensa e 366.768 assertivas offline, sem falhas neste modelo; em geral executadas com superfície artificial plana, estrada `y=0`, rio `x=55`. **Não testam diretamente GDScript, colisão, física, desempenho, saves reais ou importação Godot**.

Passos de QA nativo preparados e não executados:

```bash
godot --headless --editor --import --quit
godot --headless --script res://regional_ecology/qa_massive.gd
godot --headless --script res://convergence/frontage_qa.gd
godot --headless --script res://convergence/routine_qa.gd
godot --headless --script res://convergence/qa.gd
python3 tools/run_convergence012_checks.py /caminho/para/godot
```

Usar também execução com display para investigar visibilidade, movimento, etiquetas e interação real. A QA nativa também é uma amostra determinística/algorítmica; **não substitui testes em cenas físicas**.

## Validação necessária antes de promover

1. Importar sem erros de parser na Godot 4.6.2; resolver todas as falhas de type-check.
2. Criar 3+ regiões selvagens, 3 ruínas e 3 aproximações de masmorra em seeds distintas; comprovar que nenhum inimigo nasce bloqueando portas, rios, portais, dentro do campo visual ou na área segura.
3. Inspecionar patrulha, aquisição de alvo, magia, obstáculos, desengajamento, queda de terreno, perseguição e dano; registrar vídeo/capturas com logs.
4. Testar morte parcial de grupo, sair e entrar, salvar, reabrir em outro processo, completar grupo e esperar 540s de relógio antes de ressurgir. Verificar unicidade de XP e loot.
5. Testar coleta com inventário cheio, 200+ itens pendentes, 1800+ eventos, migração de saves existentes e backup.
6. Testar um dia inteiro de moradores numa aldeia/vila/cidade, trajetória de POI e atividades sem atravessar casas ou ficar preso.
7. Executar regressão do personagem/combate, equipamentos, prólogo, mapa, edifícios, atlas, menus e saves; comparar CPU, memória e tempo de cena com NPCs 03.

## Regra de promoção

**Não promover a versão acima de 'candidata técnica' sem Godot.** O próximo Work deve integrar, executar, identificar erros reais, corrigir e revalidar, devolvendo PASS/FAIL/NOT_RUN e um ZIP validado em engine.
