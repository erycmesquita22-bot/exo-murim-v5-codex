extends RefCounted
static func text(plan: Dictionary,seed_text: String) -> String:
 return "EXO CITY FORGE R3  |  B/N: planta  Q/E: perfil  1-5: atalhos  L: peças  ←/→: seeds  |  C3 NÃO MODIFICADA\n%s  |  %s  |  %s  |  seed %s  |  %d setores / %d estruturas  |  %s"%[str(plan.get("blueprint_id","?")),str(plan.get("settlement_scale","?")),str(plan.get("profile_id","?")),seed_text,plan.get("sectors",[]).size(),plan.get("buildings",[]).size(),str(plan.get("status","invalid"))]
