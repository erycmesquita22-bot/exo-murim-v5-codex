# EXO-MURIM — Bestiário e Inimigos 03 (candidato modular)

## Base / limites auditados

- Base de leitura: `EXO-MURIM-WORLDGENESIS-V4-CANDIDATO-02-CHECKPOINT.zip` (congelada como fonte de comparação; não alterada).
- Godot de destino: 4.6.2 Standard / Compatibility. Esta entrega é o diretório completo `exo_bestiary/`, **não** uma build jogável.
- Mesmo módulo `bestiary`, agora versão `3.0.0` (substitui conteúdo do 02, não deve ser registrado ao lado de `bestiary` 02).
- Preserva todas as espécies, humanoides, elites, chefes, arquivos JSON, IDs, serviço `bestiary.catalog`, `bestiary.ai`, `bestiary.encounters`, `bestiary.combat`, integração fauna R4 e visual R5.
- **Sem alteração no EXO Core, WorldGenesis V4, NPC02/03, Skill Forge, Cidade, Crowd, inventário, `enemy.gd`, Reward ou saves.** Nenhum outro módulo cria dano/loot/XP neste pacote.

## Mudanças reais de código

1. `v3/group_tactics.gd`: distribui papéis por arma/estilo, sugere posições (sem validar navegação), escolhe líder e limita 1–2 candidatos a ataque por janela de 0,45 s. No máximo oito membros por pedido, como envelope conservador do diretor ecológico auditado; esse valor **não** cria ou reserva NPCs.
2. `v3/combat_brain.gd`: propostas por inimigo com priorização de alcance, esquiva/defesa, recuo, linha de visão, slots e seleção de ataque do catálogo v2. Nunca aplica dano.
3. `v3/skill_bridge.gd`: avalia até 16 IDs fornecidos explicitamente pelo host, consultando `skill_forge.skill` (serviço real R3 1.2.0). Filtra requisitos básicos e retorna `HOST_AUTHORIZATION_REQUIRED`; jamais chama `authorized_cast` ou `legacy_cast`.
4. `v3/animation_timing.gd`: recomenda durações de clips, recuperação, cancelamentos e telegráficos; não altera `AnimationPlayer`, cooldowns reais, hitboxes nem recursos.
5. `module/entrypoint.gd`: novo serviço de leitura `bestiary.tactics` sem retirar endpoints históricos. `module/manifest.json`: versão 3.0.0 e lista de serviços atualizada.
6. `tests/qa_bestiary_v3.gd`: suíte GDScript preparada para Godot real; não chamar de PASS sem execução.

## Endpoints propostos no EXO Core

- `core.services.invoke("bestiary.tactics", "plan_group", [request])`
- `core.services.invoke("bestiary.tactics", "plan_actor", [profile_id, snapshot, order])`
- `core.services.invoke("bestiary.tactics", "skill_suggestions", [profile_id, actor_snapshot, candidate_ids])`
- `core.services.invoke("bestiary.tactics", "timing_preview", [profile_id])`
- `core.services.invoke("bestiary.tactics", "compatibility_status", [])`

`request` do grupo:
```
{
  "group_id": "eco/r07/t01", "region_id": 7,
  "target_position": Vector3(0,0,0),
  "combat_seconds": 0.90, "max_attackers": 2,
  "members": [{
    "uid":"enemy/1", "profile_id":"bandit_swordsman",
    "region_id":7, "position":Vector3(2,0,0),
    "hp_ratio":1.0, "attack_ready":true,
    "target_visible":true, "line_of_sight":true
  }]
}
```

A saída é `PROPOSED`, `committed=false`, `physical_verified=false`, `position_is_navigable=false`. É proibido tratar qualquer campo enviado pelo cliente ou pelo serviço como autorização física. O host de combate deve obter o estado diretamente de atores efetivamente presentes na cena, validar inimigo, HP, território, navegação, ocupação, distância, linha de visão, escudo, esquiva, recurso, cooldown e facção imediatamente antes de aplicar. O diretor ecológico continua responsável por spawn/despawn e os donos existentes por dano, loot e salvamento.

## Matriz V4 real verificada no checkpoint

- **C3 Core**: `register_service(id,owner,provider,methods,version)` suporta nova API. O `exo_core/modules.json` da build precisa ter **uma** entrada de `bestiary`, versão 3.0.0, com `bestiary.tactics` adicionado. Acompanham patch sugerido **NÃO APLICADO** e rollback.
- **Regional Ecology**: orçamento global existente de até oito atores da fauna/inimigos; módulo não acrescenta spawn.
- **Skill Forge R3**: serviço `skill_forge`, endpoint `skill(id)`; 16 técnicas legadas/168 autorais, estas últimas ainda requerem host próprio antes de executar. Apenas metadados consultados aqui.
- **NPC System 03**: serviço `npc03.agenda`, propostas read-only, movimentação e facções pertencem aos donos de NPC; NPC físico hostil nunca é convertido em Crowd.
- **Biblioteca Universal R4**: serviço `content.library` para propostas; sem catálogo sobrescrito, escolha e histórico pertencem ao owner; Bestiário atual consome perfis internos e está preparado para receber IDs validados pelo host.
- **WorldGenesis V4**: seed/IDs de 88 regiões e geometria pertencem ao mundo, posições sugeridas exigem navegação física. O checkpoint WorldGenesis V4 usado aqui não foi alterado.
- **City Forge / Crowd Illusion**: áreas e figuras são metadados; figurantes jamais passam a ser ator real ou ganham dano/loot.
- **Creature Harmonização R5**: `regional_fauna_actor.gd` preservado byte a byte e apresentação não se torna autoridade de ataque.

## Procedimento de instalação apenas pelo integrador (não executado)

1. Congelar ZIP V4 final e save de QA. Confirmar hashes e importar a Godot 4.6.2 em cópia.
2. Comparar `exo_bestiary/` da build final com o conteúdo do pacote, **não sobrescrever atualizações posteriores do Work**. Reconciliar diferenças em arquivos compartilhados antes de copiar.
3. Substituir **somente** `exo_bestiary/` na cópia depois de aprovado o diff. Não manter Bestiário 02 instalado em paralelo.
4. Aplicar as duas alterações em `exo_core/modules.json` usando o patch proposto como referência, não como aplicação cega; preservar campos V4 e ordem atual.
5. Iniciar, conferir `bestiary.tactics` e os quatro serviços originais. Testar sem hook físico; a base precisa permanecer funcional idêntica.
6. O integrador oficial pode consumir propostas em `enemy.gd`/host, **com opt-in**, obedecendo owners. Não ativar combate em grupo efetivo por simples registro do serviço.
7. Godot: `godot --headless --editor --path . --import --rendering-method gl_compatibility --quit`; depois `godot --headless --path . --script res://exo_bestiary/tests/qa_bestiary_v3.gd --rendering-method gl_compatibility`; depois iniciar F5 e testar 1×1/1×4/1×8, grupos mistos, boss/matilha, safe-zones, fuga, save/reload e falha de save.
8. Comparar fps/frame time P95/P99 e memória nas mesmas seeds; confirmar que o host reavalia posições na física, que há no máximo dois ataques simultâneos autorizados e que o ataque de fauna preservou a ponte R4.

## QA e promoção

- QA estático / simulação de políticas realizado neste ambiente e documentado à parte; NÃO substitui execução GDScript/Godot.
- **Godot 4.6.2 NOT_RUN neste ambiente.** Não prometer V4 integrada nem gameplay frenético ativo.
- QA host real, input buffering, ataques autorizados, estado de animações, spawn/dano/loot/save e benchmarks ainda requerem Work ou PC.

## Rollback

Se o teste na cópia falhar, restaurar o diretório `exo_bestiary/` e entrada única do módulo do checkpoint V4 anterior, junto ao save de QA da mesma versão. Nenhum novo domínio persistente é escrito pelo Bestiário 03.
