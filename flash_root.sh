#!/usr/bin/env bash
set -euo pipefail

BOOT_IMG="${1:-neutron.img}"

echo "== TCL Flip 2: flash_root =="
echo "Using boot image: $BOOT_IMG"
echo

echo "[0/9] Checking ADB connection status..."
adb wait-for-device || true

ADB_STATE=$(adb devices | awk 'NR==2 {print $2}')

if [[ "$ADB_STATE" != "device" ]]; then
  echo
  echo "== ACTION REQUIRED =="
  echo "Developer access is not currently authorized."
  echo "On the phone:"
  echo "  Dial *#*#33284#*#*"
  echo "  Turn USB Debugging ON"
  echo "  Accept the ADB authorization prompt"
  echo
  read -r -p "Press ENTER once USB debugging is enabled and authorized... " _
  adb wait-for-device
else
  echo "ADB already authorized ✔"
fi

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

echo
echo "[9/9] Done. Let the phone boot to Android setup."
echo "Next: run ./finish_magisk.sh"
