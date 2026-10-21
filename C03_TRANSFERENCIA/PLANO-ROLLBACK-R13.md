# R13 — Rollback pareado (código + saves)

- R12 original é imutável: ZIP `EXO-MURIM-CONVERGENCIA-03-ALFA-R12.zip` SHA-256 `f785d24d6bde1c29ba74e7a47c9f5aad74b004de5c26991957fee061dbeeb796`.
- R11 serve SOMENTE para comparação histórica, nunca como base de trabalho.
- Novo namespace R13: `EXO-Murim-Convergencia-03-ALFA-R13-QA`. Isolar também `user://` do R12 e do jogo de produção; não misturar domínios de saves.
- Para reverter código: extrair R12 em outra pasta e usar seus próprios snapshots do namespace de QA. Não copiar manualmente dados `exo_core/world_state` versão posterior sobre snapshot anterior.
- Antes de qualquer experimento de reabertura, registrar SHA-256 do save e copiar `.json`, `.bak` e `.tmp` para backup pareado. Guardar o log do commit e o hash do ZIP exato que gerou o save.
