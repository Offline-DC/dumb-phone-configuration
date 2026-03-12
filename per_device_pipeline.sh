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
./install_magisk.sh --serial "$SERIAL"
./add_modules.sh --serial "$SERIAL"
./add_apks.sh --serial "$SERIAL"
./automated_configuration.sh --serial "$SERIAL"
./post_manual_setup.sh --serial "$SERIAL"

echo "Finished setup for $SERIAL"