# Contrato de cenário autoral fixo + ocupação dinâmica

## Decisão

A geometria das cidades, ruas, paisagem, casas e interiores principais é **imutável por partida**. Só mudam ocupantes, relações sociais, economia, brasões, patrulhas, agendas e conteúdo narrativo de acordo com combinações autorais válidas.

## Exemplo HWA-02

O `VILLAGE_DYNASTY` é um **slot semântico** ligado fisicamente ao mesmo solar em todas as partidas.

| Campo | Wong | Wudong |
|---|---|---|
| Estandarte | Vermelho terroso + punho original | Azul frio + espada original |
| Comportamento | Austero, exploração e obediência | Justiça, disciplina e prestígio |
| Artes | Qi físico, resistência e impacto | Esgrima, precisão e escola maior |
| NPCs | Patriarca, instrutor, cobrador, discípulos | Líder, espadachins, mediadores, discípulos |
| Missões | Tributação, abusos, resistência, treino físico | Defesa dos humildes, provas de honra, treinos de espada |
| Arquitetura | **Idêntica** | **Idêntica** |

Estas são **variantes demonstrativas** inspiradas no exemplo do usuário e não personagens/narrativas finais. Personagens deverão ser originais, com nomes próprios e biografias revisadas.

## Contrato de save recomendado (NÃO IMPLEMENTADO)

```json
{
  "save_schema": "exo.worldstate.0.1",
  "world_seed": 101,
  "region_id": "HWA-02",
  "content_version": "0.1.0",
  "slot_assignments": {
    "VILLAGE_DYNASTY": "WONG"
  },
  "facts": {
    "dynasty_reputation": 0,
    "river_ferry_open": true
  }
}
```

1. A escolha da dinastia é feita **uma única vez**, ao criar o mundo.
2. O `slot_assignment` fica salvo e sempre prevalece sobre qualquer novo sorteio.
3. Cada slot exige regras de compatibilidade: uma família precisa de NPCs, vínculos, inimigos, técnicas, missões e contratos suficientes para ocupar o local.
4. Uma variante não pode contradizer fatos fixos da Bíblia: por exemplo, Baek e Yeon continuam existindo em Yunseong (HWA-01).
5. O conteúdo variável é uma biblioteca **autoral e dirigida**, não uma geração aleatória irrestrita.
6. O sistema de bandeiras deve ativar **uma única família** e esconder a outra. Ambas as variantes usam a mesma base geométrica.
7. Trocar versão do módulo exige instalação integral e nova validação, nunca pasta antiga + patch novo.

## Próxima fase de implementação

- Catálogo de NPCs, graus marciais, emoções, roupas e técnicas por família.
- Contratos para a economia e a reputação.
- Rotinas persistentes e conflitos evolutivos.
- Comutação entre famílias apenas **na configuração inicial** ou como ferramenta isolada de QA.

**Nenhum desses sistemas dinâmicos está implementado neste pacote.** Apenas a arte alternativa e a regra mínima de seleção para pré-visualização estão implementadas.
