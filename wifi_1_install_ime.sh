#!/usr/bin/env bash
set -euo pipefail

./adb_wait_authorized.sh
adb wait-for-device

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
APK_PATH="${SCRIPT_DIR}/ADBKeyboard.apk"

ADB_IME="com.android.adbkeyboard/.AdbIME"
ADB_PKG="com.android.adbkeyboard"

[[ -f "$APK_PATH" ]] || { echo "Missing $APK_PATH"; exit 1; }

echo "Installing ADBKeyboard..."
adb install -r "$APK_PATH"

adb shell am start -a android.settings.INPUT_METHOD_SETTINGS >/dev/null 2>&1 || true
sleep 2

echo "Saving current IME..."
adb shell settings get secure default_input_method | tr -d '\r' > /tmp/prev_ime.txt || true
echo "Previous IME saved to /tmp/prev_ime.txt"

echo "Enabling + setting ADB Keyboard..."
adb shell ime enable "$ADB_IME" || true
adb shell ime set "$ADB_IME" || true

echo "Current IME:"
adb shell settings get secure default_input_method | tr -d '\r'
