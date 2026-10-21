# Rollback

1. Feche a Godot e o jogo. Guarde cópia integral dos saves atuais e backups com identificação da revisão.
2. Extraia a C3 Work original em outra pasta. Confirme SHA-256 `abe7b5736140d91153e0e6f9343ef443d9ca526f78b636361355b2d895cb69f9`.
3. Use saves pareados da C3 anterior ao merge; não mescle apenas scripts antigos com saves já alterados pela V4. Nunca apague saves pessoais para testar.
4. Para desativação temporária da apresentação, use City `mode="legacy_procedural"` e Crowd `enable=false` em uma cópia. Isso não desfaz transações nem migra saves para trás.
5. O diff é relativo à C3 original e inclui binários novos. Aplique em cópia limpa com `git apply --check DIFF-V4-PRE-WORLDGEN-01.patch` e depois `git apply`. Importe a raiz na Godot 4.6.2 e execute o roteiro nativo incluído.

`STAGE1` é checkpoint diagnóstico, não candidato estável. `STAGE2` contém a primeira integração física aprovada. A entrega vigente é `EXO-MURIM-V4-PRE-WORLDGEN-COMPAT-01-CHECKPOINT.zip`. Nenhum destes substitui o ZIP original preservado.

O patch cobre fontes, assets e configurações do projeto; a pasta V4_CHECKPOINT de evidências/relatórios acompanha o ZIP e não integra o patch, evitando referência circular.
