# EXO-Murim 09.2 — Fundação Procedural e Legado EXO

A atualização usa a 09.1 solicitada como base. Implementa equipamento procedural
no saque real, efeitos nos sistemas de combate e persistência integral. Não há
novo modelo, rig, vila, biome, menu principal ou sistema paralelo de inventário.
O projeto abre na Godot 4.6.2, Compatibility. A entrega é o projeto-fonte.

## Auditoria e pontos de integração

Inventory.add já criava itens com UID, rarity e affixes; drop_for mantinha bolsas
pendentes e collect entregava recompensas fixas. JourneySave já validava saves
v2/v3/v4 e fazia escrita temporária/backup. Catalog e data/weapons.json fornecem
as bases de armas; Cultivation e Techniques fornecem requisitos, aprendizado e
dano. Aproveitados esses pontos, sem substituir controladores.

region.gd mantém sua composição e seed local 6412. world/event_rules.gd mantém
condições declarativas. O encontro existente usava RNG sem vínculo com o mundo;
agora suas tentativas usam um domínio próprio e relógios/contador são salvos.
Não foram adicionados encontros nem alteradas suas recompensas ou condições.

## Geração implementada

Três módulos usados em jogo: procedural/seed_stream.gd, world_state.gd e
loot_generator.gd. Regras e limites em data/loot_rules.json. Não criam nós,
malhas ou materiais para sortear dados. A geração ocorre ao materializar o saque,
nunca no processamento por quadro. Catálogo JSON carregado uma vez.

O mundo tem seed uint31, ID independente, schema 1, generation_version 1 e estado
de eventos. Algoritmo inteiro Park–Miller, multiplicador 48271, módulo 2147483647;
SHA-256 deriva os fluxos de seed/versão/domínio/chave. Domínios separados para
base, raridade, qualidade, afixos, valores e encontro. RNG global de efeitos ou
críticos do combate aprovado não participa do saque persistente.

Cada item salva UID local, instance_id com ID do mundo e chave da origem,
base, raridade, prefixo, sufixo, afinidade e valores finais. Mesma seed, versão e
parâmetros reproduzem propriedades; IDs de instância distinguem mundos.
Não há reconstrução de itens existentes pela seed. Versão desconhecida é
rejeitada e sinalizada; não existe atualização silenciosa dos valores sorteados.
As definições da geração v1 devem ser mantidas em futuras versões ou migradas
explicitamente, sem editar sua semântica e reaproveitar o número de versão.

## Regras jogáveis

Quatro raridades, cinco prefixos e seis sufixos. Comum tem qualidade sem afixo;
Incomum um prefixo; Rara e Épica dois afixos. Pools blade/mage/boss usam armas do
catálogo real. Tipos incompatíveis e grupos repetidos são excluídos. Limites
numéricos, valores e pesos configuráveis estão no JSON e são validados no save.

| Propriedade | Efeito implementado |
|---|---|
| damage_pct | Bônus arredondado ao dano-base; qualidade garante ao menos +1, mostrado no inventário |
| move_pct | Velocidade de caminhar/correr; não acelera esquiva ou investida |
| guard | Reduz dano positivo recebido, mantendo mínimo 1; antes da absorção da barreira |
| mana_regen / stamina_regen | Recuperação por segundo no controlador existente |
| agilidade | Atributo efetivo usado no tempo dos ataques e recarga da esquiva |
| inteligencia | Atributo efetivo usado no multiplicador de técnicas |
| elemental_pct + affinity | Dano das técnicas da afinidade correspondente, inclusive projéteis/campos/invocações |

Equipar ativa os modificadores; R guarda o equipamento e suspende seus bônus
no modo mãos livres. Manoplas equipadas continuam usando item e modificadores.
Sem resistência elemental, efeito especial, valor de venda ou requisito de nível
fictício. Nenhum desses campos é anunciado como implementado.

## Obtenção, transações e persistência

Cada um dos seis inimigos persistentes conserva suas recompensas fixas e dá
um equipamento adicional uma única vez. Tier 1: estrada; tier 2: ruínas;
tier 3: chefe. O item completo é sorteado na derrota e salvo na bolsa pendente.
Recolher move exatamente essa instância. Inventário cheio ou falha na escrita
reverte a transação inteira, inclusive contadores. Evento por source impede
repetir o saque. Inventário continua limitado a 24 espaços.

Raiz do save permanece v4, com extensão world schema 1. Legados sem world
recebem identidade/seed derivadas de seu conteúdo e cópia original .pre092.json.
Itens antigos mantêm atributos-base, UID e quantidade. Saves inválidos não são
sobrescritos por autosave; recuperação de backup ou reinício explícito preserva
os bytes rejeitados em .invalid.json. Validam-se IDs/versões, compatibilidade,
faixas dos atributos e duplicidade de instâncias, inclusive bolsas pendentes.

Os dois fluxos renderizados provaram criação pela tela existente, derrota por
ataque, coleta por E, descrição, botão de equipar, acerto modificado e reabertura
em outro processo. Condições e limites em TESTES-09.2.md.

## Arquivos alterados e novos

| Arquivos | Motivo |
|---|---|
| procedural/*.gd; data/loot_rules.json | RNG, estado e gerador/regras efetivamente usados |
| inventory.gd | Materialização, coleta transacional, nomes e atributos equipados |
| journey_save.gd | Extensão, migração, validação e preservação de inválidos |
| main.gd; combat/player_combat.gd; techniques.gd | Leitura dos modificadores nos sistemas existentes |
| encounters.gd | Fluxo determinístico e relógios/tentativas persistidos |
| murim_flow.gd; pause_ui.gd; ui/character_creation.gd | Seed opcional na confirmação existente |
| ui/pages/inventory.gd; journal.gd | Detalhes/ comparação; seed/ID no diário |
| exo_audio.gd; audio/events.json; audio/skill_registry.* | Despacho por ID e prova do Salto Impetuoso |
| assets/exo_legacy/*; audio/SOURCE-AUDIT.json | Dois Ogg originais CC0, proveniência e auditoria |
| procedural_qa.gd; legacy_audio_qa.gd; procedural_playable.gd; procedural_benchmark.gd | Verificação, demonstração e medição |
| tools/run_checks.py; ruins_martial_qa.gd | Incluir suítes novas; reconhecer assinatura original autorizada |
| project.godot | Nome efetivo 09.2, sem mudar renderer ou diretório de saves |

O botão EQUIPAR foi movido acima da prévia no detalhe existente para continuar
acessível após adicionar os atributos. Não foi reconstruído o menu.
O núcleo das animações e os binários dos recursos anteriores foram preservados;
conferência detalhada em PRESERVACAO-09.2.json. Arquivos de importação derivados
não são tratados como novos recursos artísticos.

A implementação continua local e de um único jogador. IDs e dados separados da
apresentação preparam expansões, mas não constituem autoridade de rede, mundo
infinito, economia, NPCs procedurais ou streaming regional.
