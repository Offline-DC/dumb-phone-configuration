#!/usr/bin/env bash
set -euo pipefail

SERIAL="${1:-}"
VERSION="${2:-}"

[[ -n "$SERIAL" ]] || { echo "Usage: $0 <SERIAL> <VERSION>" >&2; exit 2; }
[[ -n "$VERSION" ]] || { echo "Usage: $0 <SERIAL> <VERSION>" >&2; exit 2; }

CWD="$(pwd)"
CMD="./per_device_pipeline.sh --version \"$VERSION\" --serial \"$SERIAL\""

if [[ "$OSTYPE" == "darwin"* ]]; then
  ESCAPED=$(printf '%s' "cd \"$CWD\" && bash -lc '$CMD'" | sed 's/\\/\\\\/g; s/"/\\"/g')

  osascript <<EOF
tell application "Terminal"
  activate
  do script "$ESCAPED"
end tell
EOF
else
  if command -v gnome-terminal >/dev/null 2>&1; then
    gnome-terminal -- bash -lc "cd \"$CWD\" && $CMD" &
  elif command -v konsole >/dev/null 2>&1; then
    konsole -e bash -lc "cd \"$CWD\" && $CMD" &
  elif command -v x-terminal-emulator >/dev/null 2>&1; then
    x-terminal-emulator -e bash -lc "cd \"$CWD\" && $CMD" &
  else
    xterm -e bash -lc "cd \"$CWD\" && $CMD" &
  fi
fi