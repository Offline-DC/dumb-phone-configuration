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

echo "Waiting for device... wait for network carrier to register, then when prompted allow USB debugging... if not prompted, restart manually"
adb_do wait-for-device

echo "Installing magisk..."

adb_do install Magisk-v30.7.apk

say "Alert – prepare for permission request on phone."
adb_do shell su -c "/vendor/bin/write_protect 0"

adb_do shell reboot || true

echo "Waiting for device... If taking a while, restart manually"
adb_do wait-for-device

echo "Waiting for sys.boot_completed..."
until adb_do shell 'test "$(getprop sys.boot_completed)" = "1"' >/dev/null 2>&1; do
  sleep 1
done

echo "Waiting for dev.bootcomplete..."
until adb_do shell 'test "$(getprop dev.bootcomplete)" = "1"' >/dev/null 2>&1; do
  sleep 1
done

echo "Waiting for package manager..."
until adb_do shell 'pm path android >/dev/null 2>&1' >/dev/null 2>&1; do
  sleep 1
done

echo "Waiting for sdcard..."
until adb_do shell 'ls /sdcard' >/dev/null 2>&1; do
  sleep 1
done

sleep 5

adb_do shell monkey -p com.topjohnwu.magisk 1 || true

read -p "ACTION REQUIRED: Select OK, then go to Direct Install, then when commands finish, press ENTER"

adb_do shell reboot || true