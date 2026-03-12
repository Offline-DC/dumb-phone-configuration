#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------
# Simple ADB scoping helper
# ---------------------------------------
SERIAL=""
# parse optional --serial argument
while [[ $# -gt 0 ]]; do
  case "$1" in
    --serial)
      SERIAL="$2"
      shift 2
      ;;
    *)
      break
      ;;
  esac
done

adb_do() {
  if [[ -n "$SERIAL" ]]; then
    adb -s "$SERIAL" "$@"
  else
    adb "$@"
  fi
}
# END ADB SCOPING HELPER

echo "Waiting for device... when prompted allow USB debugging..."
adb_do wait-for-device

echo "Installing magisk..."

adb_do install Magisk-v30.7.apk

say "Alert – prepare for permission request on phone."

adb_do shell monkey -p com.topjohnwu.magisk 1

read -p "ACTION REQUIRED: Select OK, then go to Direct Install, then when commands finish, press ENTER"

adb_do shell reboot || true