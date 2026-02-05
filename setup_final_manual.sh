#!/usr/bin/env bash
set -euo pipefail

ZIP_NAME="FlipMouse.zip"
ZIP_LOCAL_PATH="./${ZIP_NAME}"
ZIP_REMOTE_PATH="/sdcard/Download/${ZIP_NAME}"

OPENBUBBLES_PKG="com.openbubbles.messaging"
STOCK_LAUNCHER_PKG="com.android.launcher3"

# ------------------------
# Helpers
# ------------------------
pause() {
  echo
  read -r -p "Press ENTER to continue..." _
}

say() {
  echo
  echo "==> $*"
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing required command: $1"
    exit 1
  }
}

pkg_installed() {
  local pkg="$1"
  adb shell pm list packages 2>/dev/null | tr -d '\r' | grep -q "^package:${pkg}$"
}

wait_for_boot_completed() {
  # TCL / low-end Android: adb can be up before Android is actually ready
  local tries="${1:-90}"
  for ((i=1; i<=tries; i++)); do
    local bc
    bc="$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r' || true)"
    if [[ "$bc" == "1" ]]; then
      # extra beat for SystemUI/Home to settle
      sleep 2
      return 0
    fi
    sleep 1
  done
  echo "WARNING: sys.boot_completed not reported after ${tries}s; continuing anyway."
  return 0
}

start_home() {
  # Reduce race with Launcher3 being in foreground
  adb shell am force-stop "${STOCK_LAUNCHER_PKG}" >/dev/null 2>&1 || true
  adb shell am start -a android.intent.action.MAIN -c android.intent.category.HOME >/dev/null 2>&1 || true
}

# ------------------------
# Start
# ------------------------
need_cmd adb

say "Checking adb device connection..."
adb devices

say "Waiting for device..."
adb wait-for-device >/dev/null 2>&1 || true

say "Waiting for Android boot to complete..."
wait_for_boot_completed 90

say "Opening HOME (launcher)"
start_home
pause

# ------------------------
# Set default launcher
# ------------------------
say "Opening Home settings so you can choose default launcher"
adb shell am start -a android.settings.HOME_SETTINGS >/dev/null 2>&1 || true
echo "On the phone: set your launcher (e.g., Mini List Launcher / DumbDown) as DEFAULT."
pause

# ------------------------
# Notification listener access
# ------------------------
say "Opening Notification Listener settings"
adb shell am start -a android.settings.ACTION_NOTIFICATION_LISTENER_SETTINGS >/dev/null 2>&1 || true
echo "On the phone: enable notification access for your launcher as needed."
pause

# ------------------------
# Disable stock launcher (only after default is set)
# ------------------------
say "Disabling stock launcher: ${STOCK_LAUNCHER_PKG}"
if pkg_installed "${STOCK_LAUNCHER_PKG}"; then
  if adb shell pm disable-user --user 0 "${STOCK_LAUNCHER_PKG}" >/dev/null 2>&1; then
    echo "Disabled ${STOCK_LAUNCHER_PKG} ✔"
  else
    echo "FAILED to disable ${STOCK_LAUNCHER_PKG} (continuing)"
  fi
else
  echo "Stock launcher package not found (${STOCK_LAUNCHER_PKG}); skipping."
fi

# ------------------------
# Magisk module install (FlipMouse.zip)
# ------------------------
if [[ -f "${ZIP_LOCAL_PATH}" ]]; then
  say "Pushing ${ZIP_NAME} to /sdcard/Download/"
  adb push "${ZIP_LOCAL_PATH}" "/sdcard/Download/" >/dev/null

  say "Installing Magisk module (requires root/su on device)..."
  # Check if su exists
  if adb shell command -v su >/dev/null 2>&1; then
    # Check if magisk binary exists (it should if Magisk is installed)
    if adb shell su -c 'command -v magisk >/dev/null 2>&1' >/dev/null 2>&1; then
      if adb shell su -c "magisk --install-module '${ZIP_REMOTE_PATH}'" ; then
        echo "Magisk module install ran ✔"
        say "Rebooting device..."
        adb reboot
        say "Waiting for device to come back..."
        adb wait-for-device >/dev/null 2>&1 || true
        say "Waiting for Android boot to complete..."
        wait_for_boot_completed 90
      else
        echo "Magisk install command failed."
        echo "Try manually:"
        echo "  adb shell su -c \"magisk --install-module '${ZIP_REMOTE_PATH}'\""
        echo "  adb reboot"
      fi
    else
      echo "Magisk binary not found under su. Is Magisk installed?"
      echo "Try manually in adb shell:"
      echo "  su"
      echo "  magisk --install-module '${ZIP_REMOTE_PATH}'"
    fi
  else
    echo "su not available on device; skipping automated Magisk install."
    echo "You can install manually inside Magisk app: Modules -> Install from storage -> ${ZIP_NAME}"
  fi
else
  say "Skipping Magisk module install: ${ZIP_LOCAL_PATH} not found"
  echo "Put ${ZIP_NAME} next to this script (or edit ZIP_LOCAL_PATH) if you want it automated."
fi

# ------------------------
# OpenBubbles pairing + notification channel settings
# ------------------------
say "OpenBubbles setup"
echo "Follow pairing instructions here:"
echo "  https://openbubbles.app/quickstart.html"
echo "Do the pairing now."
pause

say "Opening OpenBubbles notification settings"
if pkg_installed "${OPENBUBBLES_PKG}"; then
  adb shell am start -a android.settings.APP_NOTIFICATION_SETTINGS \
    --es android.provider.extra.APP_PACKAGE "${OPENBUBBLES_PKG}" >/dev/null 2>&1 || true
  echo "On the phone: disable the Foreground Service notification channel for OpenBubbles (if present)."
else
  echo "OpenBubbles not installed (${OPENBUBBLES_PKG}); skipping notification settings."
fi
pause

say "Done ✔"
