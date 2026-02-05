#!/usr/bin/env bash
set -euo pipefail

ZIP_PATH="tclprovision.zip"

echo "== TCL Flip 2: finish_magisk =="
echo "Provisioner zip: $ZIP_PATH"
echo

echo "[0/9] Waiting for authorized ADB..."
./adb_wait_authorized.sh

echo
echo "[1/9] Performing extra reboot to ensure Magisk is fully initialized..."
adb reboot

echo "[2/9] Waiting for device to boot again..."
adb wait-for-device

echo "[3/9] Waiting for Android boot_completed..."
until adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r' | grep -q "^1$"; do
  sleep 2
done
echo "boot_completed=1"

echo
echo "== ACTION REQUIRED =="
echo "Finish any Android setup screens on the phone."
echo
read -r -p "Press ENTER once you are fully at the home screen... " _

MAGISK_PKG=$(adb shell pm list packages | grep -i magisk | head -n1 | cut -d: -f2 | tr -d '\r')

if [[ -n "$MAGISK_PKG" ]]; then
  echo "Launching Magisk app: $MAGISK_PKG"
  adb shell monkey -p "$MAGISK_PKG" -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1 || true
else
  echo "Could not auto-detect Magisk package. Please open Magisk manually."
fi

echo
echo "== ACTION REQUIRED =="
echo "On the phone:"
echo "  • Complete any Magisk setup steps"
echo "  • WAIT for notification that confirms install is done"
echo "  • Tap notification and follow instructions to reboot"
echo
read -r -p "Press ENTER once Magisk setup is finished and reboot is done, and you're back on the home screen again" _

echo
echo "[5/9] Waiting for device after Magisk reboot..."
adb wait-for-device

echo "[6/9] Waiting for boot_completed again..."
until adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r' | grep -q "^1$"; do
  sleep 2
done
echo "boot_completed=1"

echo
echo "[7/9] Verifying root... Press GRANT to allow Magisk to have root access"
if ! adb shell su -c 'id' | grep -q "uid=0"; then
  echo "Root still not available."
  echo "Open Magisk on the phone, approve prompts, reboot once, then re-run this script."
  exit 1
fi
echo "Root OK."

echo
echo "[8/9] Installing provisioning module, please wait..."
adb push "$ZIP_PATH" /sdcard/ >/dev/null
adb shell su -c "magisk --install-module /sdcard/$(basename "$ZIP_PATH")"

echo
echo "[9/9] Rebooting to activate module..."
adb reboot

echo "Done. After boot: Run final step."
