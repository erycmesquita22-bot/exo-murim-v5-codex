#!/usr/bin/env python3
"""Run: python tools/run_checks.py /path/to/Godot [--prologue]"""
import pathlib, subprocess, sys
p=pathlib.Path(__file__).resolve().parents[1]
names=['tests','release_qa','discovery_qa','fidelity_qa','consolidation_qa','ruins_martial_qa','assets_qa','stabilization_qa','quality09_qa','martial_qa','procedural_qa','legacy_audio_qa']
if '--prologue' in sys.argv:names.append('war_qa')
logs=p/'logs-validacao';logs.mkdir(exist_ok=True)
failed=[]
for n in names:
 r=subprocess.run([sys.argv[1],'--headless','--path',str(p),'--script',n+'.gd'],capture_output=True,text=True,timeout=130)
 text=r.stdout+r.stderr;(logs/(n+'.log')).write_text(text)
 ok=r.returncode==0 and 'SCRIPT ERROR' not in text and 'ERROR:' not in text and 'FAIL ' not in text
 print(('PASS ' if ok else 'FAIL ')+n)
 if not ok:failed.append(n)
sys.exit(bool(failed))
