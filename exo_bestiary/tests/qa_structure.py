#!/usr/bin/env python3
"""Static, deliberately NOT a GDScript parser."""
from pathlib import Path
import re,json,sys
root=Path(__file__).resolve().parents[2]
files=list((root/'exo_bestiary').rglob('*.gd'))
errors=[]; refs=0
for p in files:
 s=p.read_text(encoding='utf8')
 for t in re.findall(r'(?:preload|load)\(\s*[\'\"]res://([^\'\"]+)',s):
  refs+=1
  if not (root/t).is_file():errors.append(f'{p.relative_to(root)}: missing {t}')
 # Balanced brackets ignoring comments and quotes: a lexical guard only.
 stack=[];quote=None;esc=False
 for line_no,line in enumerate(s.splitlines(),1):
  for col,ch in enumerate(line,1):
   if quote:
    if esc:esc=False
    elif ch=='\\':esc=True
    elif ch==quote:quote=None
   elif ch in "\"'": quote=ch
   elif ch=='#':break
   elif ch in '({[':stack.append((ch,line_no,col))
   elif ch in ')}]':
    if not stack or '({['[')}]'.index(ch)] != stack[-1][0]:errors.append(f'{p.name}:{line_no} unmatched {ch}');break
    stack.pop()
  if quote: errors.append(f'{p.name}:{line_no} unterminated string');quote=None
 if stack:errors.append(f'{p.name} nonclosed {stack[-1]}')
 # detect mutable non-constant assets?
 if '\t' in s:errors.append(f'{p.name}: tabs inside GDScript (style only)')
scene=root/'exo_bestiary/lab/laboratory.tscn'
if 'res://exo_bestiary/lab/laboratory.gd' not in scene.read_text():errors.append('scene has no valid script')
res={'status':'PASS' if not errors else 'FAIL','godot_parser':'NOT_RUN','scripts':len(files),'static_resource_references':refs,'errors':errors}
(root/'QA-ESTRUTURA-BESTIARIO-02.json').write_text(json.dumps(res,indent=2,ensure_ascii=False)+'\n')
print(json.dumps(res,ensure_ascii=False));sys.exit(bool(errors))
