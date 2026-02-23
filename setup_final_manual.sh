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

# Give launcher root access for accessibility services
APP_UID=$(adb shell pm list packages -U | grep "package:com.offlineinc.dumbdownlauncher" | tr -d '\r' | grep -o 'uid:[0-9]*' | cut -d: -f2)
adb shell << EOF
su -c 'magisk --sqlite "INSERT OR REPLACE INTO policies (uid,policy,until,logging,notification) VALUES($APP_UID,2,0,1,0)"'
exit
EOF

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

# ------------------------
# Notification listener access
# ------------------------
adb shell cmd notification allow_listener com.offlineinc.dumbdownlauncher/com.offlineinc.dumbdownlauncher.notifications.DumbNotificationListenerService
adb shell cmd notification allow_listener com.openbubbles.messaging/com.bluebubbles.messaging.services.notifications.NotificationListener

echo "adjust density"
adb shell wm density 120

echo "Done ✔. Do some testing and then turn off."
echo "Now turn on notifications for mini list launcher and open bubbles"

adb shell settings put secure enabled_accessibility_services com.offlineinc.dumbdownlauncher/.MouseAccessibilityService
adb shell settings put secure accessibility_enabled 1
adb shell settings get secure enabled_accessibility_services

adb shell appops set com.topjohnwu.magisk POST_NOTIFICATION deny
adb shell 'su -c "sed -i /foreground_service/s/importance=.2./importance=\\\"0\\\"/ /data/system/notification_policy.xml"'

echo "Adding MO contact..."

adb shell content insert --uri content://com.android.contacts/raw_contacts --bind account_type:s: --bind account_name:s:
ID=$(adb shell content query --uri content://com.android.contacts/raw_contacts --projection _id | tail -1 | grep -o '_id=[0-9]*' | cut -d= -f2)
echo "Got ID: $ID"
adb shell content insert --uri content://com.android.contacts/data --bind raw_contact_id:i:$ID --bind mimetype:s:vnd.android.cursor.item/name --bind data1:s:MO
adb shell content insert --uri content://com.android.contacts/data --bind raw_contact_id:i:$ID --bind mimetype:s:vnd.android.cursor.item/phone_v2 --bind data1:s:18446335463 --bind data2:i:2
adb shell content insert --uri content://com.android.contacts/data --bind raw_contact_id:i:$ID --bind mimetype:s:vnd.android.cursor.item/email_v2 --bind data1:s:month@offline.community --bind data2:i:1

echo "Adding Dumb Line contact..."

adb shell content insert --uri content://com.android.contacts/raw_contacts --bind account_type:s: --bind account_name:s:
ID=$(adb shell content query --uri content://com.android.contacts/raw_contacts --projection _id | tail -1 | grep -o '_id=[0-9]*' | cut -d= -f2)
echo "Got ID: $ID"
adb shell content insert --uri content://com.android.contacts/data --bind raw_contact_id:i:$ID --bind mimetype:s:vnd.android.cursor.item/name --bind data2:s:Dumb --bind data3:s:Line
adb shell content insert --uri content://com.android.contacts/data --bind raw_contact_id:i:$ID --bind mimetype:s:vnd.android.cursor.item/phone_v2 --bind data1:s:14047163605 --bind data2:i:2
adb shell content insert --uri content://com.android.contacts/data --bind raw_contact_id:i:$ID --bind mimetype:s:vnd.android.cursor.item/email_v2 --bind data1:s:support@offline.community --bind data2:i:1

adb reboot

echo "Waiting for device..."
adb wait-for-device

adb shell monkey -p com.topjohnwu.magisk -c android.intent.category.LAUNCHER 1

say "ACTION REQUIRED. Go through post launch setup" 
echo "- In Magisk (opened for your convenience), use Mouse to go to settings gear, and change Superuser Notification to None"
echo "- In OpenBubbles, go through setup and scan mac QR code"
echo "- Reboot and retest everything"
