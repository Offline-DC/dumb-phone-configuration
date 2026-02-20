#!/usr/bin/env bash
set -euo pipefail

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
echo "Waiting for device..."
adb wait-for-device >/dev/null 2>&1 || true

echo "Waiting for boot/services..."
until adb shell 'test "$(getprop sys.boot_completed)" = "1"' >/dev/null 2>&1; do
  sleep 1
done

# Extra: wait until InputManagerService is published
until adb shell 'service check input >/dev/null 2>&1' >/dev/null 2>&1; do
  sleep 1
done

# ------------------------
# Disable stock launcher (only after default is set)
# ------------------------
echo "Disabling stock launcher: ${STOCK_LAUNCHER_PKG}"
if pkg_installed "${STOCK_LAUNCHER_PKG}"; then
  if adb shell pm disable-user --user 0 "${STOCK_LAUNCHER_PKG}" >/dev/null 2>&1; then
    echo "Disabled ${STOCK_LAUNCHER_PKG} ✔"
  else
    echo "FAILED to disable ${STOCK_LAUNCHER_PKG} (continuing)"
  fi
else
  echo "Stock launcher package not found (${STOCK_LAUNCHER_PKG}); skipping."
fi

echo "opening launcher"
adb shell monkey -p com.offlineinc.dumbdownlauncher -c android.intent.category.LAUNCHER 1
sleep 3

# ------------------------
# Notification listener access
# ------------------------
LAUNCHER_PKG="com.offlineinc.dumbdownlauncher"

echo "Opening Notification Listener settings..."
adb shell am start -a android.settings.ACTION_NOTIFICATION_LISTENER_SETTINGS >/dev/null 2>&1 || true

echo -n "Waiting for notification access for $LAUNCHER_PKG"

# Wait until enabled_notification_listeners includes your package
while true; do
  enabled="$(adb shell settings get secure enabled_notification_listeners 2>/dev/null | tr -d '\r' || true)"

  if echo "$enabled" | grep -Fq "$LAUNCHER_PKG"; then
    echo " ✓"
    echo "Notification access granted."
    break
  fi

  echo -n "."
  sleep 1
done

echo "adjust density"
adb shell wm density 120

adb shell su -c "magisk --sqlite 'UPDATE policies SET notification=0 WHERE 1'"


# TODO – add open bubbles setup
# echo "Opening OpenBubbles notification settings"
# if pkg_installed "${OPENBUBBLES_PKG}"; then
#   adb shell am start -a android.settings.APP_NOTIFICATION_SETTINGS \
#     --es android.provider.extra.APP_PACKAGE "${OPENBUBBLES_PKG}" >/dev/null 2>&1 || true
#   echo "On the phone: disable the Foreground Service notification channel for OpenBubbles (if present)."
# else
#   echo "OpenBubbles not installed (${OPENBUBBLES_PKG}); skipping notification settings."
# fi
# pause

# echo "(Optional) OpenBubbles setup"
# echo "Follow pairing instructions here:"
# echo "  https://openbubbles.app/quickstart.html"
# echo "Do the pairing now.

echo "Done ✔. Do some testing and then turn off."
echo "Now turn on notifications for mini list launcher and open bubbles"

adb shell am start -a android.settings.ACTION_NOTIFICATION_LISTENER_SETTINGS >/dev/null 2>&1 || true

# adb shell settings put secure enabled_accessibility_services com.offlineinc.dumbdownlauncher/.MouseAccessibilityService
# adb shell settings put secure accessibility_enabled 1
# adb shell settings get secure enabled_accessibility_services
