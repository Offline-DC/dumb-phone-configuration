FLIPMOUSE_ZIP="FlipMouse.zip"
FLIPMOUSE_LOCAL="./${FLIPMOUSE_ZIP}"
FLIPMOUSE_REMOTE="/sdcard/Download/${FLIPMOUSE_ZIP}"

KEYMOD_DIR="./modules/disable-favorite-contacts-key"
KEYMOD_ZIP="DisableFavoriteContactsKey.zip"
KEYMOD_LOCAL="./${KEYMOD_ZIP}"
KEYMOD_REMOTE="/sdcard/Download/${KEYMOD_ZIP}"

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

echo "Rebooting device..."
adb reboot

echo "Waiting for device..."
adb wait-for-device >/dev/null 2>&1 || true

echo "Waiting for Android boot to complete..."

echo "Done. Wait until phone is fully on before running additional scripts"

