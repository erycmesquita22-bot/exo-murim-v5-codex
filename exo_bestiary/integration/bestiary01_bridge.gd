extends RefCounted
# Tradução opcional dos IDs do Bestiário 01, sem importar o módulo legado.
const LEGACY_TO_V2: Dictionary = {
    "road_bandit":"bandit_swordsman",
    "border_archer":"bandit_archer",
    "shadow_assassin":"dagger_raider",
    "renegade_disciple":"rival_disciple",
    "sword_master":"hostile_wanderer",
    "qi_cultivator":"aggressive_cultivator",
    "corrupt_monk":"aggressive_cultivator",
    "ruin_guardian":"stone_guardian",
    "grave_caller":"aggressive_cultivator",
    "shadow_wolf":"corrupted_wolf",
    "demon_boar":"boar",
    "wood_spirit":"spirit_deer"
}
static func resolve(old_id: String) -> String:
    return str(LEGACY_TO_V2.get(old_id,old_id))
