#!/usr/bin/env bash
set -euo pipefail

ZIP_NAME="FlipMouse.zip"
ZIP_LOCAL_PATH="./${ZIP_NAME}"
ZIP_REMOTE_PATH="/sdcard/Download/${ZIP_NAME}"

OPENBUBBLES_PKG="com.openbubbles.messaging"
STOCK_LAUNCHER_PKG="com.android.launcher3"

pause() {
  echo
  read -r -p "Press ENTER to continue..."
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

need_cmd adb

say "Checking adb device connection..."
adb devices

say "Waiting for device..."
adb wait-for-device

say "Opening launcher."
adb shell monkey -p com.offlineinc.dumbdownlauncher -c android.intent.category.LAUNCHER 1
pause

say "Opening Home settings so you can choose default launcher."
adb shell am start -a android.settings.HOME_SETTINGS || true
echo "On the phone: set Mini List Launcher as default."
pause

say "Opening Notification Listener settings so you can enable notification access."
adb shell am start -a android.settings.ACTION_NOTIFICATION_LISTENER_SETTINGS || true
echo "On the phone: enable notification access for your launcher as needed."
pause

say "Disabling stock launcher: ${STOCK_LAUNCHER_PKG}"
if adb shell pm disable-user --user 0 "${STOCK_LAUNCHER_PKG}"; then
  echo "Disabled ${STOCK_LAUNCHER_PKG}"
else
  echo "FAILED to disable ${STOCK_LAUNCHER_PKG} (continuing)"
fi

# ---- Magisk module install (FlipMouse.zip) ----
if [[ -f "${ZIP_LOCAL_PATH}" ]]; then
  say "Pushing ${ZIP_NAME} to ${ZIP_REMOTE_PATH}"
  adb push "${ZIP_LOCAL_PATH}" "/sdcard/Download/" >/dev/null

  say "Installing Magisk module (requires root/su on device)..."
  # If su isn't available, this will fail and we continue with instructions.
  if adb shell su -c "magisk --install-module '${ZIP_REMOTE_PATH}'"; then
    echo "Magisk module install command ran successfully."
    say "Rebooting device..."
    adb reboot
    say "Waiting for device to come back..."
    adb wait-for-device
  else
    echo "Magisk install failed (no su? magisk not available? path issue?)."
    echo "You can try manually:"
    echo "  adb shell su -c \"magisk --install-module '${ZIP_REMOTE_PATH}'\""
    echo "  adb reboot"
  fi
else
  say "Skipping Magisk module install: ${ZIP_LOCAL_PATH} not found."
  echo "Put ${ZIP_NAME} next to this script (or edit ZIP_LOCAL_PATH) if you want it automated."
fi

# ---- OpenBubbles ----
say "OpenBubbles setup"
echo "Follow pairing instructions here:"
echo "  https://openbubbles.app/quickstart.html"
echo "Do the pairing now."
pause

say "Opening OpenBubbles notification settings so you can disable its foreground service notification."
adb shell am start -a android.settings.APP_NOTIFICATION_SETTINGS \
  --es android.provider.extra.APP_PACKAGE "${OPENBUBBLES_PKG}" || true
echo "On the phone: disable the foreground service notification channel for OpenBubbles (if present)."
pause

say "Done."
