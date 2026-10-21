#!/usr/bin/env python3
"""Create a new original EXO Skill Forge candidate from a JSON recipe.
Run inside the installed EXO project: python exo_skill_forge/tools/add_skill.py --recipe my_skill.json
Never changes the 16 legacy techniques or grants in-game unlocks.
"""
import argparse, json, re
from pathlib import Path
BASE=Path(__file__).resolve().parents[1]

def build(recipe):
    refs=json.loads((BASE/'data/reference_index.json').read_text(encoding='utf-8'))
    templates=json.loads((BASE/'data/templates.json').read_text(encoding='utf-8'))['templates']
    template_by_id={x['id']:x for x in templates}
    key=str(recipe['id']).strip().lower()
    if not re.fullmatch(r'[a-z0-9_]{3,64}',key):raise ValueError('id deve ser snake_case de 3 a 64 caracteres')
    typ=str(recipe.get('template',''))
    if typ not in template_by_id:raise ValueError('template desconhecido')
    style=str(recipe.get('style',''))
    school=str(recipe.get('school',''))
    pose=str(recipe.get('weapon_pose',''))
    if style not in refs['style_ids']:raise ValueError('estilo não registrado')
    if school and school not in refs['school_ids']:raise ValueError('escola não registrada')
    if pose not in refs['weapon_poses']:raise ValueError('pose não registrada')
    for k,limit in [('damage',5000),('qi',100),('stamina',100),('cooldown',180),('range',18),('radius',8),('level',200)]:
        if float(recipe.get(k,0))<0 or float(recipe.get(k,0))>limit:raise ValueError(f'{k} fora do limite')
    shape=template_by_id[typ]['shape'];dmg=float(recipe.get('damage',0))
    effect=[]
    if typ=='projectile':effect.append({'stage':'release','op':'projectile','speed':14.0,'max_projectiles':1,'collision_required':True})
    if typ=='dash':effect.append({'stage':'release','op':'movement','mode':'dash','distance':float(recipe.get('range',3)),'duration':0.25,'collision_required':True})
    if typ=='field':effect.append({'stage':'release','op':'field','duration':3.0,'tick_interval':0.5,'max_instances':1})
    if typ=='channel':effect.append({'stage':'release','op':'channel','duration':1.5,'tick_interval':0.35,'max_ticks':4})
    if dmg>0:effect.append({'stage':'impact','op':'damage','shape':shape,'coefficient':1.0,'max_targets':5 if shape!='projectile' else 1})
    status=str(recipe.get('status','none'))
    if status not in ['none','slow','root','stagger','knockback','mark','bleed','burn','pierce','heal','shield','cleanse']:raise ValueError('status inválido')
    if status in ['heal','shield','cleanse']:
        effect.append({'stage':'release','op':status,'duration':4.0 if status=='shield' else 0.0,'value':45})
    elif status!='none':effect.append({'stage':'impact','op':'status','status':status,'duration':1.3,'strength':0.25})
    ident='exo.sf.'+key
    tracks=lambda kind:[{'phase':phase,'key':f'{kind}/{key}/{phase}','binding':'requires_binding',**({'gain':gain} if kind=='sfx' else {})} for phase,gain in [('prepare',0.6),('release',0.8),('impact',1.0)]]
    return {'id':ident,'name':str(recipe['name']),'source':'authorial','state':'candidate_not_unlocked','executor':'generic','template':typ,
      'tags':{'weapon_poses':[pose],'weapon_ids':[],'styles':[style],'schools':[school] if school else [],'min_level':int(recipe.get('level',1)),'min_cultivation_rank':0,'cultivation_stage':'proposed_requires_mapping','actor_types':recipe.get('actor_types',['player','npc','enemy']),'element':int(recipe.get('element',11))},
      'balance':{'damage':dmg,'qi':float(recipe.get('qi',0)),'stamina':float(recipe.get('stamina',0)),'cooldown':float(recipe.get('cooldown',4)),'range':float(recipe.get('range',0)),'radius':float(recipe.get('radius',0)),'cone_degrees':template_by_id[typ]['cone_degrees'],'cast_time':float(recipe.get('cast_time',0.6)),'release_time':float(recipe.get('release_time',0.25))},
      'effects':effect,'presentation':{'animation':{'key':'skill_forge/'+typ,'phase':'cast','binding':'requires_binding'},'vfx':tracks('vfx'),'audio':tracks('sfx')},
      'provenance':{'origin':'original_EXO_Skill_Forge_01','rights':'project_authorial_design','commercial_use':'design_only_media_pending'}}

def main():
    ap=argparse.ArgumentParser(description=__doc__);ap.add_argument('--recipe',required=True,type=Path);ap.add_argument('--dry-run',action='store_true')
    args=ap.parse_args(); recipe=json.loads(args.recipe.read_text(encoding='utf-8')); new=build(recipe)
    path=BASE/'data/authorial.json'; all_skills=json.loads(path.read_text(encoding='utf-8'))
    if any(row['id']==new['id'] for row in all_skills):raise SystemExit('ID já existe, nenhuma alteração')
    if args.dry_run:print(json.dumps(new,ensure_ascii=False,indent=2));return
    all_skills.append(new);path.write_text(json.dumps(all_skills,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    print(f'Criada: {new["id"]} (candidata não ativada). Total autoral: {len(all_skills)}')
if __name__=='__main__': main()
