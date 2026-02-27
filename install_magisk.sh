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

adb_do reboot

echo "Waiting for device... if not working, manually restart"
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

sleep 5
echo "Boot complete."

echo "Installing full Magisk APK from ramdisk..."
MAGISK_PATH=$(adb_do shell magisk --path 2>/dev/null | tr -d '\r')
adb_do shell su -c "pm install -r ${MAGISK_PATH}/Magisk.apk"
echo "Magisk APK installed ✔"

echo
echo "Initiating Magisk setup (follow instructions on screen)"
adb_do shell monkey -p com.topjohnwu.magisk -c android.intent.category.LAUNCHER 1
adb_do shell monkey -p com.topjohnwu.magisk -c android.intent.category.LAUNCHER 1

echo
echo "Waiting for Magisk notification..."

timeout=120
elapsed=0

until adb_do shell dumpsys notification | grep -q "com.topjohnwu.magisk"; do
  sleep 1
  elapsed=$((elapsed + 1))
  if [ "$elapsed" -ge "$timeout" ]; then
    echo "Timed out waiting for Magisk notification"
    adb_do shell monkey -p com.topjohnwu.magisk -c android.intent.category.LAUNCHER 1
    read -p "ERROR – Magisk timed out, manually launching magisk, press ENTER if reached home screen after restart..."
    break
  fi
done

echo "Magisk notification detected — rebooting to complete setup..."
adb_do reboot

echo "Waiting for device to come back up..."
adb_do wait-for-device

echo "Waiting for sys.boot_completed..."
until adb_do shell 'test "$(getprop sys.boot_completed)" = "1"' >/dev/null 2>&1; do
  sleep 1
done

echo "Magisk setup complete ✔"