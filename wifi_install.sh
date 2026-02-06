#!/usr/bin/env bash
set -euo pipefail

./adb_wait_authorized.sh
adb wait-for-device

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
APK_PATH="${SCRIPT_DIR}/ADBKeyboard.apk"

ADB_PKG="com.android.adbkeyboard"
ADB_IME_DEFAULT="com.android.adbkeyboard/.AdbIME"

[[ -f "$APK_PATH" ]] || { echo "Missing $APK_PATH"; exit 1; }

say(){ echo; echo "==> $*"; }

wait_for_ime_registered() {
  local pkg="$1"
  local tries="${2:-25}" # seconds
  for _ in $(seq 1 "$tries"); do
    if adb shell ime list -a 2>/dev/null | tr -d '\r' | grep -q "$pkg"; then
      return 0
    fi
    sleep 1
  done
  return 1
}

# Pull the actual component string from `ime list -a`.
# Typical lines look like: "mId=com.android.adbkeyboard/.AdbIME"
detect_ime_component_from_list() {
  local pkg="$1"
  local comp=""

  comp="$(adb shell ime list -a 2>/dev/null \
    | tr -d '\r' \
    | sed -nE "s/.*mId=(${pkg}\/[^[:space:]]+).*/\1/p" \
    | head -n 1)"

  if [[ -n "$comp" ]]; then
    echo "$comp"
  else
    echo "$ADB_IME_DEFAULT"
  fi
}

enable_and_set_ime_with_retry() {
  local ime="$1"
  local tries="${2:-12}"

  for _ in $(seq 1 "$tries"); do
    adb shell ime enable "$ime" >/dev/null 2>&1 || true
    adb shell ime set "$ime"    >/dev/null 2>&1 || true

    local cur
    cur="$(adb shell settings get secure default_input_method 2>/dev/null | tr -d '\r' || true)"
    if [[ "$cur" == "$ime" ]]; then
      return 0
    fi
    sleep 1
  done
  return 1
}

say "Installing ADBKeyboard..."
adb install -r "$APK_PATH"

say "Waiting for IME to fully register (up to ~25s)..."
if ! wait_for_ime_registered "$ADB_PKG" 25; then
  echo "ERROR: $ADB_PKG did not appear in 'ime list -a' after waiting." >&2
  echo "ime list -a output:" >&2
  adb shell ime list -a 2>/dev/null | tr -d '\r' >&2 || true
  exit 1
fi

ADB_IME="$(detect_ime_component_from_list "$ADB_PKG")"
say "Using IME component: $ADB_IME"

adb shell am start -a android.settings.INPUT_METHOD_SETTINGS >/dev/null 2>&1 || true
say "Waiting for settings UI..."
sleep 3

say "Saving current IME..."
adb shell settings get secure default_input_method | tr -d '\r' > /tmp/prev_ime.txt || true
echo "Previous IME saved to /tmp/prev_ime.txt"

say "Enabling + setting ADB Keyboard (with retries)..."
if ! enable_and_set_ime_with_retry "$ADB_IME" 15; then
  echo "ERROR: Could not enable/set IME: $ADB_IME" >&2
  echo "Current IME: $(adb shell settings get secure default_input_method 2>/dev/null | tr -d '\r' || true)" >&2
  echo "Available IMEs:" >&2
  adb shell ime list -a 2>/dev/null | tr -d '\r' >&2 || true
  exit 1
fi

say "Current IME:"
adb shell settings get secure default_input_method | tr -d '\r'
echo "Make sure ADB keyboard is the only one selected"

SSID="${1:-}"
PASS="${2:-}"

if [[ -z "$SSID" || -z "$PASS" ]]; then
  echo 'Usage: ./wifi_connect.sh "SSID" "PASSWORD"'
  exit 1
fi

adb_ime_text() {
  local txt="${1-}"
  [[ -n "$txt" ]] || { echo "ERROR: password text is empty" >&2; exit 1; }

  # Safely single-quote for the device shell: abc'def -> abc'\''def
  local safe="${txt//\'/\'\\\'\'}"
  adb shell "am broadcast -a ADB_INPUT_TEXT --es msg '$safe'" >/dev/null
}

say "Turning Wi-Fi on..."
adb shell svc wifi enable >/dev/null 2>&1 || true
sleep 1

say "Opening Wi-Fi settings..."
adb shell am start -a android.settings.WIFI_SETTINGS >/dev/null 2>&1 || true

echo
echo "On the phone:"
echo "  1) Tap network: $SSID"
echo "  2) Tap password field so cursor is blinking"
read -r -p "Press ENTER to inject password (make sure ADB Keyboard is on at the bottom)..." _

say "Injecting password..."
adb_ime_text "$PASS"

echo
echo "Password injected. Tap OK / Connect on the phone."

# --- Cleanup / restore ---
if [[ -f /tmp/prev_ime.txt ]]; then
  PREV_IME="$(cat /tmp/prev_ime.txt | tr -d '\r')"
  if [[ -n "$PREV_IME" ]]; then
    say "Restoring previous IME: $PREV_IME"
    adb shell ime set "$PREV_IME" >/dev/null 2>&1 || true
  fi
else
  echo "No /tmp/prev_ime.txt found; skipping IME restore."
fi

say "Uninstalling ADBKeyboard..."
adb uninstall "$ADB_PKG" >/dev/null 2>&1 || true

say "Done."
