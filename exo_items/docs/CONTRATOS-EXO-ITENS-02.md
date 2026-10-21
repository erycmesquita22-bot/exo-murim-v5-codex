# Contratos de propriedade — EXO Itens Procedurais 02

- `inventory.gd`: proprietário de `items`/`pending_loot`/`equipped`, 24 slots e UID `item_N`.
- `procedural/loot_generator.gd`: proprietário das **regras atuais equipáveis**, estatísticas e dano legado.
- `exo_core/persistence/save_coordinator.gd` e `journey_save.gd`: autoridade única do save; schema raiz v4.
- `exo_items/`: proprietário apenas da descrição/sorteio V2, geração compatível via delegação, validação prévia e exposição de serviço.
- `Regional Ecology`/`Bestiário`/`Dungeon`/`Jornada`: donos de mortes, oportunidades e recompensas, devendo solicitar itens e decidir quando conceder.
- `Mestres`/`EXO Visual`/`Economia`: podem consultar descritores, não são importados nem chamados por este módulo.

## Contrato de retorno `prepare_reward`

Sucesso: `{"ok":true,"item":{...schema 1 legado...},"committed":false,"requires_owner_transaction":true}`.

Falha: `{"ok":false,"reason":"world_absent|uid_absent|incompatible_or_repeated|inventory_full_or_duplicate"}`.

O UID deve vir do `next_item` **lido no momento da transação**, a origem precisa ser única, e o dono oficial deverá salvar o item/pending/evento de forma atômica. Não chamar `prepare_reward` como se concedesse algo; jamais publicar `item_collected` a partir deste módulo.

## Contrato de retorno `preview_item`

`{"schema":2,"mode":"preview_only","id":"exo2/<hash>","seed":N,"source":"...","family":"...","base_id":"...","material_id":"...","rarity_id":"...","level":N,"quality":N,"tier":N,"request_rarity":"...","request_material":"...","affixes":[...],"stats":{...},"title":"...","origin":"procedural_preview","rules_version":2}`.

**Não** inserir em `world.journey.data.items`, `pending_loot` ou `equipped`. Isso seria inválido sob o contrato atual. O serializador de previews é laboratório isolado, não cria um arquivo `user://` do jogo.

## Notas de segurança e propriedade intelectual

As tabelas `legacy_reference.json` são uma reprodução interna auditável das regras próprias já fornecidas pelo EXO Core do usuário. Os seis novos afixos são criação específica deste módulo; nenhum modelo, fonte, som ou textura de terceiros foi incluído. O emissor de aparência retorna apenas descritores e a referência aos recursos já presentes. Qualquer recurso futuro deve ter proveniência e direitos comerciais documentados.
