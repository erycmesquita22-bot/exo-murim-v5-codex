extends RefCounted
## Trusted host for existing Living World actors. No new actors, wallet, or save.
var world: Node3D
var economy: RefCounted
const Goods = preload("res://exo_economy/trade_goods.gd")
const LABELS = {"iron":"Ferro", "weapon_common":"Espada comum", "healing_tonic":"Poção de cura"}
func initialize(host: Node3D) -> bool:
    world = host
    economy = world.exo_core.instances.get("exo_economy")
    return economy != null and economy.bind_trade_authority(Callable(self,"verify_merchant"), Callable(world.inventory,"stage_economy_trade"))
func verify_merchant(request: Dictionary) -> Dictionary:
    if world.flow.phase != "adventure" or world.changing_region or world.current_region < 0 or world.health <= 0 or world.combat_timer > 0:
        return {}
    var hour: int = posmod(int(floor(float(world.extension().clock) / 90.0)), 24)
    if hour < 7 or hour >= 20 or not world.player.is_on_floor(): return {}
    var id: String = str(request.get("vendor_id", ""))
    var stored: Dictionary = world.journey.data.get("living_world", {}).get("npcs", {}).get(id, {})
    if int(stored.get("region_id", -1)) != world.current_region: return {}
    for actor in world.residents:
        if not is_instance_valid(actor) or str(actor.identity.id) != id: continue
        if actor.sheltered or not actor.is_on_floor() or not actor.position.is_finite() or actor.position.distance_to(world.player.position) > 3.0: return {}
        var ray := PhysicsRayQueryParameters3D.create(world.player.global_position + Vector3.UP, actor.global_position + Vector3.UP, 1|4)
        if not world.get_world_3d().direct_space_state.intersect_ray(ray).is_empty(): return {}
        var function: String = ""
        for lot in world.active_region.data.lots:
            if str(lot.id) == str(stored.get("work_slot", "")): function = str(lot.function)
        var offered: Array = []
        if function == "smithy": offered = ["iron", "weapon_common"]
        elif function == "herbalist" or str(stored.get("role", "")) == "healer": offered = ["healing_tonic"]
        elif str(stored.get("role", "")) == "merchant": offered = ["iron", "healing_tonic", "weapon_common"]
        if offered.is_empty(): return {}
        var stock: Dictionary = {}
        for good in offered: stock[good] = 8 if good == "weapon_common" else 30
        var reputation: int = int(world.journey.data.living_world.get("reputation", {}).get(str(stored.get("faction", "")), 0))
        return {"authorized":true, "vendor_id":id, "region_id":world.current_region, "goods":offered, "initial_stock":stock, "treasury_wen":2000, "reputation_percent":clampi(100-int(reputation/10),90,110)}
    return {}
func handle_interaction(actor: Node3D) -> bool:
    var request: Dictionary = {"vendor_id":str(actor.identity.id), "region_id":world.current_region}
    var proof: Dictionary = verify_merchant(request)
    if proof.is_empty(): return false
    show_shop(str(actor.identity.id), str(actor.identity.display_name))
    return true
func show_shop(vendor_id: String, title: String, notice: String = "") -> void:
    var request: Dictionary = {"vendor_id":vendor_id, "region_id":world.current_region}
    var proof: Dictionary = verify_merchant(request)
    if proof.is_empty():
        world.ui.dialogue(title,"O comerciante não está disponível neste local ou horário.")
        return
    var actions: Array = []
    for good in proof.goods:
        for side in ["buy", "sell"]:
            var intent: Dictionary = request.duplicate(true)
            intent.merge({"good_id":good,"side":side,"quantity":1})
            if side == "sell":
                var uid: String = ""
                for item in world.journey.data.items:
                    if Goods.can_trade(item, Goods.mapping(good)) and str(item.uid) != str(world.journey.data.equipped): uid = str(item.uid); break
                if uid.is_empty(): continue
                intent.item_uid = uid
            var quote: Dictionary = economy.shop_quote(intent)
            if not bool(quote.get("ok", false)): continue
            intent.quote_fingerprint = str(quote.quote_fingerprint)
            intent.receipt = "t_" + (str(Time.get_ticks_usec()) + JSON.stringify(intent)).sha256_text()
            var label: String = ("Comprar " if side == "buy" else "Vender ") + str(LABELS[good]) + " • %d Wen" % int(quote.total_wen)
            actions.append({"label":label,"action":Callable(self,"commit_from_ui").bind(intent, vendor_id, title)})
    var wallet: Dictionary = economy.wallet_snapshot()
    world.ui.dialogue_actions(title, "Saldo: %d Wen\n%s" % [int(wallet.get("total_wen", 0)), notice], actions)
func commit_from_ui(intent: Dictionary, vendor_id: String, title: String) -> void:
    var result: Dictionary = economy.execute_trade(intent)
    var notice: String = "Troca salva." if bool(result.get("ok",false)) else "Troca recusada. Confira saldo, espaço e disponibilidade."
    show_shop(vendor_id, title, notice)
