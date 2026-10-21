extends RefCounted
## Descriptive opportunities. No NPC generation, persistence, mission or reward writes.
static func propose(request: Dictionary,profile: Dictionary,sectors: Array) -> Dictionary:
 var region_id: int=int(request.get("region_id",-1))
 var families: Array=[]
 var count: int=clampi(int(request.get("families",-1)),0,6) if int(request.get("families",-1))>=0 else int(profile.get("maximum_influential_families",0))
 var names: Array=["Lin","Shen","Han","Yue","Zhao","Wei"]
 var seed_text: String=str(request.get("region_seed","0"))
 for i in range(count):
  var k: int=(seed_text+"|family|"+str(i)).sha256_text().substr(0,8).hex_to_int()%names.size()
  var name: String=str(names[(k+i)%names.size()])
  families.append({"id":"cf/r%d/family_%d"%[region_id,i],"name":"Casa "+name,"influence":15+int((seed_text+str(i)).sha256_text().substr(0,4).hex_to_int()%55),"relationship_authority":"narrative","persistent":false})
 var possible: Array=[]
 for i in range(families.size()):
  for j in range(i+1,families.size()):
   possible.append({"type":"potential_rivalry","participants":[families[i].id,families[j].id],"state":"not_triggered","requires":["narrative_authorization","actual_npc_participants"],"exclusive_group":"cf/social/r%d/%d_%d"%[region_id,i,j]})
 var occupations: Dictionary={}
 for s in sectors:
  var cat: String=str(s.get("category","unknown"));occupations[cat]=int(occupations.get(cat,0))+1
 return {"families":families,"situations":possible,"district_distribution":occupations,"role_weights":{"ordinary_min":float(profile.get("ordinary_population_min_share",0.78)),"noble_probability":float(profile.get("noble_probability",.02)),"guards_per_100":int(profile.get("guards_per_100_residents",4))},"schools_requested":int(request.get("schools",0)),"npc_spawn_count":0,"quest_count":0}
