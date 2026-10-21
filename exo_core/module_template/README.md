# Template de módulo EXO

Este projeto é um harness isolado de contratos; não simula o jogo. Abra project.godot com Godot 4.6.2 Compatibility. A cena registra um serviço, recebe um evento duas vezes e verifica que o contador persistente avança uma única vez.

Para integrar no jogo, copie `example/` para a raiz, acrescente o manifesto a `exo_core/modules.json` e adapte ID, dependências, serviço e domínio. O Core carrega `entrypoint` e chama `initialize(core)`. Não copie os arquivos de infraestrutura deste harness sobre o Core do jogo. `initialize` registra o domínio; não abre arquivos de save. O coordenador do jogo escreve o documento v4 inteiro. `shutdown` libera referências ao Core. Substitua o contador pelo seu sistema e forneça testes próprios e no jogo completo.
