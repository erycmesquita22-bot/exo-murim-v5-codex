# EXO Character Refit 01 — dependency audit (22 October 2026)

Baseline: EXO-MURIM-V5-OTIMIZACAO-URBANA-AC-CANDIDATO.zip (immutable).

## Owners

| Domain | Canonical implementation | Refit change | Contract preserved |
| --- | --- | --- | --- |
| Hierarchy and movement | `rig.gd` | Removed permanently generated dummy sword; created Marker3D grip/sheath reference nodes | torso child 0 mesh / child 1 head; pivot/arms/forearms/legs/calves arrays; pose, locomotion, skill_pose |
| Outfit geometry | `wardrobe.gd`, `exo_character_refit01/geometry.gd` | One renderer/batch for each animated joint; previous generated garment nodes removed on every apply | `Wardrobe.apply`, `Wardrobe.piece`, `Wardrobe.animate_cloth`, `garments`, `cloth_motion` |
| Melee/ranged weapons | `arsenal.gd`, `combat/martial_motion.gd` | Canonical forearm weapon parent retained; offset taken from `WeaponGripRight` | `weapon_root`, `carry_roots`, `grip_transform`, `carry_sheath`, projectile and ammo markers |
| Skin import | `exo_skin3d` / `exo_identity.gd` | No change in UV atlas or save schema | Vanilla 64x64/256x256 UV and classic/slim, outer layer, accessories, cosmetics |
| R2 outfit provider | `exo_humanoids03_r2/scripts/actor_visual_adapter.gd` | Physically disables previous generated garment overlay; selection data retained | saved `visual_r2` schema 2; notify_action; cleanup |
| NPCs | `npc_system04/actor.gd` | Refit Wardrobe receives derived visual profile carrying stable ID | real NPC ID, AI, collision, route planner, snapshots |
| Crowd | `exo_crowd_illusion/visuals/real_npc_visual.gd` | Same Refit construction, stable ghost UID | no gameplay ownership, visual actions |
| Player creation | `ui/character_creation.gd`, `ui/portrait_stage.gd` | Existing preview uses Refit's Wardrobe; help text updated | creation profile, race, body, weapons, skins and saves |
| EXO Core | `exo_core` | No changes | all services and owner contracts |

## What was actually removed

- The old `Wardrobe.apply` garment generation is replaced, not appended to.
- The old fake/duplicate sword's meshes are no longer created; only an empty compatibility socket remains.
- The R2 renderer's live mesh creation is disabled; its source remains as a cleanup/migration helper required for older saved selections.
- Existing 64x64 appearance/outer-layer resources are **not removed** because other modules depend on them.

## What is intentionally NOT claimed

No end-to-end Android rendering test, no performance FPS A/B of 50 characters, no Godot 4.6.2 certification, and no exhaustive manual inspection of all race+weapon+pose combinations. Preview and weapon poses may need further artistic tuning after user review.
