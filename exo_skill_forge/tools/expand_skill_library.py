#!/usr/bin/env python3
"""EXO Skill Forge 01 R2: constrained seeded authorial combinatorics.

Only produces UNLOCKED=FALSE catalog candidates; never modifies EXO Core.
Inspiration is genre-wide, not copied from any protected fictional ability.
"""
import argparse, hashlib, json, random, re, unicodedata
from collections import Counter
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
SRC=ROOT/'data'
GROUP_NAMES={
'corpo':[
 ['Punho da Aurora Fraturada','Joelho do Eco Ascendente','Cotovelo da Estrela Cadente','Passo dos Nove Pulsares','Palma do Horizonte Reverso'],
 ['Punho das Três Respirações','Cotovelada do Discípulo Errante','Guarda do Rio Silencioso','Joelho da Balança Oculta','Passos do Último Desafio'],
 ['Palma do Tigre de Bronze','Dança da Garça Cinzenta','Punho do Trovão Seco','Selo da Tartaruga Antiga','Passo do Veado das Nuvens'],
 ['Punho da Câmera Vazia','Chute do Pátio Chuvoso','Cotovelada da Porta Estreita','Guarda da Última Ponte','Passo do Duelo ao Entardecer']],
'armas':[
 ['Lâmina do Céu Dividido','Corte da Lua Cintilante','Flecha do Rastro Carmesim','Investida do Ferro Sonoro','Arco da Tempestade Rasa'],
 ['Sabre dos Cem Juramentos','Agulha da Casa Oculta','Lança da Dívida Marcial','Cajado do Pavilhão Partido','Corte do Herdeiro sem Nome'],
 ['Gume da Serpente de Jade','Alabarda do Guardião de Sal','Dardo do Corvo Lunar','Ceifa das Folhas do Outono','Golpe da Bigorna Antiga'],
 ['Espada do Beco Encharcado','Punhal da Janela Aberta','Haste do Portão Final','Tiro da Ponte de Pedra','Montante do Pátio Deserto']],
'qi':[
 ['Arco de Qi Prismático','Espiral dos Sete Fluxos','Raio do Núcleo Sereno','Círculo do Pulso Solar','Véu da Pressão Azul'],
 ['Selo do Meridiano Perdido','Vórtice do Manual Incompleto','Pulso do Dantian Velado','Onda do Mestre Itinerante','Muralha da Sétima Circulação'],
 ['Sopro da Pérola da Maré','Espiral do Dragão de Névoa','Orvalho da Flor Imortal','Ressonância do Sino Lunar','Véu da Montanha Sagrada'],
 ['Rajada do Corredor de Seda','Eco da Sala de Treino','Pulso da Lâmpada Vazia','Corrente do Lago de Vidro','Reflexo da Porta do Céu']],
'sangue':[
 ['Fio Rubro das Sombras','Pulso Escarlate Reverso','Dardo da Veia Silenciosa','Passo da Cicatriz Ardente','Círculo do Juramento Carmim'],
 ['Punhal do Herdeiro Ferido','Marca da Dívida Sangrenta','Selo da Linhagem Velada','Dança das Veias Seladas','Lâmina do Pacto Desfeito'],
 ['Gota do Sol Sepultado','Espinho do Coração de Ferro','Ritual da Rosa Rubra','Caminho do Corvo Ferido','Sombra do Tigre Escarlate'],
 ['Talho do Lenço Vermelho','Ferida do Salão Vazio','Dardo da Névoa Rubra','Passo da Taça Quebrada','Marca da Última Promessa']],
'demonica':[
 ['Corte do Abismo Pulsante','Mandíbula da Chama Sombria','Espiral do Vazio Faminto','Passo do Eclipse Rachado','Cúpula do Crepúsculo Negro'],
 ['Sabre do Exilado do Norte','Marca do Culto Caído','Corte da Herança Profana','Investida do Discípulo Rejeitado','Selo do Mestre Sem Rosto'],
 ['Garra do Leão do Submundo','Ceifa do Lótus Noturno','Fogo da Montanha Oca','Dança da Raposa de Cinzas','Barreira dos Portões Inferiores'],
 ['Lâmina sob a Lua Vermelha','Investida da Cripta Fechada','Rugido do Sino Partido','Passos da Fortaleza Negra','Corte do Último Vigia']],
'celestial':[
 ['Espada da Constelação Clara','Asas do Cometa Silencioso','Lança da Órbita Dourada','Arco da Luz Infinita','Proteção do Firmamento Vivo'],
 ['Julgamento do Mestre das Nuvens','Mantra do Pico Esquecido','Corte do Discípulo Ascendido','Passo da Escadaria Celeste','Selo da Virtude Radiante'],
 ['Pluma da Fênix Alva','Resplendor do Qilin Pacífico','Sopro do Dragão da Manhã','Flor da Lua Imaculada','Cúpula da Tartaruga Celeste'],
 ['Corte do Sol na Janela','Lança do Templo Suspenso','Pulso da Manhã Branca','Dança do Sino do Céu','Barreira do Pátio de Ouro']],
'mundana':[
 ['Corte de Três Tempos','Esquiva da Poeira Rente','Arremesso do Olho Firme','Guarda dos Calcanhares','Golpe da Brecha Curta'],
 ['Corte do Aprendiz Paciente','Passo da Estrada de Pedra','Lança do Guarda de Vila','Tiro do Caçador Sem Nome','Guarda da Escola Pequena'],
 ['Punho do Oleiro Antigo','Cajado da Colheita Tardia','Ponta do Carpinteiro','Arco do Lenhador Silencioso','Balanço do Martelo Simples'],
 ['Golpe da Feira Fechada','Esquiva do Mercado Estreito','Tiro do Muro Baixo','Bloqueio do Portão Rural','Corte do Ferreiro Exausto']]
}
ORIGINS=['anime','manhwa','lendas','cinema']
# Cycles deliberately vary tactical purpose: distance, positioning, pressure, defense, finish.
PATTERNS={
 'corpo':['cone','dash','channel','ward','ring'],
 'armas':['line_slash','fan_slash','projectile','dash','ring'],
 'qi':['projectile','channel','cone','ring','ward'],
 'sangue':['line_slash','projectile','channel','dash','ring'],
 'demonica':['line_slash','cone','channel','dash','ward'],
 'celestial':['line_slash','dash','projectile','ring','ward'],
 'mundana':['line_slash','dash','projectile','ward','cone']
}
ROLES={
 'line_slash':'precision','fan_slash':'cleave','projectile':'ranged_pressure','dash':'mobility','ring':'area_control',
 'cone':'disruption','channel':'sustained_pressure','ward':'defense','heal':'support','field':'zone_denial'
}
SCHOOL_STYLE={
'exo_martial.style.sword_swift':'exo_martial.school.seita_bambu',
'exo_martial.style.saber_iron':'exo_martial.school.cla_montanha',
'exo_martial.style.spear_dragon':'exo_martial.school.pavilhao_lanca',
'exo_martial.style.fist_river':'exo_martial.school.templo_corrente',
'exo_martial.style.kick_crane':'exo_martial.school.vale_grou',
'exo_martial.style.hidden_blade':'exo_martial.school.mercadores_sombra',
'exo_martial.style.qi_serene':'exo_martial.school.mosteiro_jade',
'exo_martial.style.fire_ember':'exo_martial.school.ordem_cinza',
'exo_martial.style.void_arts':'exo_martial.school.ermitagem_vazio',
}
WEAPONS=[
 ('sword','blade','sword_swift'),('greatsword','heavy','saber_iron'),('katana','draw','sword_swift'),
 ('rapier','thrust','sword_swift'),('dagger','reverse','hidden_blade'),('twin_daggers','dual','hidden_blade'),
 ('spear','thrust','spear_dragon'),('halberd','pole','spear_dragon'),('scythe','reap','void_arts'),
 ('quarterstaff','staff','fist_river'),('battle_mace','crush','saber_iron'),('gauntlets','fists','fist_river'),
 ('arcane_staff','focus','qi_serene'),('wand','wand','qi_serene'),('bow','bow','shadow_steps'),('crossbow','crossbow','hidden_blade')]
# Weapon semantics for the twenty specifically authored weapon-technique titles.
# Every item references a REAL R13 item; no new equippable weapon is invented.
ARM_WEAPON_IDS=[
 'sword','katana','bow','greatsword','bow',
 'greatsword','rapier','spear','quarterstaff','sword',
 'dagger','halberd','crossbow','scythe','battle_mace',
 'sword','twin_daggers','arcane_staff','crossbow','greatsword'
]
WEAPON_BY_ID={x[0]:x for x in WEAPONS}
BLOOD_WEAPON_IDS=[
 'dagger','gauntlets','dagger','twin_daggers','scythe',
 'dagger','gauntlets','scythe','twin_daggers','sword',
 'dagger','gauntlets','scythe','twin_daggers','gauntlets',
 'sword','dagger','dagger','twin_daggers','sword'
]
CELESTIAL_WEAPON_IDS=[
 'sword','quarterstaff','spear','arcane_staff','arcane_staff',
 'arcane_staff','quarterstaff','sword','spear','arcane_staff',
 'arcane_staff','spear','arcane_staff','sword','quarterstaff',
 'sword','spear','arcane_staff','quarterstaff','arcane_staff'
]
MUNDANE_WEAPON_IDS=[
 'sword','dagger','bow','quarterstaff','battle_mace',
 'sword','dagger','spear','bow','quarterstaff',
 'gauntlets','quarterstaff','spear','bow','battle_mace',
 'gauntlets','dagger','crossbow','quarterstaff','sword'
]
FAMILY_OPTIONS={
'corpo':[('gauntlets','fists','fist_river'),('gauntlets','fists','kick_crane'),('gauntlets','fists','shadow_steps')],
'armas':WEAPONS,
'qi':[('arcane_staff','focus','qi_serene'),('wand','wand','fire_ember'),('quarterstaff','staff','winter_frost')],
'sangue':[('dagger','reverse','hidden_blade'),('twin_daggers','dual','hidden_blade'),('scythe','reap','void_arts'),('gauntlets','fists','fist_river')],
'demonica':[('scythe','reap','void_arts'),('greatsword','heavy','void_arts'),('halberd','pole','fire_ember'),('arcane_staff','focus','void_arts')],
'celestial':[('sword','blade','sword_swift'),('spear','thrust','spear_dragon'),('arcane_staff','focus','qi_serene'),('quarterstaff','staff','qi_serene')],
'mundana':[('sword','blade','sword_swift'),('dagger','reverse','hidden_blade'),('spear','thrust','spear_dragon'),('quarterstaff','staff','fist_river'),('bow','bow','shadow_steps'),('crossbow','crossbow','hidden_blade'),('battle_mace','crush','saber_iron')]
}
ORIGIN_STYLE={
 'anime':('contraste_cinetico','preparação clara, liberação explosiva e silhueta legível'),
 'manhwa':('hierarquia_marcial','postura disciplinada e evolução de domínio por treino'),
 'lendas':('simbolismo_folclorico','motivos de natureza e bestiário mítico em sinais originais'),
 'cinema':('coreografia_fisica','distância, preparação corporal e leitura de reação do adversário')
}
POWER={
 'corpo':(1.0, 0, 1.22,['stagger','knockback','slow','none','stagger'],'contato e leitura do centro de gravidade'),
 'armas':(1.07, 0.68, 1.0,['bleed','stagger','pierce','none','knockback'],'alcance da arma e janelas de recuperação'),
 'qi':(0.94, 1.45, 0.55,['slow','mark','knockback','root','none'],'circulação de Qi com foco em controle espacial'),
 'sangue':(1.04, 1.0, 0.82,['bleed','bleed','mark','bleed','slow'],'cortes de pressão e sangramento, sem drenagem de HP implementada'),
 'demonica':(1.13, 1.5, 0.82,['burn','mark','stagger','slow','none'],'pressão sombria com alto custo e vulnerabilidade à interrupção'),
 'celestial':(0.99, 1.5, 0.8,['mark','slow','stagger','root','none'],'clareza de trajetória e controle defensivo'),
 'mundana':(0.79, 0, 1.2,['none','none','stagger','none','slow'],'técnica física; sem Qi obrigatório')
}
LEVELS=[1,6,14,26,42]
BASE_DAMAGE=[13,19,29,42,57]
BASE_QI=[0,6,11,17,25]
BASE_STAMINA=[10,13,16,20,25]
BASE_COOLDOWN=[3.0,4.2,5.5,7.6,11.0]
SHAPES={x['id']:x for x in json.loads((SRC/'templates.json').read_text(encoding='utf-8'))['templates']}

def slug(s):
 norm=unicodedata.normalize('NFKD',s).encode('ascii','ignore').decode().lower()
 return re.sub('_+','_',re.sub('[^a-z0-9]+','_',norm)).strip('_')

def make_candidate(family,origin,index,seed):
 if family not in GROUP_NAMES or origin not in ORIGINS or index not in range(5):raise ValueError('grupo/índice inválido')
 oi=ORIGINS.index(origin);name=GROUP_NAMES[family][oi][index]
 # explicit seed+identity ensures reproducible per skill independent of iteration order
 rng=random.Random(int.from_bytes(hashlib.sha256(f'{seed}|{family}|{origin}|{index}'.encode()).digest()[:8],'big'))
 template=PATTERNS[family][index];tp=SHAPES[template]
 opts=FAMILY_OPTIONS[family]
 # all 16 base-weapon IDs are deliberately represented by family armas
 weapon,pose,style_suffix=(WEAPON_BY_ID[ARM_WEAPON_IDS[oi*5+index]] if family=='armas' else WEAPON_BY_ID[MUNDANE_WEAPON_IDS[oi*5+index]] if family=='mundana' else WEAPON_BY_ID[BLOOD_WEAPON_IDS[oi*5+index]] if family=='sangue' else WEAPON_BY_ID[CELESTIAL_WEAPON_IDS[oi*5+index]] if family=='celestial' else opts[(oi*5+index+seed%len(opts))%len(opts)])
 if family=='armas' and weapon in ('bow','crossbow'): template='projectile';tp=SHAPES[template]
 if family=='armas' and weapon=='rapier': template='line_slash';tp=SHAPES[template]
 if weapon in ('bow','crossbow') and template!='projectile':template='projectile';tp=SHAPES[template]
 if family=='mundana' and template=='ward' and weapon in ('bow','crossbow'):template='dash';tp=SHAPES[template]
 style='exo_martial.style.'+style_suffix
 school=SCHOOL_STYLE.get(style,'')
 group_multiplier,qi_multiplier,sta_multiplier,status_cycle,identity=POWER[family]
 tier=index
 level=LEVELS[tier]
 # Balance is deterministic with bounded seeded variation, never open-ended exponentials.
 damage=round(BASE_DAMAGE[tier]*group_multiplier*rng.uniform(0.94,1.06),2)
 if template=='ward': damage=0.0
 qi=min(100,round((BASE_QI[tier]+(4 if family in ('qi','sangue','demonica','celestial') else 0)+(2 if origin in ('anime','lendas') else 0))*qi_multiplier))
 stamina=min(100,round(BASE_STAMINA[tier]*sta_multiplier))
 cooldown=round(BASE_COOLDOWN[tier]*(1.2 if template in ('ring','ward','channel') else 1.)*rng.uniform(0.97,1.04),2)
 range_m={'line_slash':4.5,'fan_slash':4.0,'projectile':9.0,'dash':3.8,'ring':0.0,'cone':4.5,'channel':5.5,'ward':0.0}[template]
 range_m=round(min(18,range_m*(1+0.13*tier)),2)
 radius=round(1.5+0.28*tier,2) if template=='ring' else 0.0
 status=status_cycle[index]
 if template=='ward': status='none'
 effects=[]
 if template=='projectile':effects.append({'stage':'release','op':'projectile','speed':round(11.+tier*1.2,1),'max_projectiles':1,'collision_required':True})
 if template=='dash':effects.append({'stage':'release','op':'movement','mode':'dash','distance':range_m,'duration':0.25,'collision_required':True})
 if template=='channel':effects.append({'stage':'release','op':'channel','duration':1.0,'tick_interval':0.25,'max_ticks':4})
 if template=='ward':effects.append({'stage':'release','op':'shield','value':round(20+level*1.15,1),'duration':3.5})
 if damage>0:effects.append({'stage':'impact','op':'damage','shape':tp['shape'],'coefficient':1.0,'max_targets':1 if template=='projectile' else 4 if template in ('ring','cone','fan_slash','channel') else 2})
 if status!='none' and damage>0:
  effects.append({'stage':'impact','op':'status','status':status,'duration':round(0.75+0.12*tier,2),'strength':0.22})
 stance={'line_slash':'ritmo de precisão','fan_slash':'arco de pressão','projectile':'janela de projeção','dash':'passo explosivo','ring':'domínio circular','cone':'ruptura de postura','channel':'pressão contínua','ward':'postura de proteção'}[template]
 rng_shuffle=['esquerda','direita','frontal'][rng.randrange(3)]
 action=f'{stance}; entrada {rng_shuffle}; {identity}'
 costs={'qi':qi,'stamina':stamina}
 def cue(kind,phase):return {'phase':phase,'key':f'{kind}/sf_r2/{family}/{slug(name)}/{phase}', 'binding':'requires_binding',**({'gain':0.55 if phase=='prepare' else 0.8 if phase=='release' else 0.9} if kind=='sfx' else {})}
 motifs={'anime':'energia com traço cinético controlado','manhwa':'pressão marcial e postura de mestre','lendas':'símbolos naturais e míticos genéricos','cinema':'impacto físico com antecipação'}
 risk='telegraph_and_recovery' if template in ('ring','channel','ward') else 'counterable_approach' if template=='dash' else 'line_of_sight_and_spacing'
 return {
  'id':'exo.sf.r2.'+slug(name),'name':name,'source':'authorial','state':'candidate_not_unlocked','executor':'generic','template':template,
  'tags':{'weapon_poses':[pose],'weapon_ids':[weapon],'styles':[style],'schools':[school] if school else [],'min_level':level,'min_cultivation_rank':0,'cultivation_stage':'proposed_requires_mapping','actor_types':['player','npc','enemy'],'element':11,
     'inspiration_origin':origin,'power_family':family,'combat_role':ROLES[template],'rarity_tier':tier+1,'world_tags':[family,origin,'authorial',ROLES[template]],'visual_language':ORIGIN_STYLE[origin][0], 'combo_role':['opener','chaser','finisher','counter','defensive'][index]},
  'balance':{'damage':damage,**costs,'cooldown':cooldown,'range':range_m,'radius':radius,'cone_degrees':tp['cone_degrees'], 'cast_time':0.38+0.1*tier+(0.32 if template in ('ring','channel','ward') else 0.),'release_time':0.19+0.045*tier},
  'effects':effects,
  'presentation':{'animation':{'key':f'skill_forge/{template}','phase':'cast','binding':'requires_binding'},'vfx':[cue('vfx',phase) for phase in ('release','impact')], 'audio':[cue('sfx',phase) for phase in ('prepare','release','impact')]},
  'design':{'origin_language':ORIGIN_STYLE[origin][1],'description':action,'visual_motif':motifs[origin], 'risk_counterplay':risk, 'dependency_state':'requires_host_execution_and_media_bindings','hp_sacrifice_or_leech_implemented':False, 'authored_not_copied':True,
      'balance_policy':'prototype_requires_real_combat_tuning','training_requirement':'to_be_defined_by_martial_progression'},
  'provenance':{'origin':'original_EXO_Skill_Forge_01_R2','rights':'original_concept_no_external_media','commercial_use':'design_only_media_pending','inspiration':'generic_genre_motifs_not_existing_named_attacks','generation_seed':seed}
 }

def generate(seed=20261020):
 return [make_candidate(fam,orig,i,seed) for fam in GROUP_NAMES for orig in ORIGINS for i in range(5)]

def main():
 p=argparse.ArgumentParser(description=__doc__);p.add_argument('--seed',type=int,default=20261020);p.add_argument('--output',type=Path,required=True)
 p.add_argument('--family',choices=list(GROUP_NAMES));p.add_argument('--inspiration',choices=ORIGINS);p.add_argument('--limit',type=int,default=140)
 a=p.parse_args();skills=[s for s in generate(a.seed) if (not a.family or s['tags']['power_family']==a.family) and (not a.inspiration or s['tags']['inspiration_origin']==a.inspiration)]
 if a.limit<1:raise SystemExit('limite deve ser positivo')
 a.output.parent.mkdir(parents=True,exist_ok=True)
 a.output.write_text(json.dumps(skills[:a.limit],ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
 c=Counter(x['tags']['power_family'] for x in skills[:a.limit]);print('Geradas',len(skills[:a.limit]),'candidatas determinísticas, seed',a.seed,dict(c),'->',a.output)
if __name__=='__main__':main()
