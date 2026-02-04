#!/bin/sh
set -e

if fastboot devices | grep -q .; then
  echo "Already in fastboot."
  exit 0
fi

sudo python3 autobooter.py
a=$?

if [ $a -gt 99 ]; then
  echo "Failed to find serial port (autobooter)."
  exit 100
elif [ $a -gt 0 ]; then
  echo "Failed to find device (autobooter)."
  exit 1
fi

echo "success"
