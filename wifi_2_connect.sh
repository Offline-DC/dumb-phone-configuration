#!/usr/bin/env bash
set -euo pipefail

SSID="${1:-}"
PASS="${2:-}"

if [[ -z "$SSID" || -z "$PASS" ]]; then
  echo 'Usage: ./wifi_2_connect.sh "SSID" "PASSWORD"'
  exit 1
fi

adb_ime_text() {
  local txt="$1"
  txt="${txt//\\/\\\\}"
  txt="${txt//\"/\\\"}"
  adb shell am broadcast -a ADB_INPUT_TEXT --es msg "$txt" >/dev/null
}

echo "Turning Wi-Fi on..."
adb shell svc wifi enable >/dev/null 2>&1 || true
sleep 1

echo "Opening Wi-Fi settings..."
adb shell am start -a android.settings.WIFI_SETTINGS >/dev/null 2>&1 || true

echo
echo "On the phone:"
echo "  1) Tap network: $SSID"
echo "  2) Tap password field so cursor is blinking"
read -r -p "Press ENTER to inject password..." _

echo "Injecting password..."
adb_ime_text "$PASS"

echo
echo "Password injected. Tap OK / Connect on the phone."
