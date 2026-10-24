"""Reproducible resident skin/profile pass; stable NPC IDs, homes, routes and saves."""
import json
from pathlib import Path
roster=Path(__file__).parents[1]/'village_npcs/roster.json'
data=json.loads(roster.read_text())
faces={
 'young_ash':('#30343b','young'), 'young_chestnut':('#6c4734','young'), 'young_black':('#252a33','young'),
 'adult_auburn':('#70443d','adult'), 'adult_black':('#343139','adult'), 'adult_brown':('#524034','adult'),
 'weathered':('#493a33','adult'), 'guard_broad':('#2c3032','adult'),
 'elder_silver':('#b8b7a9','elder'), 'elder_beard':('#c3c1b0','elder'), 'elder_ash':('#858684','elder'),
 'herbalist_grey':('#979185','elder'), 'river_tan':('#474344','adult'), 'scholar':('#35373d','adult')}
role_faces={
 'discípulo':['young_ash','young_chestnut','young_black','scholar','adult_auburn','young_black','adult_black'],
 'lavrador':['weathered','adult_brown','river_tan','elder_ash','young_chestnut'],
 'vigia':['guard_broad','adult_black'],
 'artesão':['adult_brown','elder_silver'],
 'comerciante':['adult_auburn'],
 'morador':['elder_ash','young_chestnut'],
 'estalajadeiro':['adult_brown','elder_silver'],
 'herborista':['herbalist_grey']}
explicit={'ji_wol':'adult_black','fisher_west':'weathered','fisher_jetty':'river_tan','square_local':'elder_ash','tea_worker':'young_chestnut','estate_master_weak':'elder_beard','terrace_master_weak':'elder_silver'}
styles=['cropped','low_tail','half_up','swept','long_tail','compact_tail','loose_short']
role_colors={
 'discípulo':[('#53677b','#aeb8b7','#78838a','#3e4c5e'),('#716b82','#bbb2bd','#79738a','#484958')],
 'lavrador':[('#8b8460','#bdb18b','#8d7658','#585c4b'),('#a07c62','#c6b090','#80644b','#64625a')],
 'vigia':[('#4c6572','#8799a0','#897861','#374752')],
 'artesão':[('#8b7668','#c2ae9a','#8b7265','#5d5b59')],
 'comerciante':[('#657878','#c8b9a0','#b29a75','#505d60')],
 'morador':[('#8e7274','#c5ada8','#907a74','#595661')],
 'estalajadeiro':[('#697f88','#c4bbaa','#af906d','#545f69')],
 'herborista':[('#68836d','#b4bda2','#9a8960','#485d55')]}
counts={}
for n in data['npcs']:
 role=n['role'];idx=counts.get(role,0);counts[role]=idx+1
 face=explicit.get(n['id'],role_faces.get(role,['adult_black'])[idx%len(role_faces.get(role,['adult_black']))])
 hair,age=faces[face]
 n['face']=face
 n['face_path']='res://modules/village_life/npc_faces/'+face+'.png'
 n['age_band']=age
 n['hair']['color']=hair
 n['hair']['style']=('silver_bun' if face in ['elder_silver','herbalist_grey'] else ('long_tail' if face=='elder_ash' else styles[(idx+len(role))%len(styles)]))
 physique=('strong' if role in ['vigia','mestre de cultivo'] or face in ['guard_broad','weathered'] else ('slim' if age=='young' or face=='scholar' else 'average'))
 n['physique']=physique
 dims=n['body_style'];base_h={'young':.91,'adult':1.01,'elder':.96}[age]
 dims['height']=round(max(.82,min(1.17,base_h+(idx%4)*.055)),3)
 dims['width']=round(max(.82,min(1.18,{'slim':.88,'average':.99,'strong':1.12}[physique]+(idx%3)*.025)),3)
 dims['depth']=round(max(.86,min(1.16,{'slim':.91,'average':1.0,'strong':1.09}[physique]+(idx%2)*.035)),3)
 if role in role_colors:
  c=role_colors[role][idx%len(role_colors[role])]
  n['apparel']=dict(zip(['outer','tunic','sash','trousers'],c))
 n['importance']='ordinary'
 n['display_name']=n['label'].split(' · ')[0]
 n['title']=''
 if n['id']=='ji_wol':
  n.update(importance='key',display_name='Ji Wol',title='Barqueira do Vau')
 elif n['id']=='estate_master_weak':
  n.update(importance='master',display_name='Mestre do Pátio',title='Cultivo · Refinamento inicial')
  n['apparel']={'outer':'#343f62','tunic':'#b5b8bb','sash':'#b19b68','trousers':'#303647'}
 elif n['id']=='terrace_master_weak':
  n.update(importance='master',display_name='Mestra das Terraças',title='Cultivo · Refinamento inicial')
  n['apparel']={'outer':'#52706d','tunic':'#c9c5b1','sash':'#967c58','trousers':'#384f51'}
 elif n['id']=='herbalist_01':n.update(importance='key',display_name='Herborista de Haneul',title='Ervas e remédios')
 elif n['id']=='tea_worker':n.update(importance='key',display_name='Atendente da Casa de Chá',title='Rumores da estrada')
 n['animation_profile']={'discípulo':'martial','mestre de cultivo':'master','lavrador':'field','comerciante':'trade','artesão':'trade','herborista':'trade','atendente':'serve','estalajadeiro':'serve','vigia':'guard'}.get(role,'resident')
roster.write_text(json.dumps(data,indent=2,ensure_ascii=False)+'\n')
print('profiles',len(data['npcs']),'unique faces',len({n['face'] for n in data['npcs']}))
