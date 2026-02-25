#!/usr/bin/env bash
set -euo pipefail

SERIAL=""
VERSION=""

# -----------------------------
# Parse flags
# -----------------------------
while [[ $# -gt 0 ]]; do
  case "$1" in
    --serial)
      SERIAL="${2:-}"
      [[ -n "$SERIAL" ]] || {
        echo "Error: --serial requires a value." >&2
        exit 1
      }
      shift 2
      ;;
    --version)
      VERSION="${2:-}"
      [[ -n "$VERSION" ]] || {
        echo "Error: --version requires a value." >&2
        exit 1
      }
      shift 2
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 2
      ;;
  esac
done

# -----------------------------
# Validate inputs
# -----------------------------
if [[ -z "$SERIAL" ]]; then
  echo "Error: --serial is required"
  exit 1
fi

if [[ -z "$VERSION" ]]; then
  echo "Error: --version is required"
  exit 1
fi

./flash_root.sh --serial "$SERIAL"

# (B) ADB stage:
echo "Waiting for ADB device $SERIAL... If this hangs here and doesn't continue then unplug and redo again..."
adb -s "$SERIAL" wait-for-device

STATE="$(adb -s "$SERIAL" get-state 2>/dev/null || true)"
if [[ "$STATE" != "device" ]]; then
  echo "NOTE: adb state is '$STATE'. If unauthorized, approve USB debugging on device." >&2
fi

./wifi_install.sh --serial "$SERIAL"
./install_magisk.sh --serial "$SERIAL"
./add_modules.sh --serial "$SERIAL"
./add_apks.sh --serial "$SERIAL"
./automated_configuration.sh --serial "$SERIAL"
./post_manual_setup.sh --serial "$SERIAL"

echo "Finished setup for $SERIAL"