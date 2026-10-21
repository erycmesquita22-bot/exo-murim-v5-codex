#!/usr/bin/env bash
set -euo pipefail
exo_tool_dir="${EXO_GODOT_DIR:-/workspace/tools/godot-4.6.2}"
mkdir -p "$exo_tool_dir"
exo_archive=Godot_v4.6.2-stable_linux.x86_64.zip
exo_engine="$exo_tool_dir/Godot_v4.6.2-stable_linux.x86_64"
if [[ -x "$exo_engine" ]] && [[ "$("$exo_engine" --version 2>/dev/null)" == 4.6.2.stable.official.* ]]; then
  printf '%s\n' "$exo_engine"
  exit 0
fi
curl -fL --retry 2 "https://github.com/godotengine/godot-builds/releases/download/4.6.2-stable/$exo_archive" -o "$exo_tool_dir/$exo_archive"
curl -fL --retry 2 'https://github.com/godotengine/godot-builds/releases/download/4.6.2-stable/SHA512-SUMS.txt' -o "$exo_tool_dir/SHA512-SUMS.txt"
python3 - "$exo_tool_dir" "$exo_archive" <<'PY'
import hashlib,pathlib,sys,zipfile
p=pathlib.Path(sys.argv[1]);name=sys.argv[2]
expected=next(line.split()[0] for line in (p/'SHA512-SUMS.txt').read_text().splitlines() if line.endswith(name))
if hashlib.sha512((p/name).read_bytes()).hexdigest()!=expected:raise SystemExit('Official SHA512 verification FAILED')
with zipfile.ZipFile(p/name) as z:z.extractall(p)
(p/'Godot_v4.6.2-stable_linux.x86_64').chmod(0o755)
PY
"$exo_engine" --version
