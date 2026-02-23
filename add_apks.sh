#!/usr/bin/env bash
set -euo pipefail

say(){ echo; echo "==> $*"; }

APKDIR="./apk"

echo "Waiting for device... Make sure to allow debugging after startup"
adb wait-for-device

echo "Waiting for sys.boot_completed..."
until adb shell 'test "$(getprop sys.boot_completed)" = "1"' >/dev/null 2>&1; do
  sleep 1
done

install_apk() {
  local name="$1"
  local path="$2"

  if [[ ! -f "$path" ]]; then
    echo "SKIP  $name (missing: $path)"
    return 0
  fi

  if adb install -r "$path" >/dev/null; then
    echo "PASS  $name"
  else
    echo "FAIL  $name"
    return 1
  fi
}

install_splits_dir() {
  local name="$1"
  local dir="$2"

  if [[ ! -d "$dir" ]]; then
    echo "SKIP  $name (missing dir: $dir)"
    return 0
  fi

  local base="$dir/base.apk"
  if [[ ! -f "$base" ]]; then
    echo "FAIL  $name (missing base.apk in $dir)"
    return 1
  fi

  # IMPORTANT with `set -u`: always initialize the array
  local -a splits=()

  # Fill array without mapfile (portable)
  while IFS= read -r f; do
    [[ -n "$f" ]] && splits+=("$f")
  done < <(find "$dir" -maxdepth 1 -type f -name "*.apk" ! -name "base.apk" -print | sort)

  if ((${#splits[@]} > 0)); then
    adb install-multiple -r "$base" "${splits[@]}" >/dev/null
  else
    # No splits found — install base only (or change this to fail if you prefer)
    adb install -r "$base" >/dev/null
  fi

  echo "PASS  $name"
}

echo "Installing Apps..."

# --- Single APKs ---
install_apk "WhatsApp"            "$APKDIR/WhatsApp.apk"            || true
install_apk "Uber"                "$APKDIR/uber-repo.apk"           || true
install_apk "Launcher"            "$APKDIR/launcher.apk"            || true
install_apk "Google Maps (lite)"  "$APKDIR/googlemaps/maps.apk"     || true
install_apk "Contact Sync"         "$APKDIR/contact-sync.apk"         || true
install_apk "Azure Authenticator" "$APKDIR/azure-authenticator.apk" || true

# --- Split bundles ---
install_splits_dir "OpenBubbles"        "$APKDIR/openbubbles"        || true
install_splits_dir "Contact iCloud Sync" "$APKDIR/contacticloudsync" || true

say "APK install step complete."