extends RefCounted
# Dois fluxos isolados: visual NÃO altera decisões de gameplay.
static func stable_hash(value: String) -> int:
    var h: int = 2166136261
    for b in value.to_utf8_buffer():
        h = (h ^ int(b)) * 16777619
        h = h & 0xFFFFFFFF
    return h
static func variant_for(profile: Dictionary, seed: int, uid: String) -> Dictionary:
    if uid.is_empty() or str(profile.get("id", "")).is_empty(): return {}
    var gameplay := RandomNumberGenerator.new()
    gameplay.seed = stable_hash("EXO/BEAST/2/G/%d/%s/%s" % [seed,uid,str(profile.id)])
    var cosmetic := RandomNumberGenerator.new()
    cosmetic.seed = stable_hash("EXO/BEAST/2/V/%d/%s/%s" % [seed,uid,str(profile.id)])
    return {"uid":uid,"species_id":str(profile.id),"aggression":snappedf(gameplay.randf_range(0.85,1.15),0.01),"caution":snappedf(gameplay.randf_range(0.85,1.15),0.01),"skill":gameplay.randi_range(0,3),"scale":snappedf(cosmetic.randf_range(0.88,1.12),0.01),"palette":cosmetic.randi_range(0,3)}
static func gameplay_signature(variant: Dictionary) -> Array:
    return [variant.get("aggression"),variant.get("caution"),variant.get("skill")]
