#!/usr/bin/env bash
set -euo pipefail
exo_repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
exo_engine="${GODOT_BIN:-/workspace/tools/godot-4.6.2/Godot_v4.6.2-stable_linux.x86_64}"
if [[ ! -x "$exo_engine" ]]; then
  printf '%s\n' 'Godot 4.6.2 not found. Set GODOT_BIN or run tools/v5/install_godot.sh.' >&2
  exit 1
fi
export XDG_DATA_HOME="${XDG_DATA_HOME:-$exo_repo_dir/.local-runtime/data}"
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$exo_repo_dir/.local-runtime/config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$exo_repo_dir/.local-runtime/cache}"
mkdir -p "$XDG_DATA_HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME"
exec "$exo_engine" --path "$exo_repo_dir" "$@"
