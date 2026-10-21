# EXO-Murim 09.4.1 — Correção de carregamento

## Erro reproduzido por inspeção do código
O Godot acusou `Cannot infer the type of "x" variable because the value doesn't have a set type` em `region.gd:142`. O retorno de `between()` é dinâmico porque `rng` é declarado como `RefCounted`.

## Alterações executadas
- `region.gd`: quatro declarações `var x/z := rng.between(...)` agora têm tipo explícito `float`, incluindo a multiplicação por sinal no perfil de vila próspera.
- `tools/check_094_static.py`: regressão estática para declarações semelhantes em `region.gd`.
- `VERSION.json` e manifesto atualizados.

**Nenhuma regra de seed, distribuição das vilas, comportamento procedural, personalização ou combate foi alterada.**

## Validação
- Concluído: suite estática da 09.4; integridade do ZIP e SHA256; inspeção das quatro atribuições.
- Pendente: parser/importação Godot e execução da cena principal no dispositivo do usuário. Não afirmar execução funcional antes do teste.

## Teste recomendado
Extrair a 09.4.1 em pasta separada e abrir `project.godot`. Verificar se scripts importam e a cena carrega; confirmar os quatro perfis de vilas.
