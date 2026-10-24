# Personalização de personagem 01

`appearance.gd` aplica um perfil no rig V4 **instanciado** sem editar o GLB ou a textura aprovada do player. `catalog.json` lista cinco variantes faciais mais o original, cinco composições de cabelo, quatro canais de roupa e limites de proporção. `build_faces.py` gera de modo determinístico os PNGs faciais a partir do atlas V4. Os PNGs acompanham o módulo; Blender e Python não são necessários para rodar o jogo.

Formato de perfil:

```json
{"face":"river_worker","hair":{"style":"cropped","color":"#574739"},"apparel":{"outer":"#a88c67","tunic":"#c3ad88","sash":"#81684d","trousers":"#5f6660"},"body_style":{"width":1.07,"height":1.04,"depth":1.04}}
```

`APPEARANCE.apply_to_visual(rig, profile)` muda apenas materiais de instância e visibilidade/escala das peças originais. `APPEARANCE.proportions(profile)` devolve a escala limitada para adaptar cápsula, hurtbox e etiqueta. O NPC ator é um exemplo operacional dessa integração. Para outro personagem, a cena que o hospeda deve atualizar sua colisão e altura de câmera também.

As imagens faciais variam tons de pele, íris, franja desenhada, marcas discretas e boca. A topologia e as UVs são as originais. Os penteados usam combinações da franja pintada, rabo de cavalo e mechas já presentes no GLB; não são cortes esculpidos novos. As roupas alteram as cores das peças existentes, não o corte geométrico. A escala corporal é propositalmente contida para manter animações e contato com o chão. Não há editor de personagem, troca de sexo corporal, novas cabeças modeladas ou roupa com silhueta inteiramente nova nesta fase.
