#!/usr/bin/env bash
set -euo pipefail

INSTRUCTIONS=${1:-1} # pass 0 to suppress instructions

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing required command: $1"
    exit 1
  }
}

pause() {
  echo
  read -r -p "Press ENTER to retry..." _
}

need_cmd adb

echo "== ADB: waiting for authorized device. To turn on, type *#*#33284#*#* then allow USB debugging on device =="

while true; do
  # Wait until *something* is connected (may still be unauthorized)
  adb wait-for-device >/dev/null 2>&1 || true

  # Grab the first attached device state (handles headers, blanks, etc.)
  # Possible states: device, unauthorized, offline, recovery, sideload, etc.
  ADB_STATE="$(adb devices | awk 'NR>1 && $1!="" {print $2; exit}' | tr -d '\r')"

  if [[ "$ADB_STATE" == "device" ]]; then
    echo "ADB authorized ✔"
    exit 0
  fi

  echo
  echo "ADB not authorized yet (state: ${ADB_STATE:-none})."

  if [[ "$INSTRUCTIONS" == "1" ]]; then
    echo
    echo "== ACTION REQUIRED =="
    echo "On the phone:"
    echo "  1) Dial: *#*#33284#*#*"
    echo "  2) Turn USB Debugging ON"
    echo "  3) Plug into computer"
    echo "  4) Accept the ADB authorization prompt"
  fi

  pause
done
