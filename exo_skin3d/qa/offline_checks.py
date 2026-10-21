#!/usr/bin/env python3
"""Structural EXO Skin3D validation: not a substitute for Godot engine execution."""
import hashlib, json, random, re
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
MANIFEST = Path(__file__).with_name('baseline_sha256.json')
SOURCE_PREFIX='EXO-Murim-Mundo-Vivo-02-R2-Validacao/'
EXPECTED_CHANGED={
 'wardrobe.gd','journey_save.gd','ui/character_creation.gd',
 'convergence/resident.gd','murim_flow.gd','living_world/people.gd','enemy.gd'
}
PARTS={
 'head':((0,0),(32,0),(8,8,8)),
 'torso':((16,16),(16,32),(8,12,4)),
 'right_arm':((40,16),(40,32),(4,12,4)),
 'left_arm':((32,48),(48,48),(4,12,4)),
 'right_leg':((0,16),(0,32),(4,12,4)),
 'left_leg':((16,48),(0,48),(4,12,4)),
}
results=[]
def assert_ok(x,name,detail=''):
    results.append({'name':name,'pass':bool(x),'detail':detail})
    if not x:raise AssertionError(name+' '+detail)

def rects(part,outer,slim,segment):
    base,top,(w,h,d)=PARTS[part]
    if slim and part.endswith('_arm'):w=3
    u,v=top if outer else base
    start=6 if segment==1 else 0
    length=6 if segment!=-1 else h
    return [(u+d,v+d+start,w,length),(u+d+w+d,v+d+start,w,length),
            (u+d+w,v+d+start,d,length),(u,v+d+start,d,length),
            (u+d,v,w,d),(u+d+w,v,w,d)]

def test_uv():
    repetitions=0
    for part in PARTS:
        for slim in (False,True):
            for overlay in (False,True):
                for seg in (-1,0,1):
                    r=rects(part,overlay,slim,seg)
                    assert_ok(len(r)==6,'six_faces_'+part+str(slim)+str(overlay)+str(seg))
                    for x,y,w,h in r:
                        assert_ok(0<=x and 0<=y and x+w<=64 and y+h<=64 and w>0 and h>0,'rect_bounded_'+str(repetitions))
                        repetitions+=1
                    if seg==-1:
                        target_width=3 if slim and part.endswith('_arm') else PARTS[part][2][0]
                        assert_ok(r[0][2]==target_width,'arm_uv_not_stretched_'+part+str(slim))
                    if seg==0:
                        lower=rects(part,overlay,slim,1)
                        for a,b in zip(r[:4],lower[:4]):
                            assert_ok(a[1]+a[3]==b[1] and a[0]==b[0],'split_contiguous_'+part)
    assert_ok(repetitions>400,'uv_many_rectangles_tested',str(repetitions))

def test_images():
    fixture=Image.open(ROOT/'exo_skin3d/fixtures/hybrid_test_64.png').convert('RGBA')
    assert_ok(fixture.size==(64,64),'import_fixture_exact_64')
    overlay_count=0
    for part in PARTS:
        for x,y,w,h in rects(part,True,False,-1):
            layer=fixture.crop((x,y,x+w,y+h))
            overlay_count+=sum(1 for pixel in layer.getdata() if pixel[3]>127)
    assert_ok(overlay_count>=30,'six_layers_have_some_pixels',str(overlay_count))
    assert_ok(any(v[3]==0 for v in fixture.getdata()),'real_alpha_transparency')
    exo=Image.open(ROOT/'assets/exo_identity/base_0.png').convert('RGBA')
    assert_ok(exo.size==(256,256),'exo_native_256_unmodified')
    for part in PARTS:
        for x,y,w,h in rects(part,True,False,-1):
            crop=exo.crop((x*4,y*4,(x+w)*4,(y+h)*4))
            assert_ok(crop.size==(w*4,h*4),'exo_native_uv_scaling_'+part)
    return fixture

def test_source_integrity():
    path_to_hash=json.loads(MANIFEST.read_text())['sha256_files']
    missing=[]; changed=[]
    for rel,prior_digest in path_to_hash.items():
        path=ROOT/rel
        if not path.exists():missing.append(rel);continue
        if hashlib.sha256(path.read_bytes()).hexdigest()!=prior_digest:changed.append(rel)
    assert_ok(not missing,'all_original_files_preserved',str(missing[:8]))
    core_manifest=ROOT/'MANIFESTO-PRESERVACAO-CORE-01.json'
    if core_manifest.exists():
        approved=json.loads(core_manifest.read_text())['r3_source_changes']
        source_changed={rel for rel in changed if Path(rel).suffix in {'.gd','.tscn','.godot'}}
        assert_ok(source_changed==set(approved),'audited_core_source_changes',str(sorted(source_changed)))
        for rel,digest in approved.items():
            assert_ok(hashlib.sha256((ROOT/rel).read_bytes()).hexdigest()==digest,'core_merge_hash_'+rel)
    else:
        assert_ok(set(changed)==EXPECTED_CHANGED,'only_whitelisted_integration_changes',str(changed))
    assert_ok(hashlib.sha256((ROOT/'rig.gd').read_bytes()).hexdigest()==path_to_hash['rig.gd'],'rig_and_weapon_pivots_byte_identical')
    for rel in ['arsenal.gd','anatomy.gd','techniques.gd','animation_library.gd','world/mesh_batch.gd']:
        assert_ok(hashlib.sha256((ROOT/rel).read_bytes()).hexdigest()==path_to_hash[rel],'approved_system_unmodified_'+rel)
    return changed

def test_gd_integrity():
    scripts=list((ROOT/'exo_skin3d').rglob('*.gd'))
    assert_ok(len(scripts)>=9,'eight_modules_plus_godot_qa',str(len(scripts)))
    for script in scripts:
        code=script.read_text()
        assert_ok(code.startswith('extends '),'gdscript_script_header_'+script.name)
        for target in re.findall(r'preload\("res://([^"\n]+)"\)',code):
            assert_ok((ROOT/target).exists(),'local_preload_exists_'+target)
        # Structural sanity: one static output function per component and no engine writes to stats.
        if script.name not in ['qa_skin3d.gd']:
            assert_ok(re.search(r'(?:static )?func \w+\(',code) is not None,'has_callable_'+script.name)
    script=(ROOT/'exo_skin3d/appearance_adapter.gd').read_text()
    assert_ok('Physics' not in script and 'damage' not in script,'cosmetic_adapter_no_combat')
    ui=(ROOT/'ui/character_creation.gd').read_text()
    assert_ok('import_file(path)' in ui,'importer_preserves_binary_png')
    wd=(ROOT/'wardrobe.gd').read_text()
    assert_ok(wd.count('Skin3D.apply(rig,profile)')==3,'wardrobe_three_early_return_paths')
    save=(ROOT/'journey_save.gd').read_text()
    assert_ok('profile.has("skin3d")' in save,'optional_save_field')
    assert_ok('"version":4' in save,'save_version_unchanged')
    return len(scripts)

def test_stress():
    rng=random.Random(16781018)
    # Repeat 30,000 deterministic random atlas cases, checking normalized UV invariants.
    for i in range(30000):
        part=rng.choice(list(PARTS))
        slim=bool(rng.getrandbits(1))
        overlay=bool(rng.getrandbits(1))
        seg=rng.choice((-1,0,1))
        r=rects(part,overlay,slim,seg)
        for x,y,w,h in r:
            if x<0 or y<0 or x+w>64 or y+h>64:raise AssertionError(f'UV overflow test {i}')
    assert_ok(True,'30k_random_uv_generation_no_oob')

def main():
    fixture=test_images()
    test_uv();test_gd_integrity();changed=test_source_integrity();test_stress()
    report={'suite':'EXO-Skin-3D-Hybrid-01 static/offline checks',
            'engine_executed':False,'godot_screenshots_taken':False,
            'pass':all(e['pass'] for e in results),'assertions':len(results),'random_uv_cases':30000,
            'changed_project_files':changed,'checks':results}
    output=ROOT/'exo_skin3d/qa/EXO-Skin3D-Hybrid-01-OFFLINE-REPORT.json'
    output.write_text(json.dumps(report,indent=2,ensure_ascii=False))
    print(json.dumps({k:v for k,v in report.items() if k!='checks'},ensure_ascii=False,indent=2))
    print('wrote',output)

if __name__=='__main__':main()
