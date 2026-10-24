# Entrega — Vida da Vila 01

## Implementado

- 29 moradores em 15 domicílios HWA-02, com identificação, variação de tamanho/cabelo/rosto/roupa, vida, rotina, persistência por slot e distância de ativação. Ji Wol e os outros quatro IDs anteriores foram preservados.
- Dois locais de cultivo marcial, clipe de meditação sobre rig V4, marca de qi, dois mestres locais que ensinam Qi e se defendem com um pulso.
- Três animais de campo e três feras de mata. Quatro bases com malha, skin, esqueleto e animações importadas; dados de spawn/escala/IA separados por contrato.
- Feras com aviso, avanço, dois golpes, área de impacto sincronizada, reação à esquiva, recuperação e recuo territorial. Espada do jogador atinge áreas reais da fauna.
- Estado da fauna no slot de save e suspensão do módulo fora da vila. Menu e demais módulos mantidos.

## Verificado

- SHA-256 do GLB V4: `fc8af84dc28bd3c5e1a308df7a72efe702558824e924b52ac5d49ea75d11e557`, igual ao aprovado.
- Importação dos quatro glTFs e carregamento do jogo em Godot 4.6.3 Compatibility. Todos os animais têm `Skeleton3D` (38–51 ossos) e clipes esperados. O ZIP completo também foi extraído em diretório limpo, reimportado e iniciado sem erro de script (`qa/village_life/zip_import.log`, `zip_runtime.log`).
- Teste `qa/village_life/test_village_life.gd`: 29 moradores/15 casas, 3 animais/3 feras, clipe de cultivo, dano real do lobo, esquiva sem dano, defesa do mestre e presença de clipes de combo. Resultado em `test_result.json`.
- Capturas reais 1280×800: `cultivation.png`, `field_animals.png`, `murim_beasts.png`. Render via Xorg/Mesa llvmpipe. Verificação de pose do cultivo após correção de altura do quadril.
- 7 FPS observados no renderizador por software durante captura; headless 145 FPS não representa desempenho visual. É necessária medição em PC com GPU.

## Limites

- Godot 4.7.2 não instalado; só 4.6.3 disponível. Android não testado, conforme escopo atualizado.
- As feras têm a qualidade estilizada do asset CC0 escolhido e efeitos de qi; a direção artística definitiva para bestiário futuro ainda precisa ser homologada. O contrato exige validação de ossos/clipes ao substituir modelos.
- Rotinas da vila são horários/percursos leves; não incluem economia ou interações entre NPCs. Feras não têm navegação por malha: evitam a vila pela posição dos spawns e usam retorno por raio territorial. Choques com obstáculos complexos podem exigir navegação futura.
- Um encerramento do teste headless emite aviso do Godot de recurso ainda referenciado; importação e execução não emitem erros de script. O render Xorg acusa ausência de ALSA quando o driver padrão é usado; a captura final usou `--audio-driver Dummy`.
