#!/usr/bin/env bash
set -euo pipefail

BOOT_IMG_ONE="original-boot.img"
BOOT_IMG_FINAL="original-boot-debug.img"

echo
echo "[1/5] Running bootfind.sh to get into fastboot. Make sure phone is turned off and plug it in..."
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

fastboot flashing unlock || true

echo
echo "[3/5] Flashing intermediate image..."
fastboot flash boot "$BOOT_IMG_ONE"

echo
echo "[4/5] Flashing target image..."
fastboot flash boot "$BOOT_IMG_FINAL"

echo "Rebooting..."
fastboot reboot

echo "Let the phone finish booting into Android setup."
echo "Get through initial setup screens"