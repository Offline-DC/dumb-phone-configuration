#!/usr/bin/env bash
set -euo pipefail

ENV_FILE=".env"
FORCE_SAVE=0

# Optional flag: --save forces overwrite of .env
if [[ "${1:-}" == "--save" ]]; then
  FORCE_SAVE=1
  shift
fi

# 1️⃣ Load existing .env if present
if [[ -f "$ENV_FILE" ]]; then
  set -a
  source "$ENV_FILE"
  set +a
fi

# 2️⃣ CLI args override .env
SSID="${1:-${WIFI_SSID:-}}"
PASS="${2:-${WIFI_PASS:-}}"

# 3️⃣ Prompt if still missing
if [[ -z "${SSID}" ]]; then
  echo "No .env found, setting credentials"
  read -rp "Enter Wi-Fi SSID: " SSID
fi

if [[ -z "${PASS}" ]]; then
  read -rsp "Enter Wi-Fi Password: " PASS
  echo
fi

# Final validation
if [[ -z "${SSID}" || -z "${PASS}" ]]; then
  echo "Wi-Fi SSID and Password required."
  exit 1
fi

echo "Connecting to Wi-Fi: ${SSID}..."

echo "Waiting for device that is on with debug enabled (ACTION REQUIRED: will need to allow debug on for this)!"

adb wait-for-device

adb shell "svc wifi enable; cmd wifi connect-network \"${SSID}\" wpa2 \"${PASS}\""

echo
adb shell "cmd wifi status; echo; getprop dhcp.wlan0.ipaddress"

# 4️⃣ Save .env if needed
if [[ ! -f "$ENV_FILE" || "$FORCE_SAVE" -eq 1 ]]; then
  echo
  echo "Saving Wi-Fi credentials to $ENV_FILE"

  cat > "$ENV_FILE" <<EOF
WIFI_SSID="${SSID}"
WIFI_PASS="${PASS}"
EOF

  echo "$ENV_FILE created."
else
  echo
  echo "$ENV_FILE already exists. Not overwriting."
  echo "Use --save to overwrite."
fi
