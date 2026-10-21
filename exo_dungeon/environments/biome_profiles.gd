extends RefCounted
## Preferências não autoritativas. World Genesis determina o tipo real do local.
const SUGGESTED := {
 "rocky_highlands":["cavern","mine","temple"],
 "alpine":["temple","cavern","ruins"],
 "mixed_woodland":["ruins","sect_hideout","tomb"],
 "forest":["ruins","sect_hideout","temple"],
 "plains":["tomb","ruins","sect_hideout"],
 "settlement":["sect_hideout","temple","ruins"]
}
static func suggests(biome: String) -> Array:
 return SUGGESTED.get(biome,["ruins","cavern"]).duplicate()
