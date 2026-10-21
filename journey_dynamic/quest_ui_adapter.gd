extends RefCounted
# Integrated into the existing P > Missões > Crônicas page.
static func render(menu: Control,parent: Node,world: Node3D) -> void:
	if world.get("journey_manager")==null:return
	var m=world.journey_manager
	var st: Dictionary=m.state()
	var xp: Dictionary=st.progress
	menu.text(parent,"JORNADA DINÂMICA • NÍVEL %d • XP %d"%[int(xp.level),int(xp.xp)],21)
	menu.text(parent,"Pontos de atributo: %d • Bronze: %d • Reputação local: %+d"%[int(xp.unspent),int(world.journey.data.get("living_world",{}).get("balances",{}).get("bronze",0)),int(st.local_reputation.get(str(world.current_region),0))],15,670)
	menu.text(parent,"CONTRATOS ATIVOS (%d / 5)"%st.quests.size(),19)
	for id in st.quests.keys():
		var q: Dictionary=st.quests[id]
		menu.text(parent,"%s • %s • Região %02d\nProgresso: %d/%d • XP %d, bronze %d"%[str(q.title),str(q.state),int(q.region),int(q.progress),int(q.goal),int(q.reward.xp),int(q.reward.bronze)],15,680)
		if q.state=="COMPLETED":
			var claim_button=menu.button(parent,"RECEBER RECOMPENSA DO CONTRATANTE",func():menu.result(m.claim(id)))
			claim_button.disabled=not m.nearby_giver(q)
		elif q.type=="deliver":
			var deliver_button=menu.button(parent,"ENTREGAR 2 FERROS AO CONTRATANTE",func():menu.result(m.deliver(id)))
			deliver_button.disabled=not m.nearby_giver(q)
		menu.button(parent,"PARAR DE RASTREAR" if st.tracked==id else "RASTREAR MISSÃO",func():m.track("" if st.tracked==id else id);menu.open("jornada"))
		menu.button(parent,"ABANDONAR CONTRATO",func():menu.result(m.cancel(id)))
	menu.text(parent,"CONTRATOS DISPONÍVEIS • Converse com um NPC e consulte aqui",19)
	var offered:=0
	for resident in world.residents:
		if resident.position.distance_to(world.player.position)>3.3 or not resident.rig.visible:continue
		menu.text(parent,"Contratante: "+str(resident.identity.display_name),16)
		for offer in m.options(resident.identity):
			if st.quests.has(offer.id) or st.rewarded.has(offer.id):continue
			offered+=1
			menu.text(parent,"%s • Região %02d • XP %d • Bronze %d"%[str(offer.title),int(offer.region),int(offer.reward.xp),int(offer.reward.bronze)],15,680)
			menu.button(parent,"ACEITAR: "+str(offer.title),func():menu.result(m.accept(offer)))
	if offered==0:menu.text(parent,"Aproxime-se de um morador disponível para ver contratos válidos.",14,680)
	menu.text(parent,"MEMÓRIA DA JORNADA • %d acontecimentos"%st.history.size(),18)
	for i in range(st.history.size()-1,maxi(-1,st.history.size()-9),-1):
		menu.text(parent,"• "+str(st.history[i].title),13,680)
