set -euo pipefail

VERSION=""

# -----------------------------
# Parse flags
# -----------------------------
while [[ $# -gt 0 ]]; do
  case "$1" in
    --version)
      VERSION="${2:-}"
      if [[ -z "$VERSION" ]]; then
        echo "Error: --version requires a value." >&2
        exit 1
      fi
      shift 2
      ;;
    *)
      # keep other args for your existing parsing, or just ignore here
      break
      ;;
  esac
done

git pull

./flash_root.sh

# PETE version
if [[ "$VERSION" == "pete" ]]; then
  echo "Version=pete: running Pete-only install steps and exiting."

  echo "Waiting for phone to turn on... and enable debug when the option arises"
  adb wait-for-device

  echo "Waiting for debug option..."
  adb install ./apk/WhatsApp.apk
  adb install ./apk/uber-repo.apk
  adb shell wm density 120

  echo "ACTION REQUIRED TO FINISH SETUP:"
  echo "1) Go through onboarding"
  echo "2) Go to Settings -> Phone Settings -> Key shortcuts, and make LEFT shortcut key WhatsApp, and RIGHT shortcut key Uber"
  echo "3) Go to Settings -> Display -> Menu layout, and select list"
  echo "4) Go to Settings -> Display -> font size, and select Largest"
  echo "5) Final triple check that keys open both apps as expected"
  exit 0
fi

if [[ "$VERSION" == "march" ]]; then

  ./wifi_install.sh
  ./install_magisk.sh
  ./add_modules.sh
  ./add_apks.sh
  ./setup_final_manual.sh

  exit 0
fi