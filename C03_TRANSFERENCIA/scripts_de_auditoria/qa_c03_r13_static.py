#!/usr/bin/env python3
"""C03-R13 integrity/source audit. Never label these assertions native Godot tests."""
import hashlib, pathlib, zipfile, re, json, sys
ROOT=pathlib.Path(__file__).resolve().parents[2]
EXPECTED="f785d24d6bde1c29ba74e7a47c9f5aad74b004de5c26991957fee061dbeeb796"
ALLOWED_CHANGES={'project.godot','convergence/game.gd'}

def digest(data):return hashlib.sha256(data).hexdigest()
def audit(base):
    status=[]
    def record(tag,condition,details=None):status.append({'id':tag,'result':'PASS' if condition else 'FAIL','details':details})
    record('R12_BASE_SHA256',digest(base.read_bytes())==EXPECTED)
    with zipfile.ZipFile(base) as z:
        names=set(z.namelist())
        record('R12_BASE_CRC',z.testzip() is None)
        missing=[];changed=[]
        for n in sorted(names):
            dst=ROOT/n
            if not dst.is_file():missing.append(n)
            elif digest(dst.read_bytes())!=digest(z.read(n)):changed.append(n)
        record('R12_ALL_FILES_PRESERVED',not missing,missing[:15])
        record('R12_SOURCE_CHANGES_CIRURGICAL',set(changed)==ALLOWED_CHANGES,changed)
        original=z.read('convergence/game.gd').decode()
        current=(ROOT/'convergence/game.gd').read_text()
        old='if not restoring_region and not save_progress():generation_failure="save_failed";message'
        record('SAVE_FAILURE_WAS_FALSE_SUCCESS',old in original)
        record('SAVE_FAILURE_NOW_PROPAGATES',old not in current and
            bool(re.search(r'if not restoring_region and not save_progress\(\):\s*\n(?:\t.*\n)+?\t\treturn false',current)))
    settings=(ROOT/'project.godot').read_text()
    record('USER_DATA_NAMESPACE_R13', 'config/custom_user_dir_name="EXO-Murim-Convergencia-03-ALFA-R13-QA"' in settings)
    record('MAIN_SCENE_PRESERVED','run/main_scene="res://convergence/game.tscn"' in settings)
    record('RENDER_COMPAT_PRESERVED','renderer/rendering_method="gl_compatibility"' in settings)
    scan=[];script_count=0;json_count=0;broken=[];shader_count=0
    for p in ROOT.rglob('*'):
        if not p.is_file() or '.godot' in p.parts:continue
        if p.suffix=='.gd':
            script_count+=1
            s=p.read_text(encoding='utf-8-sig',errors='replace')
            lines=s.splitlines()
            has_t=any(re.match(r'^\t+\S',t) for t in lines)
            has_s=any(re.match(r'^ +\S',t) for t in lines)
            if has_t and has_s:broken.append({'file':str(p.relative_to(ROOT)),'error':'mixed indentation'})
            for ref in re.findall(r'preload\([\'\"]res://([^\'\"]+)[\'\"]\)',s):
                if not (ROOT/ref).is_file():scan.append((str(p.relative_to(ROOT)),ref))
        elif p.suffix=='.json':
            try:json.loads(p.read_text(encoding='utf-8'));json_count+=1
            except Exception as e:broken.append({'file':str(p.relative_to(ROOT)),'error':str(e)})
        elif p.suffix=='.gdshader':shader_count+=1
    known={('godot/demo.gd','legacy/exo_state.gd'),('exo_core/module_template/test.gd','exo_core/core.gd')}
    record('ALL_JSON_AND_INDENT_SCANNED',not broken,{'GDScript':script_count,'JSON':json_count,'shaders':shader_count,'issues':broken[:20]})
    record('MISSING_PRELOADS_ONLY_HISTORICAL_LABS',all('godot/demo.gd'==x[0] or 'exo_core/module_template/test.gd'==x[0] for x in scan),scan[:12])
    record('R12_EIGHT_CORRECTED_SCRIPTS_UNMODIFIED',all((ROOT/p).read_bytes()==zipfile.ZipFile(base).read(p) for p in [
        'convergence/region.gd','genesis/settlements/settlement_planner.gd',
        'inventory.gd','cultivation.gd','regional_ecology/director.gd',
        'regional_ecology/rewards.gd','regional_ecology/territories.gd']))
    record('R13_NATIVE_TEST_PREPARED',(ROOT/'convergence/tests/qa_c03_r13_bootstrap_native.gd').is_file())
    result={'kind':'STATIC_SOURCE_AUDIT_NO_GODOT_PARSER','release':'EXO-MURIM-C03-ALFA-R13','checks':status,
            'passed':sum(x['result']=='PASS' for x in status),'failed':sum(x['result']=='FAIL' for x in status),
            'godot_native':'NOT_RUN'}
    (ROOT/'C03_TRANSFERENCIA/QA-C03-ALFA-R13-STATIC.json').write_text(json.dumps(result,indent=2,ensure_ascii=False))
    print(json.dumps(result,indent=2,ensure_ascii=False))
    return 1 if result['failed'] else 0
if __name__=='__main__':
    if len(sys.argv)!=2:sys.exit('Usage: qa_c03_r13_static.py <R12-original.zip>')
    raise SystemExit(audit(pathlib.Path(sys.argv[1])))
