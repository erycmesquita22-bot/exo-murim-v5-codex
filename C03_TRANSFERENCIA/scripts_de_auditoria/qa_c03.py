from pathlib import Path
from zipfile import ZipFile
from PIL import Image
import hashlib,json,re,io,datetime,shutil,statistics,math
R=Path('/mnt/data/C03_ALFA_WORK');SRC=Path('/mnt/data/sources')
T=R/'C03_TRANSFERENCIA';T.mkdir(exist_ok=True)
QA=[]
def row(key,ok,details,kind='STATIC'):
 QA.append({'id':key,'status':'PASS' if ok else 'FAIL','details':details,'type':kind})
def sha(b):return hashlib.sha256(b).hexdigest()
source_approved='1ef340db3f3ff0f133ec07808ee38d553ca4de7c48810f53b2cedc41cfde0b84'
base=SRC/'EXO-Murim-Cidade-Viva-01-R2-PROJETO.zip';row('C00_SHA256_BASE',sha(base.read_bytes())==source_approved,sha(base.read_bytes()))
zbase=ZipFile(base);row('C00_CRC_BASE',zbase.testzip() is None,'All 4088 source ZIP members CRC check')
# Nine APPROVED textures unchanged.
tex=[x for x in zbase.namelist() if '/textures/terrain_approved/' in x and x.lower().endswith('.png')];changed=[]
for x in tex:
 rel=x.split('/',1)[1];target=R/rel
 if not target.exists() or zbase.read(x)!=target.read_bytes():changed.append(rel)
row('C05_APPROVED_TEXTURES_BITWISE',len(tex)>=9 and len(changed)==0,{'count':len(tex),'changed':changed})
# Geometry optimizations preserved and shader from latest Visual R2 retained.
region=(R/'genesis/region_scene.gd').read_text();shader=(R/'genesis/terrain.gdshader').read_text()
row('C05_KEEP_ORIGINAL_GROUND_COLLISION',all(x in region for x in ['flat_collision_chunks','if lowest==highest','build_river_road_decks()']), 'Flat chunk optimization and river deck path retained')
row('C05_ANTI_TILE_SHADER',all(x in shader for x in ['macro_seed','alternate_uv','warp','foliage_uv_scale','exo_microvariation']), 'Macro variation + original EXO Visual uniforms preserved')
row('C05_DRESSING_CONNECTED',all(x in region for x in ['EXO_TERRAIN_R1.build(self,data)','macro_seed']) and (R/'genesis/dressing_r1/foliage_original.png').exists(),'Dressing hooked into worldgen + seed')
with Image.open(R/'genesis/dressing_r1/foliage_original.png') as im:
 row('C05_FOLIAGE_ATLAS',im.width%4==0 and im.height%2==0 and im.getbbox() is not None and im.mode in ('RGBA','LA'),'Atlas %dx%d mode=%s'%(im.width,im.height,im.mode))
row('C05_NO_ENV_EXTERN_DOWNLOAD', 'kenney' not in (R/'genesis/terrain_dressing_r1.gd').read_text().lower(), 'Generated vegetation and rocks; no Kenney reference in new environment module')
# Module packages structurally integrated as isolated folders.
for n,part in [('CORE01P','exo_core/persistence/receipt_ledger.gd'),('NPC02_R2','npc_system02/social.gd'),('EXO_HUD','exo_ui/hud_murim.gd'),('ITEMS02_R3','exo_items/module/entrypoint.gd'),('DUNGEON02_R2','exo_dungeon/module/entrypoint.gd'),('FORJA04','exo_monumental/generation/planner.gd'),('MARTIAL_R2','exo_martial/module.gd'),('BESTIARY02','exo_bestiary/catalog/species_catalog.gd'),('CREATURE_HARM02','exo_creature_harmonizacao02/module/entrypoint.gd'),('HUMANOID03_R2','exo_humanoids03_r2/scripts/voxel_geometry.gd')]:
 row('C03_SOURCE_'+n,(R/part).exists(),part)
# Only source staged, disabled modules not registered until owner QA.
mods=json.loads((R/'exo_core/modules.json').read_text());ids=[m['id'] for m in mods]
notready=['dungeon_genesis','exo_items','exo_martial','exo_monumental','exo_bestiary','exo_creature_harmonizacao02','exo_humanoids03_r2']
row('BLOCKED_GATES_FAIL_CLOSED',all(n not in ids for n in notready),'Unverified components not registered in production core')
# No external imported animation remains live; no use of third-party assets in runtime animation.
anim=(R/'animation_library.gd').read_text();rig=(R/'rig.gd').read_text()
row('RIG01_LOCAL_DIRECTIONS','lateral: float=0.0' in anim and 'EXO_original_local_8directions' in anim and 'direction.y,speed,direction.x' in rig,'Eight-direction GDScript procedural animation source installed')
row('RIG01_UNUSED_THIRDPARTY_REMOVAL',not (R/'assets/kenney/character-a.glb').exists() and not list(R.rglob('assets/kenney/character-a.glb')) and 'assets/kenney/' not in anim,'Unused Kenney imported model removed from candidate, license kept in transfer evidence')
# Direction maths fixture: facing has signed forward/lateral responses; not an actual native animation screenshot.
samples=[]
for degrees in range(0,360,45):
 a=math.radians(degrees);forward=math.cos(a);lateral=math.sin(a)
 swing=math.sin(math.pi/2)*0.64
 x=swing*forward;z=swing*lateral*.34
 samples.append({'dir_degrees':degrees,'shoulder_pitch_rad':round(x,6),'shoulder_lateral_rad':round(z,6)})
row('RIG01_DIRECTIONAL_CPU_FIXTURE',len(set((v['shoulder_pitch_rad'],v['shoulder_lateral_rad']) for v in samples))==8,'8 unique local shoulder rotations in pure math; not rendered Godot',kind='CPU_MODEL_NOT_GODOT')
# Source path scanner compares unresolved preloads to historical baseline (two baseline misses remain).
missing=[]
for file in R.rglob('*.gd'):
 data=file.read_text(errors='replace')
 for rel in re.findall(r'preload\("res://([^\"]+)"\)',data):
  if not (R/rel).exists():missing.append({'source':str(file.relative_to(R)),'target':rel})
row('SOURCE_PRELOAD_MISSING_ONLY_HISTORICAL',all(x['source'] in ['godot/demo.gd','exo_core/module_template/test.gd'] for x in missing),{'unresolved':missing})
# Core backup security regression: code paths present, no native I/O simulated.
coordinator=(R/'exo_core/persistence/save_coordinator.gd').read_text()
row('C02_EXISTING_BACKUP_VALIDATION_SOURCE',all(x in coordinator for x in ['parsed_backup: Variant=JSON.parse_string','source_world.get("seed"','old_world.get("schema"','claim_receipts']),'Nonempty pre-existing backup requires parsable JSON, matching world id/seed, supported schema')
row('C03_PROCEDURAL_BIRTH_SOURCE','call_deferred("change_region",world.starting_region(),"")' in (R/'murim_flow.gd').read_text() and 'E • Retornar ao recinto' not in (R/'convergence/game.gd').read_text(),'Creator defers to seeded region; interactive legacy return disabled')
row('C03_INPUT_INVENTORY_I','KEY_I' in (R/'pause_ui.gd').read_text() and 'Qi' in (R/'exo_hud.gd').read_text(),'Inventory I and Qi in source')
# New GDScript file counts and JSON parse
json_errors=[];jcount=0
for f in R.rglob('*.json'):
 try:json.loads(f.read_text(errors='replace'));jcount+=1
 except Exception as e:json_errors.append((str(f.relative_to(R)),str(e)))
row('JSON_PARSE_GLOBAL',not json_errors,{'parsed':jcount,'errors':json_errors[:15]})
# No Godot 4.6.2 binary available; not passed.
QA.extend([{'id':'GODOT_4_6_2_PARSE_IMPORT','status':'NOT_RUN','type':'GODOT_NATIVE','details':'Godot executable absent; no script/shader compiled'}, {'id':'GODOT_GAMEPLAY_88REGIONS','status':'NOT_RUN','type':'GODOT_NATIVE','details':'No native execution, player or NPC tests'}, {'id':'GODOT_VISUAL_FPS_VEGA8','status':'NOT_RUN','type':'HARDWARE','details':'No Ryzen 3200GE/Vega8 performance test'}, {'id':'GODOT_RIG_8DIRECTIONS','status':'NOT_RUN','type':'GODOT_NATIVE','details':'Pure Python directional fixture only, visual Godot proof required'}])
status={'qa_type':'STATIC_ONLY','date':'2026-10-19','tests':QA,'counts':{key:sum(x['status']==key for x in QA) for key in ('PASS','FAIL','NOT_RUN')}}
(T/'QA-C03-ALFA-R1.json').write_text(json.dumps(status,ensure_ascii=False,indent=2))
(T/'RIG01-DIRECOES-MODELO-CPU.json').write_text(json.dumps(samples,ensure_ascii=False,indent=2))
report='''# EXO-MURIM — CONVERGENCIA 03 ALFA R1 — RELATÓRIO DE ENGENHARIA

Data: 19/10/2026. **CANDIDATO FONTE — NÃO HOMOLOGADO / QA NATIVO NOT_RUN**.

## O que foi efetivamente feito
- Base imutável conferida por SHA256 e CRC: `EXO-Murim-Cidade-Viva-01-R2-PROJETO.zip`.
- Aplicado Core Persistence 01-P nos 17 scripts do patch, em conjunto; acrescentada validação do backup pré-migração existente por JSON/schema/world ID/seed. **Sem prova de compilação, save/reopen ou recuperação real**.
- HUD 01 seletivo; preservada a página original de configuração EXO Visual. Tecla I para inventário e rótulo Qi.
- NPC System 02 R1 e R2: diretor, perfil, planner, rotinas, residentes e ponte com roster integrados no host. **Sem teste de rotina ao vivo**.
- Criador de personagem programa mudança para região procedural após criação; interação de retorno à vila legada desativada na aventura. Não apagamos dependências compartilhadas da base/prológo.
- Terreno R1: aplicação seletiva do shader e do decorador com billboards/rochas originais. Preservadas nove texturas aprovadas, colisões planas e pontes sobre rios.
- RIG-01: removida amostragem importada de animação externa aplicada somente ao deslocamento frontal. Substituída por animação procedural que considera a movimentação local nos dois eixos e curva os cotovelos no rig local. **Resultado visual ainda não demonstrado no Godot.**
- Modelo externo de animação `assets/kenney/character-a.glb` e import removidos como inutilizados após a alteração. Arquivos de licença/histórico preservados em `C03_TRANSFERENCIA/proveniencia/`.
- Incluídas fontes completas dos módulos Dungeon R2, Itens R3, Forja Monumental 04, Mestres R2, Bestiário 02, Creature Harmonização 02 e Humanoides R2 sob seus próprios namespaces. **ESTÃO EM STAGING E NÃO REGISTRADOS NO CORE ATIVO**, pois os contratos auditados ainda impedem gameplay seguro. Não instalar PNGs 480 skins herdadas em quarentena.

## Bloqueios e limites de aprovação
- Ainda é necessário executar C01 importação e 23 suítes Cidade Viva R2, C02 Core-P backup/schema/reopen, C03 criação+HUD, C04 24h NPC, C05 terreno e FPS.
- Dungeon × Itens: contrato de transação único pendente. Jamais ativar conceder loot usando verificador que retorna true artificialmente.
- Dungeon: proteção do snapshot, visita/retorno/recovery/host/loot real não integrado.
- Forja: reservas de lotes e transições de interiores não integradas no host.
- Mestres: API narrativa de escrita e treino real pendentes.
- Bestiário: spawn/dano/XP e integração visual não conectados. Arte com proveniência não certificada para venda.
- HUD e RIG-01 exigem inspeção visual. Os testes Python verificam somente código e invariantes estáticos, NÃO execução na Godot.
- Depuração de travamento no voo, missão explorar ruínas, mapa TAB e sistema de armas por categoria continuam pendentes de reprodução ou implementação específica.
- Assets externos sem prova de desuso não foram removidos; a base ainda possui materiais com autoria comercial pendente. Não distribuir comercialmente.

## Correções ainda necessárias ANTES de alegar versão jogável integrada
1. Abrir C03 Alfa num Godot 4.6.2 Standard com Compatibility e testar parser/import/shaders; corrigir erros por classe e registrar logs.
2. Testar fim-a-fim criação → região procedural → inventário I → NPC → combate → saves em diretório de QA.
3. Validar e instrumentar backup Core-P: arquivo inválido não vazio, mesmo ID/diferente seed, schema 1/2, primário corrompido, falha de I/O e reopen.
4. Registrar novos módulos SOMENTE por fases C05–C10 sob os contratos e QA do relatório de auditoria. Não substituir sistemas existentes e não construir autoridades duplicadas.
5. Fazer inspeção visual de oito direções de cotovelo e novas folhas 2D/rochas em pelo menos quatro seeds, além de FPS/frametime no PC real.

**O ZIP é um checkpoint real de código alterado e fontes incluídas, não uma Convergência 03 final.**
'''
(T/'RELATORIO-C03-ALFA-R1.md').write_text(report)
work='''# EXO-MURIM — CONTINUAÇÃO DA CONVERGÊNCIA 03 (Chat / Work)

## Atenção: origem autoritativa
Usar este ZIP integral **C03-ALFA-R1** como ponto de partida para a próxima rodada. Ele contém projeto Godot com `project.godot` na raiz após extração. Não iniciar pela base Cidade Viva antiga; não iniciar Convergência 04. Confirme SHA e leia `C03_TRANSFERENCIA/ESTADO-INTEGRACAO-C03.json`.

## Estado concreto
São candidatos com fonte alterada: Core 01P, NPC R2, Terreno R1, HUD, flow procedural e rig RIG-01. Sete outros módulos estão presentes como **staged source somente**, sem registro/host de gameplay; veja `RELATORIO-C03-ALFA-R1.md`. Não marcar PASS sem execução nativa. Salves reais nunca devem ser sobrescritos; o `project.godot` usa um namespace `EXO-Murim-Convergencia-03-ALFA-QA`.

## Próxima execução neste chat
Reauditar o código integrado; corrigir falhas detectadas por Godot e testes nativos; executar testes de regressão; emitir R2 com hashes, logs e diffs, **não refazer merge desde o princípio**.

## Próxima execução em Work (somente após nova rodada Chat)
Abrir último ZIP, instalar/usar Godot 4.6.2 Standard Compatibility quando disponível, rodar importação nativa, boot e 23 testes históricos + scripts de módulos. Validar o personagem de 8 direções e o Terreno R1 visualmente; comparar FPS com base equivalente em Ryzen 3200GE Vega8. Corrigir bugs reais e integrar módulos staged um por vez após seus gates, sem adulterar saves. Reunir logs/capturas nativos e entregar ZIP completo mais recente.

## Ordem e gates
Ler `C03_TRANSFERENCIA/auditoria_pre_c03/ORDEM-DE-MERGE-03.md`, `MATRIZ-CONTRATOS-03.md`, `PLANO-QA-NATIVO-03.md`, `PLANO-LIMPEZA-SEGURA-03.md` e os resultados de QA estático deste ZIP.

## Regras de segurança
Não sobrescrever arquivos comuns a partir de ramos antigos; não ativar recompensas Dungeon×Itens antes de um único commit coerente; não inventar serviços narrativos; não afirmar direitos comerciais de skins legadas; não remover assets com referências dinâmicas sem prova; não trocar rig oficial por humanoide genérico.
'''
(T/'INSTRUCOES-CONTINUACAO-WORK.md').write_text(work)
D=T/'auditoria_pre_c03';D.mkdir(exist_ok=True)
for f in Path('/mnt/data/transfer_reference').glob('*'):
 shutil.copyfile(f,D/f.name)
print(json.dumps(status['counts'],ensure_ascii=False));print('FAIL entries:',[v for v in QA if v['status']=='FAIL'])
