# Legado audiovisual EXO — auditoria 09.2

Fonte acessível examinada: EXO-Central-e-Identidade-Fontes.zip, versão 13 do
arquivo de fontes. Contém EXO, Visual, Arsenal, Origens, Bosses e Jornada.
Hashes e caminhos das classes examinadas: audio/SOURCE-AUDIT.json.
Não foi redistribuído o pacote inteiro de fontes ou código Forge.

## Catálogo compartilhado

audio/skill_registry.json relaciona todos os 16 IDs reais de data/skills.json
às definições originais, efeitos, eventos do servidor, substituições do cliente,
recursos encontrados e estado de integração. Cada entrada possui preparação,
execução, movimento, impacto e finalização. Fase sem som dedicado tem event null;
isso não é um recurso ausente apresentado como funcional.

audio/skill_registry.gd é o despachante usado por ExoAudio e Techniques. Só a
entrada integrated_original_cc0 substitui playback. As demais estão auditadas
e preservam suas associações 09.1. Seus impactos continuam seguindo material e
contexto em ExoAudio. O catálogo distingue recurso encontrado de recurso integrado.

## Salto Impetuoso — rastreamento e prova

1. SkillSounds.signature identifica salto_impetuoso como ten4. ActiveSkillService
   e SkillCue distinguem execução e impacto após voo/pouso.
2. O evento servidor exomod:skill.ten4.cast/impact aponta inicialmente para
   minecraft:entity.evocation_illager.cast_spell. Esses binários vanilla **não**
   foram copiados para o jogo independente.
3. IdentityAudio, com distinctAudio ativado por padrão, e AudioPolicy substituem
   essa assinatura por exovisual:ten_4_cast/impact. sounds.json do Visual aponta
   para sounds/ten/4_cast.ogg e 4_impact.ogg.
4. TEN-AUDIO-PROVENANCE.json declara os dois derivados CC0. A origem é eco_dash,
   cuja camada spell_fire_03.ogg está identificada como CC0; os créditos do módulo
   apontam ao pacote 80 CC0 RPG SFX de **rubberduck**. A cadeia de hashes de ambos
   os arquivos e do cue intermediário foi conferida.
5. Copiados dois Ogg byte a byte para assets/exo_legacy. Sem síntese nova nem
   alteração das gravações. Registro completo em assets/exo_legacy/ORIGEM.json.
   Ganho runtime 0,65 na saída e 0,55 no pouso, pelo volume de técnicas existente.
6. A saída toca no release do controlador real. O pouso toca uma vez após estado
   aéreo seguido de chão. Removida somente para esse ID a sobreposição dos antigos
   punch/leap/landing genéricos. Contatos com inimigos mantêm os sons de material.

legacy_audio_qa.gd verificou catálogo, hashes, recursos carregados, fases e
quantidade de eventos; procedural_playable.gd repetiu o salto com renderização.
O vídeo inclui áudio efetivamente capturado pela Godot. A medição do vídeo está
no relatório de desempenho; não equivale a aprovação auditiva humana.

## Efeitos visuais examinados

SkillCue organiza fases/origem/direção; ParticleSpawners emite formas e rastros;
CutEchoes e CombatGeometry calculam orientação e geometria de cortes;
TenPresentation diferencia assinaturas; VisualBudget limita efeitos decorativos
e conserva ações primárias. AudioPolicy separa ações de decoração.

No Salto, o original confirma voo antes do impacto e usa rastro/runa/partículas.
A Godot já tinha avanço, confirmação de pouso e anel de impacto. Essa lógica foi
mantida e recebeu somente o despacho de áudio por ID. Não foram portados Java,
texturas, novos rastros ou toda a biblioteca de efeitos. A câmera isométrica e
a aparência aprovada permanecem. O catálogo registra essa distinção.

Diferença preexistente registrada: guardiao_ancestral está no catálogo original
como SUMMON_UNDEAD/trevas; a adaptação Godot usa guardião de terra. A 09.2 não
altera essa identidade sem decisão criativa. Os outros registros apontam os
IDs originais efetivamente encontrados, não inferem equivalência pelo nome.

Créditos CC0: https://opengameart.org/content/80-cc0-rpg-sfx . Os registros
individuais são a base de licença dos dois novos arquivos. Permanecem válidos
LICENCAS-09.md e os termos de todos os recursos herdados.
