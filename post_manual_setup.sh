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

clear

echo "========================================"
echo " ACTION REQUIRED — Post Launch Setup"
echo "========================================"
echo
read -p "Wait for home screen and press ENTER to begin..."

############################################
# STEP — MAGISK SETTINGS
############################################
clear
echo "STEP — Magisk Settings"
echo
echo "Instructions:"
echo "  0) using mouse, go to settings (gear in top right)"
echo "  1) Change 'Superuser Notification' → NONE"
echo "  2) Turn OFF 'Check Updates'"
echo

adb_do shell monkey -p com.topjohnwu.magisk -c android.intent.category.LAUNCHER 1

read -p "Complete the changes, then press ENTER to continue..."

############################################
# STEP — OPENBUBBLES SETUP
############################################
clear
echo "STEP — OpenBubbles Setup"
echo
echo "Instructions:"
echo "  • Go through initial setup"
echo "  • Scan the Mac QR code"
echo

adb_do shell monkey -p com.openbubbles.messaging -c android.intent.category.LAUNCHER 1

read -p "Finish setup, then press ENTER to continue..."


############################################
# STEP — DISABLE FOREGROUND SERVICE NOTIFICATION
############################################
clear
echo "STEP — Disable Foreground Service Notification"
echo
echo "Instructions:"
echo "  • Locate 'Foreground Service'"
echo "  • Turn OFF notifications manually"
echo

adb_do shell am start \
  -a android.settings.CHANNEL_NOTIFICATION_SETTINGS \
  --es android.provider.extra.APP_PACKAGE com.openbubbles.messaging \
  --es android.provider.extra.CHANNEL_ID com.bluebubbles.foreground_service

read -p "After disabling it, press ENTER to continue..."

############################################
# STEP — FINAL TEST
############################################
clear
echo "STEP — Retest"
echo
echo "Verify everything works!!!"
echo

read -p "Press ENTER when finished..."

echo
echo "✅ Setup Complete."
echo

adb_do shell reboot -p
exit