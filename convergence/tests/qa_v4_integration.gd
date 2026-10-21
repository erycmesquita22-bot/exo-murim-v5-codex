extends SceneTree
const Game=preload("res://convergence/game.gd")
var w: Node3D
var failures: Array=[]
var checks: int=0
func check(ok: bool, label: String) -> void:
 checks+=1;print("V4_CHECK ",label," ",ok)
 if not ok:failures.append(label)
func _initialize():call_deferred("run")
func run():
 Engine.max_fps=0
 var reopen: bool="--reopen" in OS.get_cmdline_user_args()
 w=Game.new();w.load_on_start=reopen;w.save_path="user://v4_integration.json";w.settings_path="user://v4_integration.cfg";root.add_child(w)
 await process_frame
 check(w.exo_core.ready,"core_boot")
 for id in ["city_forge.plans","crowd.illusion","content.library","economy","skill_forge","npc03.agenda","interior_forge.candidates","exo_vfx_forge"]:check(w.exo_core.services.has_service(id),"service_"+id)
 if not w.exo_core.ready:quit(1);return
 if not reopen:
  w.flow.phase="creator"
  var profile:Dictionary={"name":"V4 QA","race":0,"path":0,"robe":1,"hair":0,"skin":0,"style":0,"weapon":"sword","outfit":0}
  check(w.flow.create_character(profile,101),"creator_seed101")
 for frame in range(1800):
  await physics_frame
  if w.current_region>=0 and not w.changing_region:break
 if not reopen:check(await w.change_region(78),"city78")
 w.ui.resume();w.simulation_enabled=true
 for i in range(20):await physics_frame
 w.simulation_enabled=false
 var library:Dictionary=w.exo_core.services.invoke("content.library","catalog_status")
 print("V4_LIBRARY ",JSON.stringify(library))
 check(int(library.get("records",0))==1228 and int(library.get("domains",0))==76,"library_r4_1228_76")
 check(str(w.journey.data.exo_economy.seed)=="101","economy_creator_seed_survives")
 check(w.exo_core.services.invoke("exo_vfx_forge","receive_authorized_cue",[{}]).get("status")=="BLOCKED","vfx_untrusted_blocked")
 check(w.exo_core.services.invoke("skill_forge","compatibility_status").get("generic_host_bound",false),"trusted_skill_host_bound")
 check(int(w.exo_core.services.invoke("crowd.illusion","status").get("ghosts",0))>0,"crowd_physically_attached")
 print("V4_CITY ",JSON.stringify(w.active_region.data.settlement_plan.get("city_forge_r4",{})))
 print("V4_CROWD_GEOMETRY ",JSON.stringify(w.active_region.get_meta("v4_crowd_check",{})))
 print("V4_CROWD_ATTACH ",JSON.stringify(w.active_region.get_meta("v4_crowd_attach",{})))
 print("V4_CROWD_STATUS ",JSON.stringify(w.exo_core.services.invoke("crowd.illusion","status")))
 if reopen:check(w.journey.data.exo_economy.receipts.size()>=3,"trade_receipts_reopen")
 # QA fixture funding ONLY: no startup currency is added to gameplay.
 if not reopen:w.journey.data.living_world.balances.bronze=10000
 var vendor: Node3D=null
 for actor in w.residents:
  var at: Vector3=actor.position+Vector3(1.6,0,0)
  var safe:Vector3=w.regional_spawn(w.active_region,at)
  if not safe.is_finite():continue
  w.player.position=safe;w.player.velocity=Vector3.ZERO
  await physics_frame;w.player.move_and_slide();await physics_frame
  var proof:Dictionary=w.economy_host_v4.verify_merchant({"vendor_id":str(actor.identity.id),"region_id":78})
  if not proof.is_empty():vendor=actor;break
 check(vendor!=null,"physical_existing_merchant")
 if vendor!=null:
  var id:String=str(vendor.identity.id)
  print("V4_VENDOR ",id," ",vendor.position)
  check(w.economy_host_v4.handle_interaction(vendor),"physical_merchant_ui")
  w.ui.resume()
  var econ:RefCounted=w.exo_core.instances.exo_economy
  var proof:Dictionary=w.economy_host_v4.verify_merchant({"vendor_id":id,"region_id":78})
  var good:String=str(proof.goods[0])
  var request:Dictionary={"vendor_id":id,"region_id":78,"good_id":good,"quantity":1,"side":"buy"}
  var quote:Dictionary=econ.shop_quote(request)
  check(quote.get("ok",false),"real_shop_quote")
  if quote.get("ok",false):
   var intent:Dictionary=request.duplicate(true);intent.quote_fingerprint=quote.quote_fingerprint;intent.receipt="qa_"+str(Time.get_ticks_usec())
   var before_coins:Variant=w.journey.data.coins
   var first:Dictionary=econ.execute_trade(intent);print("V4_TRADE ",first)
   check(first.get("committed",false),"buy_atomic")
   var after:Dictionary=w.journey.data.duplicate(true)
   check(econ.execute_trade(intent).get("duplicate",false) and w.journey.data==after,"duplicate_exactly_once")
   var stale:Dictionary=intent.duplicate(true);stale.receipt+="_stale"
   check(not econ.execute_trade(stale).get("ok",false) and w.journey.data==after,"stale_quote_rollback")
   quote=econ.shop_quote(request);intent.quote_fingerprint=quote.quote_fingerprint;intent.receipt+="_second"
   check(econ.execute_trade(intent).get("committed",false),"second_trade_existing_shop")
   # Save failure cannot mutate stock, money, inventory, receipts, or disk.
   quote=econ.shop_quote(request);intent.quote_fingerprint=quote.quote_fingerprint;intent.receipt+="_fail"
   var before:Dictionary=w.journey.data.duplicate(true);var path:String=w.journey.path
   var disk:String=FileAccess.get_file_as_string(path)
   w.journey.path="user://missing_v4_parent/fail.json"
   check(not econ.execute_trade(intent).get("ok",false) and before==w.journey.data,"trade_save_failure_rollback")
   w.journey.path=path;check(disk==FileAccess.get_file_as_string(path),"trade_save_failure_disk")
   # No funds.
   w.journey.data.living_world.balances.bronze=0;before=w.journey.data.duplicate(true)
   check(not econ.execute_trade(intent).get("ok",false) and before==w.journey.data,"insufficient_funds_rollback")
   w.journey.data.living_world.balances.bronze=10000
   # Capacity 24/24 without mergeable stacks.
   var real_items:Array=w.journey.data.items.duplicate(true);var next:Variant=w.journey.data.next_item;var real_equipped:String=str(w.journey.data.equipped)
   w.journey.data.items=[];w.journey.data.equipped="item_1000"
   for n in range(24):w.journey.data.items.append({"uid":"item_%d"%(1000+n),"kind":"weapon","ref":"sword","qty":1,"rarity":"Comum","affixes":[]})
   w.journey.data.next_item=1024;before=w.journey.data.duplicate(true)
   check(w.journey.valid(w.journey.data),"inventory24_fixture_valid")
   check(not econ.execute_trade(intent).get("ok",false) and before==w.journey.data,"inventory24_rollback")
   w.journey.data.items=real_items;w.journey.data.next_item=next;w.journey.data.equipped=real_equipped
   # A further valid commit after failed writes proves transaction lock released.
   quote=econ.shop_quote(request);intent.quote_fingerprint=quote.quote_fingerprint;intent.receipt+="_recover"
   check(econ.execute_trade(intent).get("committed",false),"trade_after_failure")
   # Sell only a concrete supported, unequipped item UID.
   var selling:Dictionary=request.duplicate(true);selling.side="sell"
   for item in w.journey.data.items:
    if preload("res://exo_economy/trade_goods.gd").can_trade(item,preload("res://exo_economy/trade_goods.gd").mapping(good)) and str(item.uid)!=str(w.journey.data.equipped):selling.item_uid=str(item.uid);break
   var sale:Dictionary=econ.shop_quote(selling)
   if sale.get("ok",false):
    selling.quote_fingerprint=sale.quote_fingerprint;selling.receipt="sale_"+str(Time.get_ticks_usec())
    check(econ.execute_trade(selling).get("committed",false),"real_sale")
   else:check(false,"real_sale_quote")
   var closed:int=0
   for product in preload("res://exo_economy/market.gd").goods():
    if not preload("res://exo_economy/trade_goods.gd").mapping(str(product)).get("ok",false):closed+=1
   check(closed==9,"nine_unmapped_goods_blocked")
   check(w.journey.data.coins==before_coins,"legacy_coins_preserved")
   var collision:Dictionary=intent.duplicate(true);collision.quantity=2
   check(econ.execute_trade(collision).get("reason")=="receipt_collision","receipt_collision")
   var far:Vector3=w.player.position;w.player.position+=Vector3(20,0,0)
   check(not econ.shop_quote(request).get("ok",false),"merchant_distance_denied")
   w.player.position=far
   check(w.save_progress(),"v4_save")
 # Failed travel must preserve crowd container, not just saved data.
 var crowd:RefCounted=w.exo_core.instances.crowd_illusion
 var old_container:Node3D=crowd.crowd.container
 var old_region:Node3D=w.active_region
 var real_path:String=w.journey.path;w.journey.path="user://missing_v4_parent/travel.json"
 check(not await w.change_region(14),"v4_failed_travel")
 check(w.active_region==old_region and crowd.crowd.container==old_container,"crowd_preserved_failed_travel")
 w.journey.path=real_path
 w.queue_free();await process_frame;await process_frame
 print("V4_RESULT ",JSON.stringify({"checks":checks,"failures":failures,"reopen":reopen}))
 quit(0 if failures.is_empty() else 1)
