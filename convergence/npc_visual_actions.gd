extends RefCounted
## Shared visual action poses for real NPCs and Crowd Illusion.
## No gameplay state, physics, events, rewards, NPC IDs or interactions.
static func apply(rig: Node3D, action: String, time: float, variation: int = 0, social: bool = false) -> void:
    if rig == null or not is_instance_valid(rig):
        return
    if social or action == "talk":
        rig.forearms[0].rotation.x =absf( -0.25 + 0.25 * sin(time * 4.0))
    if action in ["treino", "treino_individual"]:
        rig.forearms[0].rotation.x =absf( -0.75 - 0.55 * sin(time * 3.4))
        rig.torso.rotation.y = sin(time * 1.7) * 0.17
    elif action in ["plantio", "colheita", "trabalho", "preparar_banca", "fechar_banca", "atendimento", "preparar_remedios", "administracao", "revisar_registros", "organizar_oficina", "organizar_mercadorias"]:
        rig.forearms[0].rotation.x =absf( -0.52 - 0.35 * sin(time * (2.0 + float(variation) * 0.3)))
        rig.torso.rotation.x = 0.16
    elif action in ["alerta", "observar_risco", "investigar"]:
        rig.forearms[0].rotation.x =absf( -0.7)
        rig.forearms[1].rotation.x =absf( -0.55)
    elif action == "meditacao":
        rig.forearms[0].rotation.x =absf( -0.4)
        rig.torso.rotation.y = sin(time * 0.4) * 0.03
