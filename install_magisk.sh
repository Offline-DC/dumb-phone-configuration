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

echo "Waiting for device..."
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

echo
echo "Initiating Magisk setup (follow instructions on screen)"
adb_do shell monkey -p com.topjohnwu.magisk -c android.intent.category.LAUNCHER 1
adb_do shell monkey -p com.topjohnwu.magisk -c android.intent.category.LAUNCHER 1

echo
echo "Waiting for Magisk notification..."

timeout=60
elapsed=0

until adb_do shell dumpsys notification | grep -q "com.topjohnwu.magisk"; do
  sleep 1
  elapsed=$((elapsed + 1))
  if [ "$elapsed" -ge "$timeout" ]; then
    echo "Timed out waiting for Magisk notification"
    break
  fi
done

echo "Magisk notification detected. Continuing..."

echo "Follow final setup command and reboot via Magisk UI"
adb_do shell monkey -p com.topjohnwu.magisk -c android.intent.category.LAUNCHER 1

echo
echo "Complete setup on the device."
echo "Waiting for Magisk reboot..."

WAIT_TIMEOUT=60
START_TIME=$(date +%s)

while true; do
    # check if adb is gone (device disconnected)
    if ! adb_do get-state >/dev/null 2>&1; then
        echo "Device disconnected ✔"
        break
    fi

    NOW=$(date +%s)
    ELAPSED=$((NOW - START_TIME))

    if [ "$ELAPSED" -ge "$WAIT_TIMEOUT" ]; then
        echo "No reboot detected after ${WAIT_TIMEOUT}s — launching Magisk manually..."
        adb_do shell monkey -p com.topjohnwu.magisk -c android.intent.category.LAUNCHER 1
        break
    fi

    sleep 1
done