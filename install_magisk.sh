#!/usr/bin/env bash
set -euo pipefail

adb reboot

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

sleep 5
echo "Boot complete."

echo
echo "Initiating Magisk setup (follow instructions on screen)"
adb shell monkey -p com.topjohnwu.magisk -c android.intent.category.LAUNCHER 1
adb shell monkey -p com.topjohnwu.magisk -c android.intent.category.LAUNCHER 1

echo
echo "Waiting for Magisk notification..."

until adb shell dumpsys notification | grep -q "com.topjohnwu.magisk"; do
  sleep 1
done

echo "Magisk notification detected. Continuing..."

echo "Follow final setup command and reboot via Magisk UI"
adb shell monkey -p com.topjohnwu.magisk -c android.intent.category.LAUNCHER 1

echo
echo "Complete setup on the device."
echo "Waiting for Magisk to start reboot..."
adb wait-for-disconnect
