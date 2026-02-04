#!/system/bin/sh

install_splits() {
  NAME="$1"; shift
  echo "Installing split session: $NAME"

  OUT="$(cmd package install-create -r 2>&1)"
  echo "$OUT"

  # Robust SID extraction for outputs like: "Success: created install session [54411051]"
  SID="$(echo "$OUT" | grep -oE '\[[0-9]+\]' | tr -d '[]' | tail -n 1)"

  if [ -z "$SID" ]; then
    echo "FAILED to parse install session id for $NAME"
    return 1
  fi

  echo "Session id: $SID"

  for APK in "$@"; do
    if [ ! -f "$APK" ]; then
      echo "Missing APK: $APK"
      cmd package install-abandon "$SID" >/dev/null 2>&1 || true
      return 1
    fi

    SPLIT_NAME="$(basename "$APK")"
    echo "  install-write $SID $SPLIT_NAME $APK"
    cmd package install-write "$SID" "$SPLIT_NAME" "$APK" >/dev/null 2>&1 || {
      echo "FAILED install-write: $APK"
      cmd package install-abandon "$SID" >/dev/null 2>&1 || true
      return 1
    }
  done

  echo "  install-commit $SID"
  cmd package install-commit "$SID" >/dev/null 2>&1 || {
    echo "FAILED install-commit for $NAME"
    cmd package install-abandon "$SID" >/dev/null 2>&1 || true
    return 1
  }

  echo "Split install OK: $NAME"
  return 0
}

LOG=/data/local/tmp/tclprovision.log
FLAG=/data/local/tmp/tclprovision_done
MODDIR=/data/adb/modules/tclprovision
APKDIR="$MODDIR/apk"

exec >> "$LOG" 2>&1
echo "=== tclprovision starting ==="

# Run only once
if [ -f "$FLAG" ]; then
  echo "Already provisioned; exiting."
  exit 0
fi

# Wait for Android to fully boot
while [ "$(getprop sys.boot_completed)" != "1" ]; do
  sleep 3
done
sleep 5

echo "Boot completed, provisioning..."

# Sanity: cmd/package should exist if split installs are to work
if ! command -v cmd >/dev/null 2>&1; then
  echo "ERROR: cmd binary not found; cannot do split installs."
fi

# Density tweak
wm density 120 || echo "FAILED wm density"

# Install single APKs
pm install -r "$APKDIR/WhatsApp.apk" || echo "FAILED WhatsApp"
pm install -r "$APKDIR/uber-repo.apk" || echo "FAILED uber"
pm install -r "$APKDIR/launcher.apk" || echo "FAILED launcher"
pm install -r "$APKDIR/googlemaps/maps.apk" || echo "FAILED googlemaps"
pm install -r "$APKDIR/apple-music.apk" || echo "FAILED apple-music"
pm install -r "$APKDIR/azure-authenticator.apk" || echo "FAILED azure-authenticator"

# Install split APK bundles (session-based)
install_splits "openbubbles" \
  "$APKDIR/openbubbles/base.apk" \
  "$APKDIR/openbubbles/split_config.armeabi_v7a.apk" \
  "$APKDIR/openbubbles/split_config.en.apk" \
  "$APKDIR/openbubbles/split_config.ldpi.apk" \
  || echo "FAILED openbubbles split install"

install_splits "contacticloudsync" \
  "$APKDIR/contacticloudsync/base.apk" \
  "$APKDIR/contacticloudsync/split_config.armeabi_v7a.apk" \
  "$APKDIR/contacticloudsync/split_config.en.apk" \
  "$APKDIR/contacticloudsync/split_config.ldpi.apk" \
  || echo "FAILED contacticloudsync split install"

touch "$FLAG"
echo "Provisioning complete. Rebooting..."
reboot
