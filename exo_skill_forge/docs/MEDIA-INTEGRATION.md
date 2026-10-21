# Vinculação aos recursos EXO Sound Forge 01 e VFX 02

A biblioteca autoral recebeu **associações rastreáveis para 33 eventos de áudio reais** do pacote `EXO-MURIM-SOUND-FORGE-01-AUDIOS-REAIS.zip` e **4 atlas VFX** do pacote `EXO-MURIM-VFX-02-PROTOTIPOS.zip`.

Em `data/media_sources.json`, cada ID tem o arquivo original e SHA-256 verificado a partir dos ZIPs já produzidos. `data/authorial.json` contém as chaves `source_path` ou `source_archive_member` e os respectivos hashes.

### Exemplos de sequência por habilidade

**Fio do Bambu / espada de vento:** preparação `wind.prepare` + `weapon.sword.draw`; lançamento `weapon.sword.swing_light` + `wind.sword.wave`; impacto confirmado `wind.impact.a`; VFX de corte Qi/impacto marcial (atlas de protótipo).

**Ponta do Dragão / lança:** preparação `qi.prepare`; lançamento `weapon.spear.thrust` + `wind.cast.b`; colisão `weapon.spear.hit` + `wind.impact.b`.

**Brasas da Fênix / fogo:** preparação `fire.prepare`; lançamento `fire.cast` + `qi.release`; colisão `fire.impact`.

**Círculo de Jade / defesa:** preparação `qi.meditation.breath` + `qi.prepare`; ativação `qi.barrier.activate`; o som `qi.barrier.hit` deve tocar somente quando o escudo receber dano, não no fim automático do cast.

### Gates de uso

1. Áudios gerados por Runway: nomes, bytes e hashes **existem e foram auditados**, mas apenas `weapon.sword.draw` foi avaliado como amostra aprovada no relatório original. Direitos comerciais dependem da revisão dos termos e aprovação humana individual. **Não foram copiados para este pacote nem ativados automaticamente.**
2. Atlas de VFX são protótipos originais de 24 quadros com 4 famílias, não sprites aprovados nem animação importada na Godot. **Não foram copiados nem ativados.**
3. O atual Sound Forge 01 expõe `has_event()` e `play_event_2d` / `play_event_3d`; o Skill Forge fornece `integration/sound_forge_bridge.gd` para encaminhamento após instalação e aprovação, por meio de `presentation_router.gd`.
4. Áudios com 2–3 s de duração podem ultrapassar janelas de ataque curtas; testar mix, corte, simultaneidade e transição antes de liberar; colisão confirmada deve acionar fase `impact`.
5. A mudança `requires_binding -> asset_verified` por cue **só** deve acontecer após checagem de direitos, asset importado e reprodução testada. O validador exige `resource_path` resolvido, `source_sha256` correspondente aos bytes importados e `commercial_use_verified: true`. Nunca converter todas as chaves em massa sem QA.

### Importante para NPCs

NPCs físicos e inimigos podem compartilhar eventos e atlas, mas execução/áudio devem depender de distância/visibilidade, e o `Sound Forge 01` tem limite próprio de 24 sons simultâneos por instância. Multidão fantasma não toca habilidades nem recebe dano.

## R2 — novos 140 candidatos
Os candidatos `exo.sf.r2.*` criam **3 eventos de áudio** (`prepare`, `release`, `impact`) e 2 de VFX (`release`, `impact`) em estado `requires_binding`. Nenhum OGG/PNG novo foi produzido nesta rodada; os 33 eventos OGG e 4 atlas da R1 continuam documentados, mas não se deve confundir referências antigas com mídias prontas para as 140 novas. O motor de apresentação precisa permitir camadas de lançamento + arma + impacto e priorizar a distância/visibilidade para NPCs; **a ligação real permanece pendente**.
