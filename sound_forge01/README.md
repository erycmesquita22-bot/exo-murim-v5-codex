# EXO-MURIM — SOUND FORGE 01 (AUDIO REAL)

**91 arquivos MP3 reais e 91 arquivos OGG convertidos.** Aprovado pelo usuário: somente a amostra `weapon.sword.draw`. Todos os demais aguardam avaliação auditiva. Os arquivos são gerados por Runway; confirmar o contrato/termos vigentes do serviço e registrar a proveniência comercial do jogo.

## Diretórios
- `audio/`: versões OGG Vorbis para Godot (44.1 kHz; libvorbis qualidade 4, sem aumento de volume, com atenuação conservadora somente para picos altos).
- `originals_mp3/`: todos os 91 MP3 originais, preservados bit a bit.
- `config/events.json`: IDs de eventos estáveis, caminhos, hash SHA-256, mix inicial e origens Runway.
- `config/recipes.json`: receitas por ESTÁGIO (preparar, atacar, lançar, viagem, colidir e finalizar), nunca duração automática da habilidade.
- `config/legacy_aliases.json`: sugestões de mapeamento para eventos antigos; valores null exigem substituir conteúdo inadequado. NÃO carregar automaticamente.
- `runtime/`: nó opcional Godot 4 para reproduzir por evento ou estágio sem modificar EXO Core.
- `qa/`: relatório de verificação do ZIP, hashes, volume, duração e conversões.
- `preview/index.html`: abra no navegador depois de descompactar para escutar individualmente os MP3.

## Instalação segura
Extraia a pasta `sound_forge01` para a raiz do projeto Godot, resultando em `res://sound_forge01/`. **Não sobrescreva** `game.gd`, `project.godot`, EXO Core, manifests existentes, nem remova áudio legado antes de QA. Adicione o nó `runtime/exo_sound_forge01.gd` como um filho de algum gerenciador ou instancie por código. Seus métodos de reprodução são voluntários. Se o EXO Core expuser registry/event bus, adapte por contrato inspecionado na C3; o código entregue NÃO adivinha APIs do Core.

Exemplos (GDScript 4):
```gdscript
@onready var sfx: Node = $EXOSoundForge01
sfx.play_event_2d("weapon.sword.draw") # Só quando arma for realmente sacada
sfx.play_recipe_2d("wind_projectile", "release") # No frame de lançamento
sfx.play_recipe_3d("wind_projectile", "hit", get_tree().current_scene, collision_world_pos) # Só com colisão comprovada
sfx.play_recipe_2d("basic_sword_attack", "attack")
```

**Atenção:** `foot.*` são gravações com múltiplos passos, não sons isolados para cada marcador de animação. Devem ser usados como camas de movimento até serem recortados/regravados e aprovados. `ambient.*` são camas de curta duração (8–10 s) que podem repetir mecanicamente; use zona, crossfade e audição antes de publicar.

## Estado real de verificação
- 91 de 91 nomes reconhecidos; arquivo ZIP original passou no CRC.
- 91 MP3 decodificaram e 91 OGG gerados e decodificados.
- Verificados codec, sample rate, duração, picos, silêncio aproximado, hashes e receitas.
- Sem duplicações exatas de bytes MP3. Sem validação perceptual de derivações ou semelhanças.
- Não houve execução de Godot nesta sessão porque o executável não está disponível no ambiente. Integração C3 e Android não homologadas.
- QA artística individual, loop sem costura, início do impacto, alinhamento com hitbox/animações e direitos comerciais precisam ser aprovados antes do uso final.
