# EXO Character Refit 01

Authoritative geometry owner for all new Murim player/NPC visual clothing.

- Maintains legacy `rig.gd` joint contracts (torso child 0 body, child 1 head; arms, forearms, legs, calves).
- Skin import remains 64×64 and outer layer remains compatible.
- Garments are *replaced*, never layered on prior generated clothes; one vertex-colour mesh per articulated joint.
- Retired the dummy sword geometry and previous extra R2 garment overlays; R2 selection data kept.
- Ranged and melee weapons still originate in Arsenal. Right hand has explicit Marker3D socket; default root transform preserved.
- NPC clothing colour & styles chosen deterministically from stable ID, without changing NPC AI or save schema.
- All original arts and geometry are authored with Godot primitive mesh code; no third-party models copied.

## QA needed
Character creation preview for all races and body scales; weapon poses by category; NPC spawn, save and restore; animation after roll; skin 64x64 outer layers; Android Compatibility FPS.
