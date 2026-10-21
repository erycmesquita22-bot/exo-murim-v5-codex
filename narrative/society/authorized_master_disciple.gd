extends RefCounted
# Narrative is the sole owner of master-disciple relationship mutation.
# Called only AFTER EXO Core has authenticated the trusted host proof.
# Pure staged mutation in the SAME JourneySave.data; Core owns durable commit.
const Bonds=preload("res://narrative/society/relationship_system.gd")
static func stage(state: Dictionary,request: Dictionary,at_clock: float) -> Dictionary:
 var action: String=str(request.get("action",""))
 var master: String=str(request.get("master_id",""))
 var disciple: String=str(request.get("disciple_id",""))
 var receipt: String=str(request.get("receipt",""))
 if action not in ["establish","separate"] or master.is_empty() or disciple.is_empty() or master==disciple:return {"ok":false,"reason":"invalid_parties_or_action"}
 if master.length()>128 or disciple.length()>128 or receipt.is_empty() or receipt.length()>120:return {"ok":false,"reason":"invalid_identity_or_receipt"}
 if not state.get("relationships") is Dictionary or not state.get("receipts") is Dictionary:return {"ok":false,"reason":"invalid_narrative_state"}
 var recorded: Variant=state.receipts.get(receipt,null)
 if recorded!=null:
  if recorded is Dictionary and str(recorded.get("master",""))==master and str(recorded.get("disciple",""))==disciple and str(recorded.get("action",""))==action:
   return {"ok":true,"changed":false,"replay":true}
  return {"ok":false,"reason":"receipt_conflict"}
 var key: String=Bonds.pair(master,disciple)
 var prior: Dictionary=state.relationships.get(key,{})
 if action=="establish":
  # An active learner cannot have two masters, including unordered legacy pairs.
  for bond in state.relationships.values():
   if not bond is Dictionary:continue
   if str(bond.get("kind",""))=="master_disciple" and disciple in [str(bond.get("a","")),str(bond.get("b",""))]:
    return {"ok":false,"reason":"disciple_already_bound"}
  if not prior.is_empty():return {"ok":false,"reason":"pair_already_bound"}
  if state.relationships.size()>=2048:return {"ok":false,"reason":"relationship_capacity"}
  state.relationships[key]={"a":master,"b":disciple,"kind":"master_disciple","event":receipt,"clock":at_clock,"master_id":master,"disciple_id":disciple}
 else:
  if prior.is_empty() or str(prior.get("kind",""))!="master_disciple":return {"ok":false,"reason":"no_master_disciple_bond"}
  if str(prior.get("master_id",prior.get("a","")))!=master or str(prior.get("disciple_id",prior.get("b","")))!=disciple:return {"ok":false,"reason":"wrong_bond_direction"}
  state.relationships.erase(key)
 if state.receipts.size()>=12000:return {"ok":false,"reason":"narrative_receipt_capacity"}
 state.receipts[receipt]={"action":action,"master":master,"disciple":disciple}
 return {"ok":true,"changed":true,"receipt":receipt}
