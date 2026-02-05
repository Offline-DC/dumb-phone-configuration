#!/usr/bin/env bash
set -euo pipefail

MODULE_DIR="tclprovision"

if [[ ! -d "$MODULE_DIR" ]]; then
  echo "ERROR: ./${MODULE_DIR} directory not found."
  exit 1
fi

if ! command -v zip >/dev/null 2>&1; then
  echo "ERROR: zip is not installed. On macOS: brew install zip"
  exit 1
fi

echo "== Building provisioning zip =="
echo "Module dir : ./${MODULE_DIR}"
echo "Output zip : ./tclprovision.zip"
echo

rm -f "./tclprovision.zip"

(
  cd "${MODULE_DIR}"
  # zip contents of tclprovision/ into ../tclprovision.zip
  zip -r "../tclprovision.zip" . >/dev/null
)

echo "Built: ./tclprovision.zip"
