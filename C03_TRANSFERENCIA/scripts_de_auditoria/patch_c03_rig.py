from pathlib import Path
import json,hashlib,shutil
R=Path('/mnt/data/C03_ALFA_WORK')
p=R/'animation_library.gd'
old=p.read_bytes()
new='''extends RefCounted
# EXO-MURIM C03 / directional local animation, original procedural code.
# No external animation clips or Kenney model in the release runtime.
# The character rig and combat-specific Arsenal/Anatomy remain authoritative.
static func locomotion(rig: Node3D, phase: float, sprint: bool, arms_free: bool, forward: float, speed: float, lateral: float=0.0) -> void:
 if not arms_free or speed<0.06:return
 # Direction is already measured in the character's LOCAL body coordinates;
 # this prevents elbow swing from staying fixed to a world/screen compass.
 var intensity: float=clampf(speed/3.6,0.0,1.0)
 var cadence: float=sin(phase)
 var stride: float=cadence*intensity*(0.85 if sprint else 0.64)
 for i in range(2):
  var side: float=1.0 if i==0 else -1.0
  # Fore/aft run and lateral sidestep are separate local rotations.
  rig.arms[i].rotation.x=side*stride*forward
  rig.arms[i].rotation.z=side*0.05+side*stride*lateral*0.34
  # Elbows always bend relative to the rotating parent arm, never world +X.
  var compression: float=absf(stride)*(0.16+0.20*absf(forward)+0.12*absf(lateral))
  rig.forearms[i].rotation.x=-0.18-compression
 rig.set_meta("motion_source","EXO_original_local_8directions")
'''
p.write_text(new,encoding='utf8')
rig=R/'rig.gd';s=rig.read_text()
a='preload("res://animation_library.gd").locomotion(self,gait_phase,sprint,arms_free,direction.y,speed)'
b='preload("res://animation_library.gd").locomotion(self,gait_phase,sprint,arms_free,direction.y,speed,direction.x)'
assert s.count(a)==1
rig.write_text(s.replace(a,b))
# The previously imported external animation GLB is now dead code. Move licenses
# and provenance notes to release transfer metadata, not runtime resources.
ken=R/'assets/kenney';q=R/'C03_TRANSFERENCIA/proveniencia/kenney_animation_removed';q.mkdir(parents=True,exist_ok=True)
for f in ken.iterdir():
 if f.suffix=='.glb' or f.suffix=='.import':
  f.unlink()
 else:
  shutil.move(str(f),str(q/f.name))
ken.rmdir()
manifest=R/'C03_TRANSFERENCIA/MANIFESTO-ARQUIVOS-ALTERADOS.json'
items=json.loads(manifest.read_text())
for file,prior,reason in [('animation_library.gd',old,'RIG-01 replace external forward-only animation with original local-space eight-direction swing'),('rig.gd',None,'RIG-01 pass lateral direction into elbow animation')]:
 val=(R/file).read_bytes()
 items.append({'path':file,'action':'modified','reason':reason,'before':hashlib.sha256(prior).hexdigest() if prior is not None else 'see unmodified baseline','after':hashlib.sha256(val).hexdigest()})
for f in ['assets/kenney/character-a.glb','assets/kenney/character-a.glb.import']:
 items.append({'path':f,'action':'removed_from_candidate','reason':'Unused external imported motion model; no active runtime references after RIG-01','before':None,'after':None})
manifest.write_text(json.dumps(items,ensure_ascii=False,indent=2))
status_path=R/'C03_TRANSFERENCIA/ESTADO-INTEGRACAO-C03.json';d=json.loads(status_path.read_text());d['modified_or_added_count']=len(items)
d['checkpoints']['RIG-01']='CODE_PATCHED_PROCEDURAL_8DIR_NATIVE_NOT_RUN'
d['notes']=[v for v in d['notes'] if v!='RIG arm flexion bug remains unconfirmed']+['RIG-01 root cause found: forward-only external imported animation; replacement written, visually NOT VERIFIED', 'Kenney animation model removed from candidate; provenance retained under C03_TRANSFERENCIA']
status_path.write_text(json.dumps(d,ensure_ascii=False,indent=2))
print('RIG01 patched, unused external motion GLB removed, transfer provenance maintained')
