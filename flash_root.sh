#!/usr/bin/env bash
set -euo pipefail

BOOT_IMG="neutron.img"

echo "== TCL Flip 2: flash_root =="
echo "Using boot image: $BOOT_IMG"
echo

echo "[0/9] Waiting for authorized ADB..."
./adb_wait_authorized.sh

echo
echo "[1/9] Waiting for ADB device..."
adb wait-for-device
adb devices -l

echo "[2/9] Enabling dev settings flag (harmless if already enabled)..."
adb shell settings put global development_settings_enabled 1 || true

echo
echo "[3/9] Powering off phone..."
adb shell reboot -p || true

echo
echo "== ACTION REQUIRED =="
echo "Unplug the phone, wait until it's fully off, then plug it back in."
echo "When plugged in, we will try to enter fastboot using ./bootfind.sh (serial autobooter)."
read -r -p "Press ENTER once the phone is unplugged and fully off. After pressing ENTER, plug your phone back in... " _

echo
echo "[4/9] Running bootfind.sh to get into fastboot. Plug in your phone now after password..."
./bootfind.sh

echo
echo "[5/9] Waiting for FASTBOOT device..."
for _i in {1..60}; do
  if fastboot devices | grep -q .; then
    break
  fi
  sleep 1
done
fastboot devices

echo
echo "[6/9] Unlocking bootloader (will prompt on phone)..."
echo "== ACTION REQUIRED =="
echo "When the prompt appears on the phone, press Volume Up to confirm unlock."
fastboot flashing unlock || true

echo
echo "[7/9] Flashing boot image..."
fastboot flash boot "$BOOT_IMG"

echo
echo "[8/9] Rebooting..."
fastboot reboot

say "flash_root complete."
echo "Let the phone finish booting into Android setup."
echo "Get through initial setup screens, skip wifi, let carrier switch, and wait until you're at the home screen. Then you can continue with the next step."
