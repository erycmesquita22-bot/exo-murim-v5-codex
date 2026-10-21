# EXO Skill Forge 01 — Relatório da rodada R2

**Data:** 20/10/2026  
**Base:** Skill Forge R1, inspirado no snapshot da Convergência 03 Alfa R13.  
**Escopo:** expansão autoral e QA, sem substituir ou mesclar EXO Core.

## Inventário

- 16 técnicas legadas preservadas.
- 28 técnicas candidatas da R1 preservadas byte a byte na estrutura JSON (conteúdo original idêntico).
- 140 técnicas novas candidatas: 20 corpo, 20 armas, 20 Qi, 20 sangue, 20 demoníacas, 20 celestiais, 20 mundanas.
- Cada uma das 7 famílias: 5 de anime, 5 de manhwa, 5 de lendas, 5 de cinema.
- 184 no catálogo total (168 autorais ainda dependem do host para ativação).
- 16 armas da R13 atendidas no conjunto; não inventados equipamentos ou IDs de escola.
- 10 templates já existentes mantidos, com utilização de 8 na R2. `projectile` é obrigatório para arcos/bestas.
- Algoritmo com seed reproduzível, vocabulário/nome curado e limites seguros de variabilidade numérica; 40 seeds amostradas em QA sem colisão de ID.

## Exemplos (tier 3 de cada origem)

| Família | Linguagem | Técnica | Arma | Custo Qi |
|---|---|---|---|---:|
| corpo | anime | Cotovelo da Estrela Cadente | `gauntlets` | 0 |
| corpo | manhwa | Guarda do Rio Silencioso | `gauntlets` | 0 |
| corpo | lendas | Punho do Trovão Seco | `gauntlets` | 0 |
| corpo | cinema | Cotovelada da Porta Estreita | `gauntlets` | 0 |
| armas | anime | Flecha do Rastro Carmesim | `bow` | 9 |
| armas | manhwa | Lança da Dívida Marcial | `spear` | 7 |
| armas | lendas | Dardo do Corvo Lunar | `crossbow` | 9 |
| armas | cinema | Haste do Portão Final | `arcane_staff` | 7 |
| qi | anime | Raio do Núcleo Sereno | `arcane_staff` | 25 |
| qi | manhwa | Pulso do Dantian Velado | `quarterstaff` | 22 |
| qi | lendas | Orvalho da Flor Imortal | `wand` | 25 |
| qi | cinema | Pulso da Lâmpada Vazia | `arcane_staff` | 22 |
| sangue | anime | Dardo da Veia Silenciosa | `dagger` | 17 |
| sangue | manhwa | Selo da Linhagem Velada | `scythe` | 15 |
| sangue | lendas | Ritual da Rosa Rubra | `scythe` | 17 |
| sangue | cinema | Dardo da Névoa Rubra | `dagger` | 15 |
| demonica | anime | Espiral do Vazio Faminto | `halberd` | 26 |
| demonica | manhwa | Corte da Herança Profana | `arcane_staff` | 22 |
| demonica | lendas | Fogo da Montanha Oca | `scythe` | 26 |
| demonica | cinema | Rugido do Sino Partido | `greatsword` | 22 |
| celestial | anime | Lança da Órbita Dourada | `spear` | 26 |
| celestial | manhwa | Corte do Discípulo Ascendido | `sword` | 22 |
| celestial | lendas | Sopro do Dragão da Manhã | `arcane_staff` | 26 |
| celestial | cinema | Pulso da Manhã Branca | `arcane_staff` | 22 |
| mundana | anime | Arremesso do Olho Firme | `bow` | 0 |
| mundana | manhwa | Lança do Guarda de Vila | `spear` | 0 |
| mundana | lendas | Ponta do Carpinteiro | `spear` | 0 |
| mundana | cinema | Tiro do Muro Baixo | `crossbow` | 0 |

## Funcionamento real versus proposta

**Pronto em dados/QA offline:** catálogo curado, filtros, tags, custos, recarga, efeitos suportados, poses/IDs de armas, fases de áudio/VFX bloqueadas, documentação e geração determinística a partir de seed. A interpretação `media=requires_binding` evita apontar para arquivos de som ou VFX inexistentes.

**Ainda não implementado no gameplay:** dano autoral, colisão Godot, animação real, audiovisual autoral das novas 140, desbloqueio de técnicas por escola e cultivo, sinergias de combo concretas, escala de bosses, sacrifício de HP, roubo de vida, transformações demoníacas/celestiais e execução autônoma de NPCs. O serviço continua fail-closed e depende do host autorizado. `rank_tier` é apenas gradação inicial de design, não progressão oficial.

## Testes executados

- `qa_offline.py`: **20/20 PASS**, 180.000 iterações.
- `qa_r2_expansion.py`: **19/19 PASS**, 549.998 iterações de consulta, recuperação de Qi/Vigor e janelas de alcance; 40 seeds sem colisões.
- `qa_install_r2.py`: **4/4 PASS**, espelho mínimo dos 6 contratos da R13 (instalação não registrada, com registro e backup, rejeição de reinstalação, rejeição por hash modificado).
- Total: **43/43 PASS**, **729.998 iterações sintéticas**; não representam 729.998 golpes em Godot.
- **Godot 4.6.2 e gameplay real: NOT_RUN** (executável Godot indisponível).
- O instalador permanece estritamente ancorado à R13: para C3/R14, remapear contratos antes da integração; nunca forçar cópia em projeto divergente.

## Balanço e riscos pendentes

Os números de dano, Qi, alcance, tempos e stamina são **valores iniciais**, ajustados por patamar 1..5 com pequena variação reprodutível. O teto de dano/alcance aplicado é um limite de segurança de dados, não um limite competitivo. Não há dados suficientes para declarar tempo até cultivo, DPS efetivo ou impacto em FPS. Testar cenários de jogador iniciante, mestre, multidões físicas, PvE e combate contra chefe depois da integração, sempre com perfis de aparelho.

## Fontes de inspiração e propriedade intelectual

A linguagem se inspira em convenções abertas de wuxia/xianxia, artes marciais fantásticas em anime e manhwa, mitos genéricos e coreografia de cinema. **Não foram importadas técnicas protegidas, cenas, falas, personagens, nomes próprios de franquias nem mídia de terceiros.** Motivos como criaturas mitológicas ou passos leves são referências culturais, não tradução/cópia de uma habilidade específica.

**Entrada para a próxima etapa:** ZIP R2 independente e candidato; validar Godot/contratos C3 antes de qualquer merge ou ativação dos 140 novos candidatos.
