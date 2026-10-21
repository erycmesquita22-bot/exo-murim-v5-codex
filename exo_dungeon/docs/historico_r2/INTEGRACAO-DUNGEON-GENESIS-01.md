# Integração controlada — Dungeon Genesis 01

## Base auditada

- Fonte: `EXO-Murim-EXO-Core-01-CANDIDATO-CORRIGIDO.zip`.
- Hash exato: `d6cae1fc95078b9b083755d68ee59c99568801e01fde8c5983366dc4c616f1ac`.
- Contratos verificados: `exo_core/core.gd`, `module_registry.gd`, `service_registry.gd`, `save_coordinator.gd`, `exo_core/modules.json` e template oficial.
- Godot alvo: 4.6.2 Standard, Compatibility.

## Procedimento sob responsabilidade do integrador central

1. Faça **backup** da versão EXO Core oficialmente escolhida. Não cole `project.godot` deste ZIP sobre o `project.godot` do jogo. Este arquivo pertence unicamente ao laboratório standalone.
2. Copie **somente a pasta `exo_dungeon/`** para a raiz do projeto EXO Core e confirme que `res://exo_dungeon/module/entrypoint.gd` existe. O catálogo oficial da Forja permanece onde já está.
3. No `exo_core/modules.json` existente, adicione **um novo objeto** igual ao conteúdo de `exo_dungeon/module/manifest.json`. Não substitua o manifesto central e não duplique os módulos existentes. Isto é uma alteração de **registro** a ser feita pelo integrador, e não é aplicada por este pacote.
4. Confirme ausência de colisões com o serviço `dungeons` e com o domínio `dungeon_genesis`. O registry ordenará a inicialização após `persistence` e `world`.
5. Ao ativar o jogo, o entrypoint receberá `initialize(core)`, registrará `dungeons` e domínio `dungeon_genesis`, schema 1. A raiz do save **continua v4**. Se a inicialização falhar, não force boot desabilitando o validador.
6. World Genesis deve fornecer a **localização externa oficial e persistente**. Não crie nova região do grafo de 88.
7. Quando o jogador acionar a entrada, um coordenador central validado deverá chamar o serviço e fazer materialização sob demanda. O módulo não altera por conta própria `game.gd`, input, HUD, câmera ou posição do jogador.

Exemplo de descritor (dados de teste apenas):

```gdscript
var descriptor := {
 "world_id": "world_saved_id",
 "world_seed": 45712,
 "region_id": 14,
 "location_id": "ruins_14_01",
 "family": "ruins",  # ruins, cavern, temple, sect_hideout, mine, tomb
 "floors": 2,
 "rooms_per_floor": 12,
 "difficulty": 4
}
var plan: Variant = core.services.invoke("dungeons", "visit", [descriptor])
if plan is Dictionary and plan.get("ok", false):
 var dungeon := preload("res://exo_dungeon/runtime/dungeon_instance.gd").new()
 interior_container.add_child(dungeon)
 if dungeon.materialize(plan):
  # IntegradOR: trocar região exterior / controle do jogador segundo Core.
  # Conectar dungeon.transition_requested ao controlador oficial.
  pass
```

O trecho exemplifica a API, **não** é um patch automático para `convergence/game.gd`.

## Escopo dos serviços e persistência

Serviço `dungeons` (métodos públicos permitidos):

- `plan(descriptor)` — cria planta válida; não altera save.
- `visit(descriptor)` — cria/atualiza delta do interior e incrementa visitas; não escreve disco.
- `mark_discovered(dungeon_id, room_id)` — altera delta lógico.
- `is_reward_claimed(dungeon_id, reward_id)` — consulta recibo.
- `confirm_reward_receipt(dungeon_id, reward_id, receipt)` — **somente** confirmação, nunca concessão. Deve ser chamado pelo dono autoritativo de itens na mesma operação transacional; ainda exige integração de transações e testes de falha.
- `snapshot(dungeon_id)` — consulta imutável por cópia.

Os métodos modificam o documento `core.world.journey.data.dungeon_genesis`; o dono central chama o método **já existente** `world.journey.write()` quando apropriado. Nunca chame `_commit_legacy` no módulo e não crie `user://` de save separado.

Não persistir loot determinado, personagens gerados ou resultados não autoritativos só por haver um descritor. Consumir o ID de item oficial do inventário e o recibo oficial antes de permitir reivindicações reais.

## Visual e progressão

`runtime/dungeon_instance.gd` materializa blocos voxel originais para QA com pisos, paredes, corredores e colisão. Os marcadores `Area3D` dos andares **não iniciam transições automaticamente**; o integrador aciona `request_floor_transition(source_room, actor)` na interação explícita, recebe `transition_requested` e move o personagem com o **controlador já existente**, preservando o ponto de retorno para a região externa. `reveal_secret(room_id)` remove lacres físicos depois de um evento de descoberta validado.

A decoração original existente na Forja pode ser acoplada por `dungeon.add_official_forja_decoration()` **somente após importação de todos os GLBs e inspeção visual**. O decorador omite recursos ausentes; não altera o Core nem copia assets de terceiros.

As famílias são identidades semânticas; nenhum perfil inimigo, tesouro, evento histórico ou missão é inventado pelo módulo. Os descritores são encaminhados aos donos corretos mediante contratos oficiais.

## Gates necessários antes de promover a estável

1. Importação nativa Godot sem erros/warnings críticos.
2. Executar `res://exo_dungeon/tests/run_qa.gd` (7.200 tentativas, seis famílias) e `res://exo_dungeon/tests/run_render_smoke.gd`.
3. Testar o `module_registry` com manifesto novo e checar saúde de todos os módulos.
4. Entrada/saída/reentrada com câmera, HUD e jogador EXO reais, colisões, física e FPS.
5. Testar no **processo novo** a recuperação do save v4 após visita, tesouro concedido pelo inventário, derrota do boss e troca de versão; nenhum recibo duplicado.
6. Exercitar falha do save, inventário cheio, perfil inimigo ausente, modo visual desativado e gerenciamento de memória de interiores.
7. Registrar capturas reais na Godot de cinco categorias e métricas reais antes de aprovar conteúdo físico.

**Importante:** não integre definitivamente enquanto os outros módulos estão evoluindo em paralelo; o manifesto foi preparado para posterior inspeção e merge consciente.

## Atualização 0.2.0 — mecânicas de chaves e portões

**A versão do gerador passou para 2.** Não sobrescrever saves de Dungeon Genesis 0.1.0, cujos digests diferem; a entrada rejeita `generator_version_mismatch` até existir migração aprovada. Schema do domínio `dungeon_genesis` permanece 1.

Para entrada/retorno, use o snapshot do save do Core ao materializar:

```gdscript
var plan: Dictionary = core.services.invoke("dungeons", "visit", [descriptor])
if plan.get("ok", false):
 var state: Dictionary = core.services.invoke("dungeons", "snapshot", [plan.id])
 var dungeon = preload("res://exo_dungeon/runtime/dungeon_instance.gd").new()
 interior_container.add_child(dungeon)
 if dungeon.materialize(plan, state):
  dungeon.key_collected.connect(func(key_id: String, room_id: String, actor: Node3D) -> void:
   core.services.invoke("dungeons", "mark_key_collected", [plan.id, key_id])
  )
  dungeon.gate_unlocked.connect(func(gate_id: String, key_id: String, actor: Node3D) -> void:
   core.services.invoke("dungeons", "mark_gate_opened", [plan.id, gate_id])
  )
```

No controlador de interações **existente** do EXO, ao jogador próximo a um marcador de chave, chame `dungeon.collect_key(room_id, key_id, actor)`; próximo a um portão trancado, chame `dungeon.unlock_gate(gate_id, actor)`. Os métodos recusam coleta repetida, abertura repetida, chave ausente e ator afastado. Eles apenas enviam eventos de delta; a integração deve confirmar autorização do ator, aplicar persistência via save coordinator central, administrar falha de escrita e sincronizar estado multiplayer. **Não usar esses métodos para conceder itens.**

A identificação estável de portão é `menor_room_id + "~" + maior_room_id`. O campo `opened` do snapshot guarda portões desbloqueados e `activated` guarda as chaves (`key_*`). Os bloqueadores físicos de `LockedSeal_*` não são gerados se o portão já está aberto. `SecretSeal_*` continua independente da fechadura, exigindo descoberta por mecânica futura.

Execute as três suítes **na Godot 4.6.2** (todas `NOT_RUN` nesta sessão):

```bash
godot --headless --path . --script res://exo_dungeon/tests/run_qa.gd
godot --headless --path . --script res://exo_dungeon/tests/run_mechanics_qa.gd
godot --headless --path . --script res://exo_dungeon/tests/run_render_smoke.gd
```

E o teste de referência em Python, que não substitui o teste de engine:

```bash
python exo_dungeon/tests/stress_reference.py --samples 36000
```

**Critérios de aceite em Godot:** nenhum erro de parser; 7.200 cenários do `run_qa.gd` validados; 144 cenas materializadas no teste de mecânica; nenhuma chave inacessível; lacres físicos presentes antes de abertura e retirados depois; colisões, corpo e câmera EXO testados em jogo; 1% low/FPS medidos em cidade/dungeon real; regressão de Core, inventário, recompensa transacional e saves reabertos.

## Correção R2 de portais (anti-loop)

**Mudança relevante:** tocar/entrar em `Area3D` não solicita transição. O controlador oficial deve, no botão de interação perto de um portal, chamar `dungeon.request_floor_transition(source_room, actor)`; o método exige que o ator esteja fisicamente a até 3 m do ponto de origem e ignora solicitações duplicadas pendentes. Depois de mover o personagem ou de cancelar a operação, chamar `dungeon.acknowledge_floor_transition(actor)` para liberar novos usos. Isso impede a oscilação automática entre pisos ao reaparecer no centro de um portal. O teleporte em si pertence ao controlador oficial.
