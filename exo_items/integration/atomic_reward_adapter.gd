extends RefCounted
# R3. Isolated transaction helper for a future INVENTORY-OWNED Convergencia 03 hook.
# DO NOT call this from the existing gameplay without applying the COMPLETE Core 01-P patch.
# No save files, no new event bus, no global singleton, no activation in entrypoint.gd.
const CoreWorld = preload("res://procedural/world_state.gd")
const Inventory = preload("res://inventory.gd")
const LIMIT = 2147483647

static func _whole(value: Variant, minimum: int=1, maximum: int=LIMIT) -> bool:
 if not (value is int or value is float) or not is_finite(float(value)):
  return false
 return float(value) == float(int(value)) and int(value) >= minimum and int(value) <= maximum

static func _json_safe(v: Variant, depth: int=0) -> bool:
 if depth > 24: return false
 if v == null or v is String or v is StringName or v is bool or v is int: return true
 if v is float: return is_finite(v)
 if v is Array:
  for item in v:
   if not _json_safe(item, depth + 1): return false
  return true
 if v is Dictionary:
  for k in v.keys():
   if (not k is String and not k is StringName) or not _json_safe(v[k], depth + 1): return false
  return true
 return false

static func _uid_id(uid: Variant) -> int:
 if not uid is String or not uid.begins_with("item_"): return -1
 var suffix: String = uid.trim_prefix("item_")
 if not suffix.is_valid_int(): return -1
 var number: int = int(suffix)
 if number < 1 or number > LIMIT or uid != "item_%d" % number: return -1
 return number

static func _receipt(data: Dictionary, id: String) -> Dictionary:
 var w: Dictionary = data.get("world", {})
 if w.get("schema") != 2 or not w.get("claim_receipts") is Dictionary: return {}
 var ledger: Dictionary = w.claim_receipts
 var digest: String = id.sha256_text()
 var shard: Variant = ledger.get("shards", {}).get(digest.substr(0, 2), {})
 if not shard is Dictionary: return {}
 var found: Variant = shard.get(digest, {})
 if not found is Dictionary or found.get("id") != id: return {}
 return found

static func _base_ok(data: Dictionary) -> bool:
 if not data.get("world") is Dictionary: return false
 var w: Dictionary = data.world
 # Core 01-P is mandatory; schema 1 is read-only and never mutated here.
 if w.get("schema") != 2 or not w.get("claim_receipts") is Dictionary: return false
 if not CoreWorld.valid(w): return false
 if not data.get("items") is Array or not data.get("pending_loot") is Array: return false
 if not _whole(data.get("next_item", -1)): return false
 if data.items.size() > Inventory.CAPACITY: return false
 return true

static func _find_pending(data: Dictionary, source: String) -> Dictionary:
 var matching: Dictionary = {}
 for e in data.get("pending_loot", []):
  if not e is Dictionary: return {}
  if str(e.get("source", "")) == source:
   if not matching.is_empty(): return {} # Ambiguous double pending.
   matching = e
 return matching

static func _fingerprint(data: Dictionary, claim_id: String, rewards: Array) -> String:
 # Stable on replay; independent of camera, NodePath and current inventory counter.
 var w: Dictionary = data.world
 var payload: Dictionary = {"version":1,"world_id":w.id,"seed":w.seed,"generation":w.generation_version,"claim":claim_id,"rewards":rewards}
 return JSON.stringify(payload, "", true).sha256_text()

static func prepare_pending(data: Dictionary, source: String) -> Dictionary:
 # Read-only. Neither grants nor reserves items; returns a staged copy and immutable fingerprint.
 if not _base_ok(data): return {"ok":false,"reason":"core01p_required_or_invalid_data"}
 if source.is_empty() or source.length() > 123 or source.contains("\n") or source.contains("\r"):
  return {"ok":false,"reason":"unstable_source"}
 var claim_id: String = "loot/" + source # Preserve official/legacy loot IDs.
 var received: Dictionary = _receipt(data, claim_id)
 if not received.is_empty():
  return {"ok":false,"reason":"already_collected","receipt":received.duplicate(true)}
 var w: Dictionary = data.world
 if not w.events.has(claim_id) or w.events[claim_id].get("status") != "pending":
  return {"ok":false,"reason":"pending_event_absent"}
 var pending: Dictionary = _find_pending(data, source)
 if pending.is_empty() or not pending.get("items") is Array or pending.items.is_empty():
  return {"ok":false,"reason":"pending_drop_missing_or_ambiguous"}
 if not _json_safe(pending): return {"ok":false,"reason":"non_json_or_non_finite"}
 var fingerprint: String = _fingerprint(data, claim_id, pending.items)
 var candidate: Dictionary = data.duplicate(true)
 var items: Array = candidate.items
 var occupied: Dictionary = {}
 for existing in items:
  if not existing is Dictionary or not _json_safe(existing) or not Inventory.valid_item(existing):
   return {"ok":false,"reason":"invalid_existing_item"}
  var key: int = _uid_id(existing.get("uid"))
  if key < 1 or occupied.has(key): return {"ok":false,"reason":"invalid_existing_uid"}
  occupied[key] = true
 var reserved_elsewhere: Dictionary = {}
 var instances_elsewhere: Dictionary = {}
 for drop in data.pending_loot:
  if not drop is Dictionary or not drop.get("items") is Array:
   return {"ok":false,"reason":"bad_pending_drop"}
  if str(drop.get("source", "")) == source: continue
  for other in drop.items:
   if not other is Dictionary: return {"ok":false,"reason":"bad_pending_item"}
   if other.has("instance_id"):
    if not other.instance_id is String or other.instance_id.is_empty() or instances_elsewhere.has(other.instance_id):
     return {"ok":false,"reason":"conflicting_pending_instance"}
    instances_elsewhere[other.instance_id] = true
   if other.has("uid"):
    var uid: int = _uid_id(other.uid)
    if uid < 1 or reserved_elsewhere.has(uid): return {"ok":false,"reason":"conflicting_pending_uid"}
    reserved_elsewhere[uid] = true
 var own_reserved: Dictionary = {}
 var allocated: Array = []
 var cursor: int = int(candidate.next_item)
 for reward in pending.items:
  if not reward is Dictionary or not _json_safe(reward):
   return {"ok":false,"reason":"bad_reward"}
  var qty: Variant = reward.get("qty")
  if not _whole(qty, 1, 99): return {"ok":false,"reason":"invalid_qty"}
  if reward.has("generation"):
   if not Inventory.valid_item(reward) or reward.get("kind") != "weapon" or reward.qty != 1:
    return {"ok":false,"reason":"unsupported_generated_item"}
   if reward.get("mode", "") == "preview_only": return {"ok":false,"reason":"preview_forbidden"}
   if not reward.get("generation") is Dictionary or reward.generation.get("source") != claim_id:
    return {"ok":false,"reason":"generation_source_conflict"}
   var generated_uid: int = _uid_id(reward.get("uid", ""))
   if generated_uid < 1 or generated_uid >= cursor or occupied.has(generated_uid) or reserved_elsewhere.has(generated_uid) or own_reserved.has(generated_uid):
    return {"ok":false,"reason":"generated_uid_conflict"}
   var instance_id: Variant = reward.get("instance_id")
   if not instance_id is String or instance_id != (str(w.id) + "/" + claim_id) or instances_elsewhere.has(instance_id):
    return {"ok":false,"reason":"instance_source_conflict"}
   for other_item in items:
    if other_item.get("instance_id", "") == instance_id:
     return {"ok":false,"reason":"instance_conflict"}
   own_reserved[generated_uid] = true
   occupied[generated_uid] = true
   items.append(reward.duplicate(true))
   allocated.append(reward.uid)
  else:
   # Authoritative legacy inventory.add semantics: merge if entire quantity fits,
   # otherwise allocate one new slot. No split-stack/partial claim proposal.
   if reward.get("kind") not in ["weapon", "manual", "material", "consumable"] or not reward.get("ref") is String:
    return {"ok":false,"reason":"bad_legacy_kind"}
   for key in reward.keys():
    if key not in ["kind", "ref", "qty"]:
     return {"ok":false,"reason":"untrusted_legacy_fields"}
   var combined: bool = false
   if reward.kind in ["material", "consumable"]:
    for existing in items:
     if existing.kind == reward.kind and existing.ref == reward.ref and _whole(existing.qty, 1, 99) and int(existing.qty) + int(qty) <= 99:
      existing.qty = int(existing.qty) + int(qty)
      combined = true
      break
   if not combined:
    while occupied.has(cursor) or reserved_elsewhere.has(cursor) or own_reserved.has(cursor):
     cursor += 1
     if cursor > LIMIT: return {"ok":false,"reason":"uid_exhausted"}
    var item: Dictionary = {"uid":"item_%d" % cursor,"kind":reward.kind,"ref":reward.ref,"qty":int(qty),"rarity":"Comum","affixes":[]}
    if not Inventory.valid_item(item): return {"ok":false,"reason":"unsupported_legacy_item"}
    occupied[cursor] = true
    allocated.append(item.uid)
    items.append(item)
    cursor += 1
  if items.size() > Inventory.CAPACITY:
   return {"ok":false,"reason":"inventory_full","pending_kept":true}
 if cursor > LIMIT: return {"ok":false,"reason":"uid_exhausted"}
 candidate.next_item = cursor
 if not _json_safe(candidate.items): return {"ok":false,"reason":"non_finite_staged_item"}
 return {"ok":true,"claim_id":claim_id,"source":source,"fingerprint":fingerprint,"pending_items":pending.items.duplicate(true),"staged_items":items.duplicate(true),"staged_next_item":cursor,"allocated":allocated.duplicate(),"mode":"all_or_nothing","committed":false}

static func confirm_pending(world: Node3D, source: String, expected_fingerprint: String, domain_stage: Callable=Callable()) -> Dictionary:
 # Central INVENTORY owner must invoke synchronously on the game thread after Core 01-P integration.
 # The optional domain_stage is supplied by Convergencia 03, and may ONLY edit the SAME
 # journey.data in RAM. It must not save or publish irreversible external side effects.
 if world == null or world.get("journey") == null:
  return {"ok":false,"reason":"world_or_journey_unavailable"}
 var journey: Variant = world.get("journey")
 var data: Dictionary = journey.data
 var plan: Dictionary = prepare_pending(data, source)
 if not plan.get("ok", false): return plan
 if expected_fingerprint != plan.fingerprint:
  return {"ok":false,"reason":"stale_or_conflicting_plan"}
 if not world.has_method("save_progress"):
  return {"ok":false,"reason":"official_save_unavailable"}
 var snapshot: Dictionary = data.duplicate(true)
 var next_data: Dictionary = data.duplicate(true)
 next_data.items = plan.staged_items.duplicate(true)
 next_data.next_item = plan.staged_next_item
 var found: bool = false
 for drop in next_data.pending_loot:
  if str(drop.get("source", "")) == source:
   next_data.pending_loot.erase(drop)
   found = true
   break
 if not found: return {"ok":false,"reason":"drop_disappeared"}
 # Contract permits appending metadata into pending before moving it into the permanent ledger.
 var event: Dictionary = next_data.world.events.get(plan.claim_id, {}).duplicate(true)
 event["fingerprint"] = plan.fingerprint
 event["item_uids"] = plan.allocated.duplicate()
 next_data.world.events[plan.claim_id] = event
 if not CoreWorld.mark_collected(next_data.world, plan.claim_id):
  return {"ok":false,"reason":"receipt_rejected"}
 if not _json_safe(next_data): return {"ok":false,"reason":"invalid_staged_save"}
 journey.data = next_data
 if domain_stage.is_valid():
  var stage_result: Variant = domain_stage.call(world, source, plan.pending_items.duplicate(true))
  if not stage_result is bool or not stage_result:
   journey.data = snapshot
   return {"ok":false,"reason":"domain_stage_rejected","pending_kept":true}
 if not world.save_progress():
  journey.data = snapshot
  return {"ok":false,"reason":"save_failed","pending_kept":true}
 return {"ok":true,"committed":true,"claim_id":plan.claim_id,"fingerprint":plan.fingerprint,"allocated":plan.allocated,"atomic_boundary":"journey_save"}

static func abort_pending(data: Dictionary, source: String) -> Dictionary:
 # A read-only cancellation of a staged plan: the original drop remains in pending_loot.
 var result: Dictionary = inspect(data, source)
 if result.get("status") == "pending":
  return {"ok":true,"aborted":true,"pending_kept":true}
 return {"ok":false,"reason":"cannot_abort_persisted_or_invalid_state","inspection":result}

static func inspect(data: Dictionary, source: String) -> Dictionary:
 if not _base_ok(data): return {"status":"core01p_required_or_invalid_data"}
 if source.is_empty() or source.length() > 123: return {"status":"bad_source"}
 var id: String = "loot/" + source
 var receipt: Dictionary = _receipt(data, id)
 var pending: Dictionary = _find_pending(data, source)
 if not receipt.is_empty():
  if not pending.is_empty(): return {"status":"corrupt_collected_with_pending","receipt":receipt.duplicate(true)}
  return {"status":"collected","receipt":receipt.duplicate(true)}
 if not pending.is_empty() and data.world.events.has(id):
  return {"status":"pending","claim_id":id}
 if pending.is_empty() and not data.world.events.has(id): return {"status":"not_found"}
 return {"status":"inconsistent_pending_state"}

static func recover_pending(data: Dictionary, source: String) -> Dictionary:
 # After reopening official JourneySave (including .bak/.tmp recovery), inspect exact
 # persistent receipt. A missing receipt with pending loot is retriable, never silently consumed.
 var state: Dictionary = inspect(data, source)
 if state.status == "collected": return {"ok":true,"action":"already_committed","regrant":false}
 if state.status == "pending":
  var p: Dictionary = prepare_pending(data, source)
  if p.get("ok", false): return {"ok":true,"action":"retry_owner_confirmation","fingerprint":p.fingerprint,"regrant":false}
  return {"ok":true,"action":"keep_pending","reason":p.get("reason","unknown"),"regrant":false}
 return {"ok":false,"action":"quarantine","reason":state.status,"regrant":false}
