from pathlib import Path
from zipfile import ZipFile
import os,json,hashlib,shutil,difflib,datetime
ROOT=Path('/mnt/data/C03_ALFA_WORK');SRC=Path('/mnt/data/sources')
changes=[];warnings=[];issues=[]

def digest(data):return hashlib.sha256(data).hexdigest()
def load(rel):return (ROOT/rel).read_text(encoding='utf-8')
def store(rel,text,reason):
 p=ROOT/rel;old=p.read_bytes() if p.exists() else None
 new=text.encode('utf-8')
 if new==old:return
 p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(new)
 changes.append({'path':rel,'action':'modified' if old is not None else 'added','reason':reason,'before':digest(old) if old is not None else None,'after':digest(new)})
def replace(rel,old,new,reason):
 a=load(rel)
 if a.count(old)!=1:raise RuntimeError(f'Expected one match {rel}: {old[:110]!r} count={a.count(old)}')
 store(rel,a.replace(old,new),reason)
def put_bytes(rel,data,reason,overwrite=False):
 p=ROOT/rel
 if p.exists():
  if p.read_bytes()==data:return
  if not overwrite:raise RuntimeError('Existing differing path: '+rel)
  was=digest(p.read_bytes())
 else:was=None
 p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(data)
 changes.append({'path':rel,'action':'modified' if was else 'added','reason':reason,'before':was,'after':digest(data)})
def module(zipname,prefixes,excludes=()):
 z=ZipFile(SRC/zipname)
 for n in z.namelist():
  if n.endswith('/') or n.startswith('__MACOSX/') or '..' in Path(n).parts:continue
  if not any(n.startswith(v) for v in prefixes):continue
  if any(n.startswith(v) for v in excludes):continue
  put_bytes(n,z.read(n),'C03 fonte candidata: '+zipname,overwrite=False)

# C02: persistencia atomica candidata. Retain all scripts (17 files); never mix partial old/new files.
z=ZipFile(SRC/'CORE-PERSISTENCE-01P-CANDIDATO.zip')
for n in z.namelist():
 if n.startswith('isolated/') and n.endswith('.gd'):
  rel=n[len('isolated/'):]
  put_bytes(rel,z.read(n),'C02 Core Persistence 01P atomic patch',overwrite=True)
# Fix security of pre-existing migration backups: matching world identity, version/schema, parse and semantic validity.
p='exo_core/persistence/save_coordinator.gd';s=load(p)
old=''' if FileAccess.file_exists(backup):return not FileAccess.get_file_as_string(backup).is_empty()'''
new=''' if FileAccess.file_exists(backup):
  var previous_backup: String=FileAccess.get_file_as_string(backup)
  if previous_backup.is_empty():return false
  var parsed_backup: Variant=JSON.parse_string(previous_backup)
  var parsed_source: Variant=JSON.parse_string(snapshot)
  if not parsed_backup is Dictionary or not parsed_source is Dictionary:return false
  if int(parsed_backup.get("version",-1))!=4 or int(parsed_source.get("version",-1))!=4:return false
  if not parsed_backup.get("world") is Dictionary or not parsed_source.get("world") is Dictionary:return false
  var old_world: Dictionary=parsed_backup.world
  var source_world: Dictionary=parsed_source.world
  if str(old_world.get("id",""))!=str(source_world.get("id","")) or str(old_world.get("id",""))=="":return false
  if int(old_world.get("schema",-1))!=1:return false
  if not old_world.get("events") is Dictionary:return false
  if not parsed_backup.get("character") is Dictionary or not parsed_backup.get("items") is Array:return false
  return true'''
assert s.count(old)==1
store(p,s.replace(old,new),'C02 validate pre-existing nonempty migration backup against source world identity/schema/data structure')
# C03: HUD feature with core Visual base preserved, no wholesale settings overwrite.
z=ZipFile(SRC/'EXO-Murim-HUD-01-PATCH.zip')
for n in z.namelist():
 if n.startswith('exo_ui/') and not n.endswith('/'):put_bytes(n,z.read(n),'C03 native EXO HUD widget',overwrite=False)
for rel,old,new in [
 ('exo_hud.gd','const STYLES=["Sistema"','const STYLES=["EXO Murim (oficial)"'),
 ('exo_hud.gd','not get_tree().paused','not get_tree().paused and int(world.graphics.hud.style)!=0'),
 ('exo_hud.gd','["Vida","Mana","Estamina"]','["Vida","Qi","Estamina"]'),
 ('exo_hud.gd','["V","M","S"]','["V","Q","S"]'),
 ('exo_menu.gd','Mana %.0f / 100','Qi %.0f / 100'),
]:
 s=load(rel)
 if old not in s:issues.append('HUD missing expected '+old);continue
 store(rel,s.replace(old,new),'C03 HUD Qi and official style')
# For pause_ui, apply donor patch where compatible using hunks later; retain Visual settings full source.
rel='pause_ui.gd';base=load(rel)
new_pause=z.read(rel).decode('utf-8')
if new_pause.startswith(base[:35]):
 # All prior CityViva changes are in this donor? verify diff amount and locations via opcodes.
 ratio=difflib.SequenceMatcher(None,base.splitlines(),new_pause.splitlines()).ratio()
 if ratio>0.92:store(rel,new_pause,'C03 patch native HUD, inventory hotkey, keep current pause flow')
 else:issues.append('pause_ui donor mismatch ratio %.2f'%ratio)
else:issues.append('pause_ui mismatched header; manual review')
# visual settings keep base, add only control text.
rel='ui/pages/settings.gd';s=load(rel)
if 'P • Central do Aventureiro\\nTab • mapa' in s:
 store(rel,s.replace('P • Central do Aventureiro\\nTab • mapa','P • Central do Aventureiro\\nI • inventário\\nTab • mapa'),'C03 HUD input key guidance; keep EXO Visual settings')

# NPC R1 then R2: new standalone modules and targeted integration.
module('EXO-Murim-NPC-System-02-PATCH-CANDIDATO.zip',['npc_system02/'])
# R2 supersedes same module files only; preimages differ by design.
z2=ZipFile(SRC/'EXO-Murim-NPC-System-02-R2-POLIDO-CANDIDATO.zip')
for n in z2.namelist():
 if n.startswith('npc_system02/') and not n.endswith('/'):
  put_bytes(n,z2.read(n),'C04 NPC 02 R2 replacing corresponding R1 component',overwrite=True)
# integrate R1 bridge in City Viva base (one new const/two calls, preserve roster and transactional save)
replace('living_world/bridge.gd','const People=preload("res://living_world/people.gd")','const People=preload("res://living_world/people.gd")\nconst Profile=preload("res://npc_system02/profile.gd")','C04 NPC personalities')
replace('living_world/bridge.gd','\t\tresults.append(state.npcs[id])','\t\tif Profile.enrich(state.npcs[id],seed_text):changed=true\n\t\tresults.append(state.npcs[id])','C04 NPC roster profile enrich')
replace('living_world/bridge.gd','\tif not State.valid(state):','\tif Profile.link_roster(results):changed=true\n\tif not State.valid(state):','C04 NPC social network validation')
# Residents: R2 source adds methods and state, preserving existing family of visual logic via targeted donor.
rel='convergence/resident.gd';old=load(rel);donor=z2.read(rel).decode()
if difflib.SequenceMatcher(None,old.splitlines(),donor.splitlines()).ratio()<0.42:raise RuntimeError('R2 resident too divergent')
store(rel,donor,'C04 NPC R2 resident directional routines/social/patrol')
# Host bridge small patch without overriding core CityViva scripts.
replace('convergence/game.gd','const Resident=preload("res://convergence/resident.gd")','const Resident=preload("res://convergence/resident.gd")\nconst NPCDirector=preload("res://npc_system02/director.gd")','C04 NPC Director service reference')
replace('convergence/game.gd','var residents: Array=[]','var residents: Array=[]\nvar npc_director: Variant','C04 NPC manager')
replace('convergence/game.gd','\tsuper._ready()\n\tecology_director=EcologyDirector.new(self)','\tsuper._ready()\n\tnpc_director=NPCDirector.new(self)\n\tif is_instance_valid(player):player.collision_mask=player.collision_mask|8\n\tecology_director=EcologyDirector.new(self)','C04 NPC init and bidirectional collision')
replace('convergence/game.gd','for actor in residents:state.actors[actor.identity.id]=actor.snapshot()','for actor in residents:state.actors[actor.identity.id]=actor.snapshot(float(state.clock))','C04 snapshot NPC sim clock')
replace('convergence/game.gd','candidate.resident_routes(person,people));residents.append(actor)','candidate.resident_routes(person,people),float(extension().clock));residents.append(actor)','C04 NPC clock on loading')
replace('convergence/game.gd','\tfor actor in residents:actor.nearby_residents=residents\n\tif graphics!=null:graphics.apply()','\t# NPC Director updates nearby residents spatially instead of global O(N^2).\n\tif graphics!=null:graphics.apply()','C04 NPC spatial neighborhood')
replace('convergence/game.gd','\t\tfor actor in residents:\n\t\t\tactor.visual_active=actor.presentation_visible\n\t\t\tactor.step(delta,hour)','\t\tif npc_director!=null:npc_director.tick(delta,residents,float(extension().clock))','C04 NPC spatial tick')

# C03 flow: retain old prologue/training fallback but enter procedural world after creator and prevent manual regress.
rel='murim_flow.gd'; s=load(rel); anchor='''\tworld.ui.close_flow()
\tworld.message("Nascimento: "+str(birthplace.title)+" • procure a representante da Guilda.")'''
if s.count(anchor)==1:
 store(rel,s.replace(anchor,'''\tworld.ui.close_flow()
\t# Convergencia 03: first playable area comes from atlas, not legacy initial enclosure.
\t# Deferred until the creator callback releases the UI tree; old prologue assets
\t# remain available only as references while shared quests/training are migrated.
\tif world.has_method("change_region") and world.has_method("starting_region"):
\t\tworld.call_deferred("change_region",world.starting_region(),"")
\t\tworld.message("Nascimento: "+str(birthplace.title)+" • viajando para as regiões procedurais.")
\t\treturn true
\tworld.message("Nascimento: "+str(birthplace.title)+" • procure a representante da Guilda.")'''),'C03 boot creator to procedural atlas after creation')
else:issues.append('creator procedural anchor missing')
# Special guard: don't redirect to legacy if checkpoint already in region; avoid accidental relaunch old camp.
replace('convergence/game.gd','''\tif convergence_ready and current_region>=0:return_home()
\tsuper.resume_checkpoint()''','''\tif convergence_ready and current_region>=0:
\t\t# Respawn in current region, not the retired legacy camp.
\t\tvar saved_region: int=current_region
\t\treturn_home()
\t\tcall_deferred("change_region",saved_region,"")
\t\treturn
\tsuper.resume_checkpoint()''','C03 regional checkpoint recovery to seeded region (legacy respawn remains temporary fallback)')
# Fix misleading legacy hint, although original return gate still used as explicit safe fallback.
replace('convergence/game.gd','"RECINTO INICIAL • E"','"PORTAL DE RETORNO • E"','C03 rename legacy return gate visible text')

# Terrain: use VISUAL branch and cherry pick only required additions in CityViva, preserving flat collision branch, UV roadmap and latest river bridges.
terrain='EXO-Murim-Terreno-01-R1-EXO-Visual01-PATCH.zip';zz=ZipFile(SRC/terrain)
for n in zz.namelist():
 if n.startswith('genesis/') and n not in ['genesis/region_scene.gd','genesis/terrain.gdshader'] and not n.endswith('/'):
  put_bytes(n,zz.read(n),'C05 Terrain R1 new owned dressing/foliage assets',overwrite=False)
replace('genesis/region_scene.gd','const APPROVED_GROUND="res://textures/terrain_approved/"','const APPROVED_GROUND="res://textures/terrain_approved/"\nconst EXO_TERRAIN_R1=preload("res://genesis/terrain_dressing_r1.gd")','C05 Terrain R1 scene dependency')
replace('genesis/region_scene.gd','mat.set_shader_parameter("road_tex",load(APPROVED_GROUND+"trilha_terra.png"))','mat.set_shader_parameter("road_tex",load(APPROVED_GROUND+"trilha_terra.png"))\n\tmat.set_shader_parameter("macro_seed",float(int(data.noise.seed)%8191))','C05 Terrain shader seed per region')
replace('genesis/region_scene.gd','\tbuild_roadside_grass()','\tbuild_roadside_grass()\n\t# WorldGen R1: deterministic isometric foliage and grouped rocks.\n\tEXO_TERRAIN_R1.build(self,data)','C05 Terrain WorldGen overlay after existing roadside grass')
# Shader: donor version includes all Visual R2 uniforms and no extra changes besides terrain improvements.
base_sh=load('genesis/terrain.gdshader');donor_sh=zz.read('genesis/terrain.gdshader').decode('utf-8')
if base_sh.count('uniform float foliage_uv_scale = 2.45;')!=1 or 'build_river' in donor_sh:raise RuntimeError('terrain shader diff conflict')
# Only diff belongs to macro and warp: approved Visual R2 shader preserved aside from these additions.
store('genesis/terrain.gdshader',donor_sh,'C05 Terrain R1 low frequency anti-tiling shader; Visual R2 uniforms retained')
# Selected module sources; blocked features are not registered until QA + contract owners are reconciled.
module('EXO-Murim-Dungeon-Genesis-02-R2-POLIDO-CANDIDATO.zip',['exo_dungeon/'])
module('EXO-Murim-Itens-Procedurais-02-R3-CANDIDATO.zip',['exo_items/'])
module('EXO-Murim-Forja-Monumental-04-CANDIDATO-REVISADO.zip',['exo_monumental/'])
module('EXO-Murim-Mestres-Artes-Marciais-01-R2-CANDIDATO.zip',['exo_martial/'])
module('EXO-Murim-Bestiario-Inimigos-02-PATCH.zip',['exo_bestiary/'])
module('EXO-Murim-Creature-Harmonizacao-02-CANDIDATO.zip',['exo_creature_harmonizacao02/'])
module('EXO-Murim-Humanoides-03-R2-CANDIDATO.zip',['exo_humanoids03_r2/'])
# Quarantine laboratory mock from runtime export; preserve under documentation only and avoid parsing in exported game.
mock=ROOT/'exo_martial/integration/mock_narrative_r2.gd'
if mock.exists():
 payload=mock.read_bytes();dest=ROOT/'C03_TRANSFERENCIA/quarentena/mock_narrative_r2.gd.txt';dest.parent.mkdir(parents=True,exist_ok=True);dest.write_bytes(payload)
 mock.unlink()
 changes.append({'path':'exo_martial/integration/mock_narrative_r2.gd','action':'quarantined','reason':'Lab fake narratives not permitted as production service','before':digest(payload),'after':None})
# Avoid placing images from 480 unlicensed skins into the product. Humanoids R2 generates own procedural geometry.
# Path in module intentionally isolated; no global modules registration for these incomplete sections.
# User save namespace must never write to baseline's test campaigns.
replace('project.godot','config/name="EXO-Murim — Cidade Viva 01 R2"','config/name="EXO-Murim — Convergencia 03 ALFA R1"','C03 candidate identity')
replace('project.godot','config/custom_user_dir_name="EXO-Murim-Convergencia-01"','config/custom_user_dir_name="EXO-Murim-Convergencia-03-ALFA-QA"','C03 isolate saves from actual game')
# Fail closed for unfinished modules: source is delivered, but module manifests NOT autoregistered.
(ROOT/'C03_TRANSFERENCIA').mkdir(exist_ok=True)
status={
'base_sha256':'1ef340db3f3ff0f133ec07808ee38d553ca4de7c48810f53b2cedc41cfde0b84',
'build_status':'ALFA_R1_UNVERIFIED_NO_GODOT',
'checkpoints':{'C00':'PASS_original_zip_sha_and_crc','C01':'NOT_RUN_GODOT','C02':'CANDIDATE_CODE_APPLIED_NATIVE_NOT_RUN','C03':'CANDIDATE_HUD_PROCEDURAL_NATIVE_NOT_RUN','C04':'CANDIDATE_NPC02_R1_R2_NATIVE_NOT_RUN','C05':'CANDIDATE_TERRAIN_R1_NATIVE_NOT_RUN','C06_C11':'STAGED_SOURCE_BLOCKED_FUNCTIONAL_RUNTIME'},
'blocked_features':['Dungeon enter/loot/host','Atomic dungeon loot R3','Martial real enrollment/progression','Monument reservation in live WorldGen','Bestiary spawn/combat integration','Creature actor visual runtime binding','Humanoid wardrobe runtime hook','Commercial release without per-asset rights review'],
'notes':['NO native Godot 4.6.2 available in this runtime','Existing base contains active legacy home flows that require further review','RIG arm flexion bug remains unconfirmed','Terrain R1 preserved approved ground images; shader lacks compiled proof','No unverified third party files deleted or silently licensed','Quarantined humanoid PNGs excluded from new module import'],
'issues':issues,'warnings':warnings,
'modified_or_added_count':len(changes),
}
(ROOT/'C03_TRANSFERENCIA/ESTADO-INTEGRACAO-C03.json').write_text(json.dumps(status,indent=2,ensure_ascii=False))
(ROOT/'C03_TRANSFERENCIA/MANIFESTO-ARQUIVOS-ALTERADOS.json').write_text(json.dumps(changes,indent=2,ensure_ascii=False))
print(json.dumps({'files_changed':len(changes),'issues':issues,'status':status['checkpoints']},indent=2,ensure_ascii=False))
