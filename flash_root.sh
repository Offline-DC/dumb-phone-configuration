#!/usr/bin/env bash
set -euo pipefail

BOOT_IMG="neutron.img"

echo "== TCL Flip 2: flash_root =="
echo "Using boot image: $BOOT_IMG"
echo

echo
echo "[1/5] Running bootfind.sh to get into fastboot. Plug in your phone now after password..."
./bootfind.sh

echo
echo "[2/5] Waiting for FASTBOOT device..."
for _i in {1..60}; do
  if fastboot devices | grep -q .; then
    break
  fi
  sleep 1
done
fastboot devices

echo
echo "[3/5] Unlocking bootloader (will prompt on phone)..."
echo "== ACTION REQUIRED =="
echo "When the prompt appears on the phone, press Volume Up to confirm unlock."
fastboot flashing unlock || true

echo
echo "[4/5] Flashing boot image..."
fastboot flash boot "$BOOT_IMG"

echo
echo "[5/5] Rebooting..."
fastboot reboot

say "flash_root complete."
echo "Let the phone finish booting into Android setup."
echo "Get through initial setup screens,
run ./wifi_install.sh "YourSSID" "YourPassword" to set up Wi-Fi, and then 
let carrier switch (if SIM), and wait until you're at the home screen. Then you can continue with the next step."
