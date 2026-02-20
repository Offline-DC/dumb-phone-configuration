FLIPMOUSE_ZIP="FlipMouse.zip"
FLIPMOUSE_LOCAL="./${FLIPMOUSE_ZIP}"
FLIPMOUSE_REMOTE="/sdcard/Download/${FLIPMOUSE_ZIP}"

KEYMOD_DIR="./modules/disable-favorite-contacts-key"
KEYMOD_ZIP="DisableFavoriteContactsKey.zip"
KEYMOD_LOCAL="./${KEYMOD_ZIP}"
KEYMOD_REMOTE="/sdcard/Download/${KEYMOD_ZIP}"

echo "Waiting for device..."
adb wait-for-device

echo "Waiting for sys.boot_completed..."
until adb shell 'test "$(getprop sys.boot_completed)" = "1"' >/dev/null 2>&1; do
  sleep 1
done

echo "Waiting for dev.bootcomplete..."
until adb shell 'test "$(getprop dev.bootcomplete)" = "1"' >/dev/null 2>&1; do
  sleep 1
done

echo "Waiting for package manager..."
until adb shell 'pm path android >/dev/null 2>&1' >/dev/null 2>&1; do
  sleep 1
done

echo "Waiting for sdcard..."
until adb shell 'ls /sdcard' >/dev/null 2>&1; do
  sleep 1
done
adb shell mkdir -p /sdcard/Download

echo "Building key-remap Magisk module zip..."
( cd "${KEYMOD_DIR}" && zip -r "../../${KEYMOD_ZIP}" . >/dev/null )

echo "Pushing ${FLIPMOUSE_ZIP} to Downloads..."
adb push "${FLIPMOUSE_LOCAL}" "${FLIPMOUSE_REMOTE}"

echo "Installing FlipMouse module..."
adb shell su -c "magisk --install-module '${FLIPMOUSE_REMOTE}'"
echo "FlipMouse install command executed ✔"

echo "Pushing ${KEYMOD_ZIP} to Downloads..."
adb push "${KEYMOD_LOCAL}" "${KEYMOD_REMOTE}"

echo "Installing key-remap module..."
adb shell su -c "magisk --install-module '${KEYMOD_REMOTE}'"
echo "Key-remap install command executed ✔"

adb shell settings put global device_provisioned 1
adb shell settings put secure user_setup_complete 1
adb shell settings put secure profile_setup_complete 1 2>/dev/null || true

echo "Rebooting device..."
adb reboot

echo "Waiting for device..."
adb wait-for-device >/dev/null 2>&1 || true