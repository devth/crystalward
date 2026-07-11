#!/usr/bin/env bash
# Launch Crystalward with a clear process context.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GODOT="${GODOT:-}"
if [[ -z "$GODOT" ]]; then
  if command -v godot >/dev/null 2>&1; then
    GODOT="$(command -v godot)"
  elif [[ -x "/Applications/Godot.app/Contents/MacOS/Godot" ]]; then
    GODOT="/Applications/Godot.app/Contents/MacOS/Godot"
  elif [[ -x "/opt/homebrew/bin/godot" ]]; then
    GODOT="/opt/homebrew/bin/godot"
  else
    echo "Crystalward: could not find Godot. Install Godot 4 or set GODOT=..." >&2
    exit 1
  fi
fi
# Window title is set in-engine; this is the project runner.
exec "$GODOT" --path "$ROOT" "$@"
