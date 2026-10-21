extends RefCounted
# Não salva coordenadas transitórias. A autoridade é Regional Ecology.
static func key(region: int, territory: String, member: int, generation: int) -> String:
    return "r%02d/%s/m%03d/g%04d" % [region,territory,member,generation]
