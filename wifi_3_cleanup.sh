#!/usr/bin/env bash
set -euo pipefail

ADB_PKG="com.android.adbkeyboard"

if [[ -f /tmp/prev_ime.txt ]]; then
  PREV_IME="$(cat /tmp/prev_ime.txt | tr -d '\r')"
  if [[ -n "$PREV_IME" ]]; then
    echo "Restoring previous IME: $PREV_IME"
    adb shell ime set "$PREV_IME" >/dev/null 2>&1 || true
  fi
else
  echo "No /tmp/prev_ime.txt found; skipping IME restore."
fi

echo "Uninstalling ADBKeyboard..."
adb uninstall "$ADB_PKG" >/dev/null 2>&1 || true

echo "Done."
