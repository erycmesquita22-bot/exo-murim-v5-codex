#!/usr/bin/env python3
"""EXO Murim C03 Alfa R12 STATIC integrity/indent audit; no Godot simulation."""
import zipfile,sys,hashlib,re,json
from collections import Counter
BASE_SHA="44d2408b91531ca5abe7ea3240a40445f631c5a90a26ece3c5356b09739b9a58"
EXPECTED={"convergence/game.gd":126,"regional_ecology/territories.gd":31,"convergence/region.gd":30,"genesis/settlements/settlement_planner.gd":22,"inventory.gd":16,"cultivation.gd":6,"regional_ecology/rewards.gd":6,"regional_ecology/director.gd":5}
def sha(b):return hashlib.sha256(b).hexdigest()
def main(a,b):
  result={"kind":"STATIC_SOURCE_ONLY_NOT_NATIVE_GODOT","checks":[],"errors":[]}
  def check(name,ok,extra=None):
    result["checks"].append({"name":name,"status":"PASS" if ok else "FAIL","detail":extra})
    if not ok:result["errors"].append(name)
  try:
    with zipfile.ZipFile(a) as src,zipfile.ZipFile(b) as dst:
      check("R11_SHA",sha(open(a,'rb').read())==BASE_SHA)
      check("R11_CRC",src.testzip() is None)
      check("R12_CRC",dst.testzip() is None)
      check("ALL_R11_PATHS_PRESERVED",set(src.namelist()).issubset(set(dst.namelist())))
      allowed=set(EXPECTED)|{"project.godot"}
      changes=[]
      for name in src.namelist():
        if src.read(name)!=dst.read(name):changes.append(name)
      check("ONLY_NINE_ALLOWED_SOURCE_FILES_CHANGED",set(changes)==allowed,changes)
      count=0
      for path,expected in EXPECTED.items():
        old=src.read(path).decode('utf-8').splitlines()
        new=dst.read(path).decode('utf-8').splitlines()
        same=len(old)==len(new) and [x.lstrip(' \t') for x in old]==[x.lstrip(' \t') for x in new]
        differences=sum(x!=y for x,y in zip(old,new))
        normalized=all(not re.match(r'^ +\S',x) for x in new)
        check('IDENTICAL_CODE_TOKENS_'+path,same)
        check('CORRECTED_INDENT_'+path,differences==expected and normalized, differences)
        count+=differences
      check('EXACTLY_242_LINES_CONVERTED',count==242,count)
      check('R12_SEPARATE_QA_NAMESPACE',b'ALFA R12 QA' in dst.read('project.godot'))
      check('ACTIVE_MAIN_SCENE_PRESERVED',b'run/main_scene="res://convergence/game.tscn"' in dst.read('project.godot'))
      bad=[]; scripts=0;docs=0
      for name in dst.namelist():
        if name.endswith('.json'):
          try:json.loads(dst.read(name).decode('utf-8'));docs+=1
          except Exception as e:bad.append((name,str(e)))
        if name.endswith('.gd'):
          scripts+=1
          # Mixed tabs+space prefixes are an actionable import blocker.
          t=dst.read(name).decode('utf-8-sig',errors='replace').splitlines()
          has_tabs=any(bool(re.match(r'^\t+\S',x)) for x in t)
          has_spaces=any(bool(re.match(r'^ +\S',x)) for x in t)
          if has_tabs and has_spaces:bad.append((name,'Mixed indentation'))
      check('JSON_AND_SCRIPT_INDENT_SCAN',not bad,{"json_documents":docs,"gdscripts":scripts,"issues":bad[:30]})
  except Exception as e:result['errors'].append('EXCEPTION:'+str(e))
  result['passed']=sum(x['status']=='PASS' for x in result['checks'])
  result['failed']=sum(x['status']=='FAIL' for x in result['checks'])+sum(x.startswith('EXCEPTION:') for x in result['errors'])
  print(json.dumps(result,indent=2,ensure_ascii=False))
  return 0 if result['failed']==0 else 1
if __name__=='__main__':
  if len(sys.argv)!=3:raise SystemExit('Usage: python qa_c03_r12_static.py R11.zip R12.zip')
  raise SystemExit(main(sys.argv[1],sys.argv[2]))
