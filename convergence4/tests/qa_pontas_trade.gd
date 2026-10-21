extends SceneTree
var w:Node3D
var failures:Array=[]
func check(ok:bool,label:String):
 print("PONTAS_TRADE_CHECK ",label," ",ok)
 if not ok:failures.append(label)
func _initialize():call_deferred("run")
func finish():
 print("PONTAS_TRADE_RESULT ",JSON.stringify({"failures":failures,"fixture":"official roster vendor positioned on verified floor, noon, 10000 Wen test balance"}))
 w.queue_free();await process_frame;await process_frame;quit(0 if failures.is_empty() else 1)
func run():
 var reopen:bool="reopen" in OS.get_cmdline_user_args()
 w=preload("res://convergence/game.gd").new();w.load_on_start=reopen;w.save_path="user://pontas_trade.json";root.add_child(w);await process_frame
 if reopen:
  for i in range(1800):
   await physics_frame
   if w.current_region>=0 and not w.changing_region:break
  w.simulation_enabled=false
  var expected:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("user://pontas_trade_expected.json"))
  check(w.current_region==78,"reopen_region")
  check(w.journey.data.items==expected.items,"reopen_inventory")
  check(w.journey.data.exo_economy.receipts==expected.receipts,"reopen_receipts")
  check(w.journey.data.exo_economy.shops==expected.shops,"reopen_stock")
  check(w.journey.data.living_world.balances.bronze==expected.balance,"reopen_wallet")
  await finish();return
 w.flow.phase="creator";w.flow.create_character({"name":"Comercio QA","race":0,"path":0,"robe":1,"hair":0,"skin":0,"style":0,"weapon":"sword","outfit":0},101)
 for i in range(1800):
  await physics_frame
  if w.current_region>=0 and not w.changing_region:break
 check(await w.change_region(78),"city")
 w.ui.resume();w.simulation_enabled=false;w.extension().clock=1080.0
 var vendor:CharacterBody3D
 for actor in w.residents:
  if str(actor.identity.role)=="merchant":vendor=actor;break
 check(is_instance_valid(vendor),"official_vendor")
 if not is_instance_valid(vendor):await finish();return
 var at:Vector3=w.regional_spawn(w.active_region,Vector3(0,w.active_region.data.center_h,0))
 check(at.is_finite(),"safe_floor")
 if not at.is_finite():await finish();return
 w.player.position=at;vendor.position=at+Vector3(1.5,0,0);vendor.sheltered=false
 for i in range(25):
  await physics_frame
  for actor in [w.player,vendor]:actor.velocity=Vector3(0,-6,0);actor.move_and_slide();actor.apply_floor_snap()
 var request:Dictionary={"vendor_id":str(vendor.identity.id),"region_id":78,"good_id":"iron","side":"buy","quantity":1}
 var proof:Dictionary=w.economy_host_v4.verify_merchant(request)
 check(not proof.is_empty(),"physical_proximity_authorized")
 if proof.is_empty():print("TRADE_DIAGNOSTIC ",w.player.position," ",vendor.position," floor ",w.player.is_on_floor()," ",vendor.is_on_floor());await finish();return
 var economy:RefCounted=w.exo_core.instances.exo_economy
 w.journey.data.living_world.balances.bronze=10000
 check(w.save_progress(),"fixture_saved")
 var quote:Dictionary=economy.shop_quote(request)
 check(quote.get("ok",false),"official_quote")
 if not quote.get("ok",false):print("TRADE_QUOTE ",quote);await finish();return
 request.quote_fingerprint=quote.quote_fingerprint;request.receipt="pontas_buy_1"
 var goods:Script=preload("res://exo_economy/trade_goods.gd")
 var count:int=goods.count_stock(w.journey.data.items,goods.mapping("iron"))
 var result:Dictionary=economy.execute_trade(request)
 check(result.get("ok",false) and result.get("committed",false),"buy_committed")
 check(goods.count_stock(w.journey.data.items,goods.mapping("iron"))==count+1,"physical_inventory_item")
 check(w.journey.data.living_world.balances.bronze==10000-int(quote.total_wen),"wallet_debited")
 var committed:Dictionary=w.journey.data.duplicate(true)
 check(economy.execute_trade(request).get("duplicate",false),"receipt_replay")
 check(w.journey.data==committed,"replay_no_state_delta")
 var second:Dictionary=request.duplicate(true);second.receipt="pontas_buy_2"
 quote=economy.shop_quote(second);second.quote_fingerprint=quote.get("quote_fingerprint","")
 var original_path:String=w.journey.path;w.journey.path="user://missing_pontas/fail.json"
 check(not economy.execute_trade(second).get("ok",true),"disk_failure_rejected")
 check(w.journey.data==committed,"disk_failure_wallet_inventory_stock_rollback")
 w.journey.path=original_path
 w.player.position+=Vector3(10,0,0)
 check(w.economy_host_v4.verify_merchant(second).is_empty(),"remote_vendor_rejected")
 check(not economy.execute_trade(second).get("ok",true),"remote_trade_rejected")
 var expectation:Dictionary={"items":committed.items,"balance":committed.living_world.balances.bronze,"receipts":committed.exo_economy.receipts,"shops":committed.exo_economy.shops}
 FileAccess.open("user://pontas_trade_expected.json",FileAccess.WRITE).store_string(JSON.stringify(expectation))
 await finish()
