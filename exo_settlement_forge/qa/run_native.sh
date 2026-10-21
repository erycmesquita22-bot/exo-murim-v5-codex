#!/usr/bin/env bash
set -o pipefail
GODOT_BIN="${GODOT_BIN:-godot}"
if ! command -v "$GODOT_BIN" >/dev/null 2>&1; then
  echo "BLOCKED: Godot 4.6.2 binary not found: $GODOT_BIN" >&2
  exit 127
fi
"$GODOT_BIN" --version
"$GODOT_BIN" --headless --editor --path "$(cd "$(dirname "$0")/../.." && pwd)" --import || exit $?
"$GODOT_BIN" --headless --path "$(cd "$(dirname "$0")/../.." && pwd)" --script res://exo_settlement_forge/qa/native_smoke.gd
