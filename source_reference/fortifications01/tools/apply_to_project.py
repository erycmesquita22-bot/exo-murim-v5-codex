"""Opt-in Fortifications 01 install into Work-validated R3 Godot project.
Does not replace any existing production file; aborts on conflicting methods.
Usage: python tools/apply_to_project.py /path/to/EXO-Murim-R3 --apply
Without --apply: dry-run report of expected changes.
"""
import argparse,hashlib,pathlib,re,shutil,sys,json

def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
p=argparse.ArgumentParser();p.add_argument('project',type=pathlib.Path);p.add_argument('--apply',action='store_true');a=p.parse_args()
root=pathlib.Path(__file__).parent.parent;dest=a.project
source_files=list((root/'fortifications').glob('*.gd'))
region=dest/'convergence/region.gd';godot=dest/'project.godot'
if not godot.is_file() or not region.is_file():raise SystemExit('ABORT: project.godot or convergence/region.gd missing')
body=region.read_text(encoding='utf-8')
if not re.search(r'^extends\s+"res://genesis/region_scene.gd"',body,re.M):raise SystemExit('ABORT: different region.gd base')
if re.search(r'^func\s+build\(',body,re.M):raise SystemExit('ABORT: already has build override; use manual integration')
if 'res://fortifications/adapter.gd' in body:raise SystemExit('ABORT: already integrated')
if not re.search(r'^func\s+build_lots\(',body,re.M):raise SystemExit('ABORT: build_lots not found')
for f in source_files:
 if (dest/'fortifications'/f.name).exists():raise SystemExit('ABORT: destination file exists: '+f.name)
hook='''\n# EXO Fortificações 01 (opt-in): preserve the validated R3 residents and architecture.\nconst Fortifications = preload("res://fortifications/adapter.gd")\nfunc build(d: RefCounted,allowed: Array) -> void:\n\tsuper.build(d,allowed)\n\tvar fortification_result: Dictionary=Fortifications.apply(self,d)\n\tset_meta("fortification_status",fortification_result.get("status","not_planned"))\n'''
print(json.dumps({'mode':'apply' if a.apply else 'dry-run','project':str(dest),'region_source_sha256':sha(region),'files_to_add':[f.name for f in source_files],
                  'hook':'append at end of convergence/region.gd','preserve_existing_region_lines':True},ensure_ascii=False,indent=2))
if not a.apply:sys.exit(0)
(dest/'fortifications').mkdir(exist_ok=True)
for f in source_files:shutil.copy2(f,dest/'fortifications'/f.name)
region.write_text(body.rstrip()+'\n'+hook,encoding='utf-8')
print('APPLIED. Next: run Godot native QA and full regression suite; do not promote without those results.')
