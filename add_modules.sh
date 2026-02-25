FLIPMOUSE_ZIP="FlipMouse.zip"
FLIPMOUSE_LOCAL="./${FLIPMOUSE_ZIP}"
FLIPMOUSE_REMOTE="/sdcard/Download/${FLIPMOUSE_ZIP}"

KEYMOD_DIR="./modules/disable-favorite-contacts-key"
KEYMOD_ZIP="DisableFavoriteContactsKey.zip"
KEYMOD_LOCAL="./${KEYMOD_ZIP}"
KEYMOD_REMOTE="/sdcard/Download/${KEYMOD_ZIP}"

# ---------------------------------------
# Simple ADB scoping helper
# ---------------------------------------
SERIAL=""
# parse optional --serial argument
while [[ $# -gt 0 ]]; do
  case "$1" in
    --serial)
      SERIAL="$2"
      shift 2
      ;;
    *)
      break
      ;;
  esac
done

adb_do() {
  if [[ -n "$SERIAL" ]]; then
    adb -s "$SERIAL" "$@"
  else
    adb "$@"
  fi
}
# END ADB SCOPING HELPER

echo "Waiting for device..."
adb_do wait-for-device

echo "Waiting for sys.boot_completed..."
until adb_do shell 'test "$(getprop sys.boot_completed)" = "1"' >/dev/null 2>&1; do
  sleep 1
done

echo "Waiting for dev.bootcomplete..."
until adb_do shell 'test "$(getprop dev.bootcomplete)" = "1"' >/dev/null 2>&1; do
  sleep 1
done

echo "Waiting for package manager..."
until adb_do shell 'pm path android >/dev/null 2>&1' >/dev/null 2>&1; do
  sleep 1
done

echo "Waiting for sdcard..."
until adb_do shell 'ls /sdcard' >/dev/null 2>&1; do
  sleep 1
done

echo "Building key-remap Magisk module zip..."
( cd "${KEYMOD_DIR}" && zip -r "../../${KEYMOD_ZIP}" . >/dev/null )

echo "Installing FlipMouse module..."
adb_do push FlipMouse.zip /data/local/tmp/FlipMouse.zip

say "Alert – prepare for permission request on phone."
adb_do shell su -c "magisk --install-module '/data/local/tmp/FlipMouse.zip'"

echo "FlipMouse install command executed ✔"

echo "Pushing ${KEYMOD_ZIP} to Downloads..."
adb_do push "${KEYMOD_LOCAL}" "${KEYMOD_REMOTE}"

echo "Installing key-remap module..."
adb_do shell su -c "magisk --install-module '${KEYMOD_REMOTE}'"
echo "Key-remap install command executed ✔"

adb_do shell settings put global device_provisioned 1
adb_do shell settings put secure user_setup_complete 1
adb_do shell settings put secure profile_setup_complete 1 2>/dev/null || true

echo "Rebooting device..."
adb_do reboot

echo "Waiting for device..."
adb_do wait-for-device >/dev/null 2>&1 || true