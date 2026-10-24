#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
if [ -n "${GODOT_BIN:-}" ]; then exec "$GODOT_BIN" --editor --path "$PWD"; fi
if command -v godot >/dev/null 2>&1; then exec godot --editor --path "$PWD"; fi
if command -v godot4 >/dev/null 2>&1; then exec godot4 --editor --path "$PWD"; fi
echo "Godot não encontrada. Informe GODOT_BIN=/caminho/para/Godot_v4.7.2-stable_linux.x86_64" >&2
exit 1
