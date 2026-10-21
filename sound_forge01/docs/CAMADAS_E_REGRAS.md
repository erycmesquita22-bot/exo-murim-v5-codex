# Camadas sonoras e disparos

- **DRAW:** somente quando a arma realmente sai da bainha. Não é som de cada golpe.
- **CHARGE:** começa quando o gameplay/animador entra em carregamento.
- **ATTACK / RELEASE:** toca quando o ataque efetivamente é lançado.
- **TRAVEL:** projétil voando; use somente quando existe projétil.
- **HIT:** só em evento confiável de colisão/dano/defesa; se errou, não toca.
- **END:** dissipação ou fim; cuidado para não tocar ao mesmo tempo que impacto e repetir a explosão.
- Em 'sword_qi', ATTACK possui dois efeitos simultâneos (corte físico e descarga energética); os tempos devem ser refinados por marcadores de animação na C3.
- `play_recipe_*` NÃO agenda etapas automaticamente; cada evento é solicitado pelo sistema proprietário no frame correto.
- `play_event_*` aceita token opcional para desduplicar emissões duplicadas de animação e combate. IDs de efeitos permanecem independentes do código do Core.
- Integrações `WorldGenesis`, `CityForge`, NPCs e Multidão Fantasma devem emitir semântica de região/ação; ambientes usam 1–3 zonas espaciais, nunca um player sonoro por figurante.
- O catálogo de MP3 contém 8 tipos de sequência de passos, não 8 bancos de passos individuais. Não os use como footstep one-shot sem edição.
