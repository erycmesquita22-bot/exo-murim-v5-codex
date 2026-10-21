#!/usr/bin/env python3
"""Usage: python3 tools/run_repair_chat_checks.py /path/to/Godot --rendered
Graphical scene observation takes at least 180 seconds; not a benchmark.
"""
import json
import os
from pathlib import Path
import subprocess
import sys

project = Path(__file__).resolve().parents[1]
evidence = project / 'REPARACAO_CHAT_V4' / 'evidence'
evidence.mkdir(parents=True, exist_ok=True)
env = os.environ.copy()
env['EXO_QA_OUT'] = str(evidence / 'after')
results = []

def run(label, arguments, graphical=False, timeout=600):
    command = [sys.argv[1]] + ([] if graphical else ['--headless']) + ['--path', str(project)] + arguments
    try:
        r = subprocess.run(command, capture_output=True, text=True, env=env, timeout=timeout)
        log = r.stdout + r.stderr
        (evidence / (label + '.log')).write_text(log)
        ok = r.returncode == 0 and not any(token in log for token in ['SCRIPT ERROR', 'ERROR:', 'FAIL '])
        status = 'PASS' if ok else 'FAIL'
    except subprocess.TimeoutExpired:
        status = 'FAIL'
    results.append({'test': label, 'status': status})
    print(status, label, flush=True)
    return status == 'PASS'

run('import', ['--editor', '--import'])
for label, script in [
    ('numeric', 'repair_v4/tests/qa_numeric.gd'),
    ('crowd-native', 'exo_crowd_illusion/tests/qa_native.gd'),
    ('crowd-r4', 'exo_crowd_illusion/tests/qa_native_r4.gd'),
]:
    run(label, ['--script', 'res://' + script])
if '--rendered' in sys.argv:
    run('crowd-feet-rendered', ['--audio-driver', 'Dummy', '--script', 'res://exo_crowd_illusion/tests/qa_native.gd'], True)
    if run('scene', ['--audio-driver', 'Dummy', '--max-fps', '15', '--script', 'res://repair_v4/tests/qa_scene.gd'], True, 1200):
        run('reload', ['--script', 'res://repair_v4/tests/qa_reload.gd'])
else:
    results.extend([{'test': 'scene', 'status': 'NOT_RUN'}, {'test': 'reload', 'status': 'NOT_RUN'}])
run('functional', ['--script', 'res://convergence4/tests/qa_functional.gd'])
(evidence / 'runner-results.json').write_text(json.dumps(results, indent=2))
sys.exit(any(row['status'] == 'FAIL' for row in results))
