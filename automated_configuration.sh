#!/usr/bin/env bash
set -euo pipefail

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

STOCK_LAUNCHER_PKG="com.android.launcher3"

pkg_installed() {
  local pkg="$1"
  adb_do shell pm list packages 2>/dev/null | tr -d '\r' | grep -q "^package:${pkg}$"
}

# ------------------------
# Start
# ------------------------
echo "Waiting for device..."
adb_do wait-for-device >/dev/null 2>&1 || true

echo "Waiting for boot/services..."
until adb_do shell 'test "$(getprop sys.boot_completed)" = "1"' >/dev/null 2>&1; do
  sleep 1
done

# Extra: wait until InputManagerService is published
until adb_do shell 'service check input >/dev/null 2>&1' >/dev/null 2>&1; do
  sleep 1
done

# Give launcher root access for accessibility services
APP_UID=$(adb_do shell pm list packages -U | grep "package:com.offlineinc.dumbdownlauncher" | tr -d '\r' | grep -o 'uid:[0-9]*' | cut -d: -f2)
adb_do shell << EOF
su -c 'magisk --sqlite "INSERT OR REPLACE INTO policies (uid,policy,until,logging,notification) VALUES($APP_UID,2,0,1,0)"'
exit
EOF

# ------------------------
# Disable stock launcher (only after default is set)
# ------------------------
echo "Disabling stock launcher: ${STOCK_LAUNCHER_PKG}"
if pkg_installed "${STOCK_LAUNCHER_PKG}"; then
  if adb_do shell pm disable-user --user 0 "${STOCK_LAUNCHER_PKG}" >/dev/null 2>&1; then
    echo "Disabled ${STOCK_LAUNCHER_PKG} ✔"
  else
    echo "FAILED to disable ${STOCK_LAUNCHER_PKG} (continuing)"
  fi
else
  echo "Stock launcher package not found (${STOCK_LAUNCHER_PKG}); skipping."
fi

echo "opening launcher"
adb_do shell monkey -p com.offlineinc.dumbdownlauncher -c android.intent.category.LAUNCHER 1

# ------------------------
# Notification listener access
# ------------------------
adb_do shell cmd notification allow_listener com.openbubbles.messaging/com.bluebubbles.messaging.services.notifications.NotificationListener

echo "adjust density"
adb_do shell wm density 120

echo "Done ✔. Do some testing and then turn off."
echo "Now turn on notifications for mini list launcher and open bubbles"

## Add launcher notification service and mouse importance
adb_do shell cmd notification allow_listener com.offlineinc.dumbdownlauncher/com.offlineinc.dumbdownlauncher.notifications.DumbNotificationListenerService
adb_do shell settings put secure enabled_accessibility_services com.offlineinc.dumbdownlauncher/.MouseAccessibilityService
adb_do shell settings put secure accessibility_enabled 1
adb_do shell settings get secure enabled_accessibility_services

## Give mini list launcher dnd access
adb_do shell << 'EOF'
su
sed -i 's|<service_listing approved="com.android.camera2" user="0" primary="true" />|<service_listing approved="com.android.camera2" user="0" primary="true" />\n<service_listing approved="com.offlineinc.dumbdownlauncher" user="0" primary="true" />|' /data/system/notification_policy.xml
EOF
###

echo "Disabling Magisk notifications..."
adb_do shell su -c 'appops set com.topjohnwu.magisk POST_NOTIFICATION ignore'
adb_do shell su -c 'appops get com.topjohnwu.magisk POST_NOTIFICATION'

echo "Adding MO contact..."

adb_do shell content insert --uri content://com.android.contacts/raw_contacts --bind account_type:s: --bind account_name:s:
ID=$(adb_do shell content query --uri content://com.android.contacts/raw_contacts --projection _id | tail -1 | grep -o '_id=[0-9]*' | cut -d= -f2)
echo "Got ID: $ID"
adb_do shell content insert --uri content://com.android.contacts/data --bind raw_contact_id:i:$ID --bind mimetype:s:vnd.android.cursor.item/name --bind data1:s:MO
adb_do shell content insert --uri content://com.android.contacts/data --bind raw_contact_id:i:$ID --bind mimetype:s:vnd.android.cursor.item/phone_v2 --bind data1:s:18446335463 --bind data2:i:2
adb_do shell content insert --uri content://com.android.contacts/data --bind raw_contact_id:i:$ID --bind mimetype:s:vnd.android.cursor.item/email_v2 --bind data1:s:month@offline.community --bind data2:i:1

echo "Adding Dumb Line contact..."

adb_do shell content insert --uri content://com.android.contacts/raw_contacts --bind account_type:s: --bind account_name:s:
ID=$(adb_do shell content query --uri content://com.android.contacts/raw_contacts --projection _id | tail -1 | grep -o '_id=[0-9]*' | cut -d= -f2)
echo "Got ID: $ID"
adb_do shell content insert --uri content://com.android.contacts/data --bind raw_contact_id:i:$ID --bind mimetype:s:vnd.android.cursor.item/name --bind data2:s:Dumb --bind data3:s:Line
adb_do shell content insert --uri content://com.android.contacts/data --bind raw_contact_id:i:$ID --bind mimetype:s:vnd.android.cursor.item/phone_v2 --bind data1:s:14047163605 --bind data2:i:2
adb_do shell content insert --uri content://com.android.contacts/data --bind raw_contact_id:i:$ID --bind mimetype:s:vnd.android.cursor.item/email_v2 --bind data1:s:support@offline.community --bind data2:i:1

adb_do shell settings put global zen_mode 0

echo "Rebooting..."
adb_do reboot || true