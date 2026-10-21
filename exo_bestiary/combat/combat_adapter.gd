extends RefCounted
# Ações de ataque DEVEM atravessar o gameplay autoritativo.
# Nunca aplica dano, XP, cooldown, loot ou redução de XP localmente.
var attack_executor: Callable
var statuses: Array[String] = []
func bind_executor(executor: Callable) -> bool:
    if not executor.is_valid():return false
    attack_executor=executor
    return true
func request_attack(actor_uid: String, attack: Dictionary, target_uid: String) -> Dictionary:
    if actor_uid.is_empty() or target_uid.is_empty() or attack.is_empty():return {"status":"BLOCKED","reason":"invalid_request"}
    if not attack_executor.is_valid():return {"status":"BLOCKED","reason":"missing_authoritative_executor"}
    var result: Variant = attack_executor.call(actor_uid,attack.duplicate(true),target_uid)
    if not result is Dictionary:return {"status":"BLOCKED","reason":"invalid_executor_result"}
    if not bool(result.get("accepted",false)):return {"status":"BLOCKED","reason":str(result.get("reason","authoritative_reject"))}
    return {"status":"ACCEPTED","receipt":str(result.get("receipt",""))}
