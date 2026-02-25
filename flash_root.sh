#!/usr/bin/env bash
set -euo pipefail

SERIAL=""
BOOT_IMG_ONE="original-boot.img"
BOOT_IMG_FINAL="original-boot-debug.img"
MAX_WAIT=90
FLASH_RETRIES=5

while [[ $# -gt 0 ]]; do
  case "$1" in
    --serial) SERIAL="${2:-}"; shift 2;;
    --boot-one) BOOT_IMG_ONE="${2:-}"; shift 2;;
    --boot-final) BOOT_IMG_FINAL="${2:-}"; shift 2;;
    *) echo "Usage: $0 --serial <SERIAL> [--boot-one IMG] [--boot-final IMG]" >&2; exit 2;;
  esac
done

[[ -n "$SERIAL" ]] || { echo "Error: --serial required" >&2; exit 1; }

fb() { fastboot -s "$SERIAL" "$@"; }

wait_fastboot() {
  echo "Waiting for fastboot serial=$SERIAL ..."
  for _i in $(seq 1 "$MAX_WAIT"); do
    if fastboot devices | awk '$1=="'"$SERIAL"'" && $2=="fastboot" {found=1} END{exit !found}'; then
      # sanity: confirm we can talk to it
      if fb getvar product >/dev/null 2>&1; then
        echo "Fastboot OK for $SERIAL"
        return 0
      fi
    fi
    sleep 1
  done
  echo "ERROR: $SERIAL not ready in fastboot after ${MAX_WAIT}s" >&2
  return 1
}

flash_retry() {
  local part="$1"
  local img="$2"
  for attempt in $(seq 1 "$FLASH_RETRIES"); do
    echo "fastboot flash $part $img (attempt $attempt/$FLASH_RETRIES)"
    if fb flash "$part" "$img"; then
      return 0
    fi
    echo "WARN: flash failed; retrying after re-checking fastboot link..." >&2
    sleep 1
    wait_fastboot
  done
  echo "ERROR: failed to flash $part after retries" >&2
  return 1
}

echo "== fastboot_flash_root =="
echo "SERIAL=$SERIAL"
echo "BOOT_IMG_ONE=$BOOT_IMG_ONE"
echo "BOOT_IMG_FINAL=$BOOT_IMG_FINAL"

wait_fastboot

# Best-effort unlock (don’t fail if already unlocked)
fb flashing unlock >/dev/null 2>&1 || true

# IMPORTANT: two flashes back-to-back, no reboot between
echo "Flash #1: boot <- $BOOT_IMG_ONE"
flash_retry boot "$BOOT_IMG_ONE"

echo "Flash #2: boot <- $BOOT_IMG_FINAL"
flash_retry boot "$BOOT_IMG_FINAL"

echo "Rebooting device..."
fb reboot

echo "Fastboot stage done for $SERIAL"