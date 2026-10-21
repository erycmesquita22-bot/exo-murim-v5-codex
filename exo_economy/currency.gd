extends RefCounted
## The existing Living World bronze balance is the only player monetary authority.
## Ratios are GAMEPLAY rules, not an assertion of fixed historical rates.
const WEN_PER_LIANG: int = 1000
const WEN_PER_GOLD: int = 100000
const MAX_WEN: int = 1000000000

static func valid_amount(value: Variant) -> bool:
    return (value is int or value is float) and is_finite(float(value)) and int(value) == value and value >= 0 and value <= MAX_WEN

static func breakdown(amount: Variant) -> Dictionary:
    if not valid_amount(amount):
        return {"ok": false, "reason": "invalid_amount"}
    var total: int = int(amount)
    var gold: int = total / WEN_PER_GOLD
    var liang: int = (total % WEN_PER_GOLD) / WEN_PER_LIANG
    var wen: int = total % WEN_PER_LIANG
    return {"ok": true, "gold": gold, "liang": liang, "wen": wen, "total_wen": total}

static func combine(gold: int, liang: int, wen: int) -> Dictionary:
    if gold < 0 or liang < 0 or wen < 0 or liang >= 100 or wen >= 1000:
        return {"ok": false, "reason": "noncanonical_denominations"}
    # Bound denominations before multiplying: GDScript int64 arithmetic must not overflow.
    if gold > MAX_WEN / WEN_PER_GOLD:
        return {"ok": false, "reason": "wallet_capacity"}
    var value: int = gold * WEN_PER_GOLD + liang * WEN_PER_LIANG + wen
    if value > MAX_WEN:
        return {"ok": false, "reason": "wallet_capacity"}
    return breakdown(value)

static func label(amount: Variant) -> String:
    var result: Dictionary = breakdown(amount)
    if not result.get("ok", false):
        return "—"
    var names: PackedStringArray = PackedStringArray()
    if result.gold > 0: names.append("%d %s" % [result.gold, str(TranslationServer.translate(&"ECON_CURRENCY_GOLD"))])
    if result.liang > 0: names.append("%d %s" % [result.liang, str(TranslationServer.translate(&"ECON_CURRENCY_LIANG"))])
    if result.wen > 0 or names.is_empty(): names.append("%d %s" % [result.wen, str(TranslationServer.translate(&"ECON_CURRENCY_WEN"))])
    return " + ".join(names)
