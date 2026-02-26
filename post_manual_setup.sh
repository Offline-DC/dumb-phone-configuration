#!/usr/bin/env bash
set -euo pipefail

echo "Waiting for device..."
adb wait-for-device

echo "Waiting for sys.boot_completed..."
until adb shell 'test "$(getprop sys.boot_completed)" = "1"' >/dev/null 2>&1; do
  sleep 1
done

echo "Waiting for dev.bootcomplete..."
until adb shell 'test "$(getprop dev.bootcomplete)" = "1"' >/dev/null 2>&1; do
  sleep 1
done

echo "Waiting for package manager..."
until adb shell 'pm path android >/dev/null 2>&1' >/dev/null 2>&1; do
  sleep 1
done

clear

echo "========================================"
echo " ACTION REQUIRED — Post Launch Setup"
echo "========================================"
echo
read -p "Wait for home screen and press ENTER to begin..."

############################################
# STEP 3 — MAGISK SETTINGS
############################################
clear
echo "STEP 3 — Magisk Settings"
echo
echo "Instructions:"
echo "  0) using mouse, go to settings (gear in top right)"
echo "  1) Change 'Superuser Notification' → NONE"
echo "  2) Turn OFF 'Check Updates'"
echo

adb shell monkey -p com.topjohnwu.magisk -c android.intent.category.LAUNCHER 1

read -p "Complete the changes, then press ENTER to continue..."


############################################
# STEP 2 — OPENBUBBLES SETUP
############################################
clear
echo "STEP 2 — OpenBubbles Setup"
echo
echo "Instructions:"
echo "  • Go through initial setup"
echo "  • Scan the Mac QR code"
echo

adb shell monkey -p com.openbubbles.messaging -c android.intent.category.LAUNCHER 1

read -p "Finish setup, then press ENTER to continue..."

############################################
# STEP 1 — DISABLE FOREGROUND SERVICE NOTIFICATION
############################################
clear
echo "STEP 1 — Disable Foreground Service Notification"
echo
echo "Instructions:"
echo "  • Locate 'Foreground Service'"
echo "  • Turn OFF notifications manually"
echo

adb shell am start \
  -a android.settings.CHANNEL_NOTIFICATION_SETTINGS \
  --es android.provider.extra.APP_PACKAGE com.openbubbles.messaging \
  --es android.provider.extra.CHANNEL_ID com.bluebubbles.foreground_service

read -p "After disabling it, press ENTER to continue..."

############################################
# STEP 4 — FINAL TEST
############################################
clear
echo "STEP 4 — Retest"
echo
echo "Verify everything works!!!"
echo

read -p "Press ENTER when finished..."

echo
echo "✅ Setup Complete."
echo
adb shell reboot -p