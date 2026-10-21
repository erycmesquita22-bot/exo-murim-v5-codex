extends "res://validation_r3/support.gd"
func _initialize() -> void:call_deferred("run")
func run() -> void:
    await boot("user://v5-gameplay.json")
    for i in range(300):
        if w.current_region>=0 and not w.changing_region:break
        await physics_frame
    check(w.current_region>=0,"world_started")
    w.graphics.set_option("fps_limit",0)
    # Test inventory through its real use/equip/save path.
    var potion: String=""
    for item in w.journey.data.items:
        if item.kind=="consumable" and item.ref=="potion":potion=item.uid;break
    w.health=maxi(1,w.max_health-35)
    var hp: int=w.health
    check(not potion.is_empty() and w.inventory.use(potion) and w.health>hp,"consume_heal_and_save")
    var sword: String=w.inventory.add("weapon","sword")
    check(not sword.is_empty() and w.inventory.use(sword) and w.journey.data.equipped==sword,"equip_inventory_and_save")
    var visual_before: int=w.vfx_host_v5.emitted
    check(w.techniques.cast(0),"real_skill_cast")
    await frames(50)
    check(w.vfx_host_v5.emitted>visual_before,"authorized_vfx_release")
    var forged: Dictionary=w.exo_core.instances.exo_vfx_forge.receive_authorized_cue({})
    check(not forged.get("ok",true),"forged_vfx_rejected")
    w.combat_timer=0.0
    # A transaction with a physically present NPC04 merchant and the official wallet.
    w.extension().clock=900.0
    var vendor: Variant=null
    for actor in w.residents:
        if str(actor.identity.role)=="merchant":vendor=actor;break
    check(vendor!=null,"merchant_present")
    if vendor!=null:
        w.player.position=vendor.position+Vector3(1.2,.2,0);w.player.velocity=Vector3.ZERO
        await frames(15)
        var request: Dictionary={"vendor_id":str(vendor.identity.id),"region_id":w.current_region,"good_id":"iron","side":"buy","quantity":1}
        var economy: Variant=w.exo_core.instances.exo_economy
        var quote: Dictionary=economy.shop_quote(request)
        check(bool(quote.get("ok",false)),"npc04_physical_shop_quote:"+str(quote.get("reason","")))
        if bool(quote.get("ok",false)):
            # Explicit initial test balance, never a mocked transaction or fake success.
            w.journey.data.living_world.balances.bronze=10000
            var balance: int=w.journey.data.living_world.balances.bronze
            request.quote_fingerprint=quote.quote_fingerprint;request.receipt="v5_native_purchase"
            var result: Dictionary=economy.execute_trade(request)
            check(bool(result.get("ok",false)),"npc04_trade_commit:"+str(result.get("reason","")))
            check(w.journey.data.living_world.balances.bronze==balance-int(quote.total_wen),"wallet_debit_exact")
            var items_before: String=JSON.stringify(w.journey.data.items)
            var retry: Dictionary=economy.execute_trade(request)
            check(bool(retry.get("duplicate",false)) and JSON.stringify(w.journey.data.items)==items_before,"trade_idempotent")
        var offers: Array=w.journey_manager.options(vendor.identity)
        check(not offers.is_empty(),"real_quest_offers")
        if not offers.is_empty():
            check(w.journey_manager.accept(offers[0]),"accept_real_quest_at_npc")
    var talk: Dictionary={}
    var giver: Variant=null
    for actor in w.residents:
        for offer in w.journey_manager.options(actor.identity):
            if offer.type=="talk":talk=offer;giver=actor;break
        if not talk.is_empty():break
    check(not talk.is_empty(),"talk_contract_available")
    if not talk.is_empty():
        w.player.position=giver.position+Vector3(1.2,.15,0);w.player.velocity=Vector3.ZERO
        await frames(10)
        print("TALK_DEBUG_GIVER ",JSON.stringify({"id":giver.identity.id,"visible":giver.rig.visible,"sheltered":giver.sheltered,"distance":giver.position.distance_to(w.player.position),"player":str(w.player.position),"actor":str(giver.position)}))
        check(w.journey_manager.accept(talk),"talk_contract_accept")
        var receiver: Variant=null
        for actor in w.residents:
            if str(actor.identity.id)==str(talk.target):receiver=actor;break
        check(receiver!=null,"talk_target_materialized")
        if receiver!=null:
            w.player.position=receiver.position+Vector3(1.2,.15,0);w.player.velocity=Vector3.ZERO
            await frames(10)
            w.gate_cooldown=0;w.interaction_cooldown=0;w.attack_time=-1;w.roll_time=-1
            w.interact()
            check(not w.wg5_visit.inside(),"npc_not_shadowed_by_building_door")
            check(w.journey_manager.state().quests.get(talk.id,{}).get("state","")=="COMPLETED","talk_core_event_completes_contract")
            w.ui.resume()
            w.player.position=giver.position+Vector3(1.2,.15,0);w.player.velocity=Vector3.ZERO
            await frames(10)
            var bronze_before: int=w.journey.data.living_world.balances.bronze
            check(w.journey_manager.claim(talk.id),"claim_quest_reward")
            check(w.journey.data.living_world.balances.bronze==bronze_before+int(talk.reward.bronze),"quest_reward_exact")
            check(not w.journey_manager.claim(talk.id),"quest_reward_not_duplicated")
    check(await w.change_region(52),"wild_combat_region")
    w.extension().clock=0.0
    if not w.ecology_director.sites.is_empty():
        var site: Dictionary=w.ecology_director.sites[0]
        await observe(site)
        var actors: Array=w.ecology_director.active.values()
        check(not actors.is_empty(),"native_ecology_spawn")
        if not actors.is_empty():
            var actor: Node3D=actors[0]
            facts["fight"]=await fight(actor,true)
            check(await loot(str(facts.fight.uid)),"real_drop_collection")
            check(w.save_progress(),"combat_loot_save")
    else:check(false,"ecology_sites")
    await finish("v5_gameplay")
