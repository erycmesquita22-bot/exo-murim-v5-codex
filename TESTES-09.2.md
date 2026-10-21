# Testes executados — EXO-Murim 09.2

## Referência preservada

A base foi extraída de EXO-Murim-09.1-Corpo-Marcial.zip, SHA-256
749baf3e8be37373aef78d63dfdfb81c49cce80304fac6aeb7c07aea69a7bbbe.
martial_qa foi executado na 09.1 antes das alterações: 41 verificações passaram.
Base permanece em ZIP separado. Logs da nova execução em logs-validacao/092;
os logs fora dessa subpasta incluem evidências históricas identificadas.

## Automatizados na engine

As 11 suítes herdadas passaram na 09.2: tests, release_qa, discovery_qa,
fidelity_qa, consolidation_qa, ruins_martial_qa, assets_qa, stabilization_qa,
quality09_qa, martial_qa e war_qa. A expectativa de ruins_martial_qa foi ampliada
somente para reconhecer exo_salto_cast, o novo evento autorizado.

procedural_qa: **47 passaram, 0 falharam**. Exercita 2.000 combinações reais,
quatro raridades, compatibilidade, limites, separação de fluxos, repetição de
seed e variação entre seeds, roundtrip JSON, versão/afixo inválido, save real
09.1, cópia byte a byte da migração, arquivo inválido preservado, derrota real,
saque pendente gravado, coleta, recompensas fixas, capacidade/transação parcial,
equipamento/dano, identidade persistente, duplicidade de instância e modificadores.
Movimento usa entrada/física; agilidade altera duração de ataque; inteligência,
afinidade, defesa e recuperação são verificadas nos sistemas executores.
Guardar por R suspende os bônus sem descartar a arma.

legacy_audio_qa: **8 passaram, 0 falharam**. Dezesseis IDs/cinco fases,
proveniência CC0/hash, recursos carregados, salto real, saída no voo, impacto
após tocar o chão, ausência de eventos genéricos duplicados e demais sons mantidos.

Falhas encontradas durante desenvolvimento foram corrigidas: números inteiros
lidos como float do JSON não passavam em consultas de arrays; sincronização inicial
dos relógios do encontro sobrescrevia estado preparado antes do primeiro tick;
o botão Equipar ficava abaixo da dobra após adicionar as descrições.
Os logs de tentativas com erro não são apresentados como testes aprovados.

## Renderização e fluxo jogável

procedural_playable.gd rodou em dois processos Godot Linux separados, com
renderização Compatibility e áudio de Movie Maker. Primeira sessão: **8/8**;
segunda sessão após encerrar a primeira: **5/5**. Seed 24 escolhida pela tela
de criação, ataque acionado por entrada, derrota do inimigo real, coleta por E,
inventário com nome/raridade/atributos, botão Equipar e acerto mais forte que a
arma-base equivalente. A segunda sessão carregou o mesmo mundo/item/equipamento,
sem repetir saque, e executou o Salto com os dois eventos originais.

Fixtures explícitos: IA suspensa, primeiro salteador estacionário com 1 PV,
alvo reutilizável com 1000 PV para comparar dano. Posição do jogador controlada
entre etapas para abreviar deslocamentos. Nenhuma alteração desses parâmetros
foi feita nos scripts normais de jogo. Não é sessão humana.

playable_validation.gd herdado também rodou com renderização: **14/14**.
Movimento, corrida, salto, esquiva, espada/contato, gelo/Qi, exploração das ruínas
por movimento físico, marcador encerrado, salvamento/recarga e menu único.
O roteiro prepara um estado válido de missão estágio 5 para testar a conclusão.

Capturas: evidencias/092-seed.png, 092-saque.png, 092-inventario-antes.png,
092-equipado.png, 092-dano.png, 092-reaberto.png, 092-salto-voo.png e
092-salto-pouso.png. Conferidas visualmente criação e detalhe do item no menu;
vídeo inclui as duas sessões em sequência, sem simulação textual de resultado.

## Reproduzir

Importar o projeto uma vez com Godot 4.6.2. Depois:

```sh
python tools/run_checks.py /caminho/Godot --prologue
Godot --headless --path . --script procedural_benchmark.gd
Godot --path . --script procedural_playable.gd
Godot --path . --script procedural_playable.gd -- reload
```

Para gravar: acrescente --fixed-fps 30 --write-movie /caminho/demo.avi antes
--script. O roteiro usa saves exclusivos demo092/qa092, separados da jornada
normal. O benchmark equivalente é tools/steady_benchmark.gd. Métricas em
DESEMPENHO-09.2.md. Resultados brutos fazem parte da entrega.

## Limites

Roteiros automatizados não substituem uma sessão de jogabilidade humana.
Não houve teste/exportação Android, aprovação artística nova nem audição estética
humana. A personagem/vila/combate existentes foram preservados dentro do escopo;
nenhuma malha Murim definitiva ou biblioteca audiovisual completa foi anunciada.

## Conferência do pacote

Uma extração nova do ZIP, sem cache .godot, foi importada com Godot 4.6.2.
As 13 suítes foram reexecutadas nessa cópia: todas passaram, sem SCRIPT ERROR,
ERROR ou asserção FAIL. Logs fresh-import/fresh-checks e logs de cada suíte
acompanham o projeto. O ZIP foi conferido por CRC e a base original por SHA-256.
A cena principal também foi aberta com renderização em processo novo, sem
erros de script/engine; o driver llvmpipe apenas informa que não controla VSync.
