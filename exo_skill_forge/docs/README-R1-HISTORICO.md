# EXO-MURIM — SKILL FORGE 01

**Módulo candidato independente • Catálogo e composição de técnicas • Godot 4.6.2 Compatibility**

## Base real de auditoria

Pacote lido: `EXO-MURIM-CONVERGENCIA-03-ALFA-R13-1.zip`  
SHA-256: `e958f60ea4c4a1f44ed09ff2c2a24075e85d506d3a19d4ddbf09df9b8a97210a`

Componentes auditados diretamente: `data/skills.json`, `data/slot_rules.gd`, `techniques.gd`, `catalog.gd`, `cultivation.gd`, `exo_martial/data/*`, `exo_martial/module.gd`, `audio/skill_registry.gd`, `exo_audio.gd`, `exo_core/modules.json`, `exo_core/core.gd`, `exo_core/service_registry.gd`, `combat/player_combat.gd`, `enemy.gd`, `ui/pages/skills.gd`.

**Nenhuma alteração no arquivo R13 original é incluída ou presumida.** A instalação é opt-in e destinada primeiro a uma cópia do projeto. O módulo não é um ZIP completo do jogo.

## Conteúdo

- **16 técnicas EXO existentes**, espelhadas, sem alterar seus IDs, custos, animações, desbloqueios, regras de slot ou execução.
- **28 técnicas autorais candidatas**, em `data/authorial.json`; são propostas de design, não técnicas já desbloqueadas no jogo.
- **10 modelos de efeitos** orientados por dados: cortes/linhas, cone, projéteis, área circular, avanço, escudo, cura, campos e canalização.
- **Metadados de compatibilidade** com as 9 escolas, 12 estilos e 16 armas do projeto; filtros por nível, pose, estilo, escola, tipo de ator.
- **Pipeline de áudio e VFX por fase**: preparação, liberação, impacto; cada fase pode ter múltiplas pistas. Foram associados 33 eventos OGG comprovados do Sound Forge 01 e 4 atlas VFX de protótipo (somente referências; direitos, importação e mix pendentes). Placeholders são marcados `requires_binding` e jamais tocados como se fossem arquivos reais.
- **Validador fail-closed**, detector de deriva entre espelhos e Core e limites de custo, alcance, efeitos e instâncias.
- **Serviço EXO Core `skill_forge`** opcional, via manifesto, sem domínio de save nem event bus próprio.
- **Executor de planos declarativos** (`planner.gd`) que descreve ações que o host deverá aplicar; não aplica danos, custos nem cooldowns autonomamente.
- **Conector de disparo legado** que chama o `world.techniques.cast(index)` existente, com verificações de `learned` e `loadout`.
- Ferramentas Python para adicionar técnicas sem escrever GDScript, instalar com bloqueio por contratos e executar QA offline.

## Status exato de funcionamento

| Item | Situação |
|---|---|
| Biblioteca 16+28 e filtros JSON | Implementado / QA Python aprovado |
| Verificação de espelho legado R13 e referências | Implementado / QA Python aprovado |
| Rotas declarativas, formatos, custos e fases | Implementado / QA Python aprovado |
| Conector `techniques.cast()` legado | Código escrito; execução real Godot **não testada** |
| Serviço opcional no EXO Core R13 | Código escrito; boot Godot **não testado** |
| Novas 28 técnicas dentro do gameplay | **Bloqueadas** até host de combate, autorização, UI e progressão oficiais |
| VFX/áudio/animações específicos novos | 33 eventos OGG e 4 atlas localizados por hash; aprovação, importação e binding **pendentes** |
| Uso NPC/inimigos | Metadados + interfaces; IA/agendamento e autoridade do host **pendentes** |
| Save/load de novos unlocks | **Não implementado**, por exigir autorização do Core e migração oficial |
| GDScript Godot 4.6.2 headless | **NOT_RUN** — binário Godot indisponível neste ambiente |

## Instalação segura (NÃO mexe no R13 entregue)

1. Extraia uma **cópia** do projeto R13, mantendo os diretórios originais.
2. Copie a pasta `exo_skill_forge/` para a raiz do projeto, **ou** use a ferramenta:

```bash
python exo_skill_forge/tools/install_preview.py --project /caminho/para/COPIA_EXO --register
```

O instalador rejeita projetos com divergência nos seis contratos R13 auditados e cria `exo_core/modules.json.pre_skill_forge01.bak` antes da única alteração opcional no registro. Não altera `main.gd`, `techniques.gd`, NPCs, assets, UI nem o save.

3. Em uma instalação com Godot disponível, rode:

```bash
godot --headless --path /caminho/para/COPIA_EXO --script res://exo_skill_forge/tests/qa_native.gd
```

O testador nativo **não foi executado aqui**; só depois de import, parser, boot e regressão reais poderá ser marcado PASS. Ative primeiro somente como serviço de catálogo.

## Uso com EXO Core

A entrada JSON a adicionar a `exo_core/modules.json` está em `patches/module_entry.json`. O método `core.services.invoke("skill_forge", "summary")` fornece métricas; `skill(id)` retorna cópia profunda da definição; `query({"weapon_pose":"blade"})` filtra; `plan(id,{"type":"npc", "weapon_pose":"blade", "level":20})` devolve plano puramente declarativo.

Para usar o disparo legado via serviço opcional, `legacy_cast("corte_inicial")` apenas redireciona para a autoridade existente e somente se habilidade aprendida e equipada. Isso **não substitui** os controles do jogador.

`authorized_cast(actor_id, skill_id)` para técnicas novas permanece bloqueado até integrador de confiança ligar callbacks de permissão e execução. Uma configuração incorreta pode causar duplicação de dano ou custos: o contrato está em `exo_skill_forge/docs/CONTRATO-HOST.md` e exige consumo/recarga/efeitos atômicos em um host de combate real.

## Criar uma técnica apenas por dados

Faça uma receita JSON com `name`, `id`, `template`, `style`, `school` opcional, `weapon_pose`, `level`, `damage`, `qi`, `stamina`, `cooldown`, `range` e `status`, conforme `tools/example_recipe.json`, então:

```bash
python exo_skill_forge/tools/add_skill.py --recipe exo_skill_forge/tools/example_recipe.json
```

Isso adiciona a entrada a `data/authorial.json`, com efeitos, fases de áudio e VFX pendentes, e classificação. Não fornece aprendizagem ao jogador nem instancia efeitos inexistentes. A biblioteca pode crescer sem escrever nova classe GDScript por técnica, **desde que** permaneça dentro das 10 famílias de execução. Mecânicas realmente novas precisarão de um novo template e um adaptador host correspondente.

Veja `exo_skill_forge/docs/MEDIA-INTEGRATION.md` para o mapeamento de Sound Forge 01 e VFX 02. Nenhum `.ogg`/PNG de outro módulo foi duplicado neste ZIP.

## QA que já foi executado

`exo_skill_forge/tests/QA-OFFLINE-RESULTS.json` contém resultados auditáveis. 20 testes (Python), **0 falhas**, incluindo 180.000 iterações sintéticas (50 mil filtros, 100 mil recursos/recargas, 30 mil limites de efeitos). Testes sintéticos não garantem FPS, detecção de colisão Godot, animações, som, renderização, NPCs ao vivo nem progressão real.
