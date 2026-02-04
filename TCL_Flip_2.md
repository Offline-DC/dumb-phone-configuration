## TCL Flip 2 Configuration

This document tracks working solutions for installing apps and getting developer/root access to the TCL Flip 2. Since this phone is built off of android

## 0. Prerequisite: Computer setup

Do setup in terminal (Mac or Linux)

1. clone this repository and go into it:

```bash
git clone https://github.com/Offline-DC/dumb-phone-configuration.git
cd dumb-phone-configuration

brew install android-platform-tools
python3 -m pip install --user pyserial
```

### 1. Enable Developer Access on Phone

On the TCL Flip 2:

- Dial: `*#*#33284#*#*`
- Turn on USB Debugging
- Plug phone into computer
- Run: `adb devices`
  Tap Allow on phone when prompted.

### 2. Unlock + Flash Root + Finish Magisk

This script handles:

- Power off
- Serial boot trigger
- Fastboot detection
- Bootloader unlock
- Flashing neutron.img

Follow instructions in the command line

```bash
./flash_root.sh neutron.img
```

### 3. Add magisk script

This script waits for Android to finish booting, checks root, installs the provisioning module, and reboots.

First build the module zip:

```bash
cd tclprovision && zip -r ../tclprovision.zip . && cd ..
```

(Recommended: Connect to WiFi, otherwise Magisk will install using data)

Then run:

```bash
./finish_magisk.sh tclprovision.zip
```

### 4. Final Manual Setups

Choose a default launcher:

```bash
adb shell am start -a android.settings.HOME_SETTINGS

```

Enable notification access:

```bash
adb shell am start -a android.settings.ACTION_NOTIFICATION_LISTENER_SETTINGS
```

Disable stock launcher

```bash
adb shell pm disable-user --user 0 com.android.launcher3 || echo "FAILED disable launcher3"
```

```bash
adb push tclprovision/modules/FlipMouse.zip /sdcard/Download/
adb shell su -c 'magisk --install-module /sdcard/Download/FlipMouse.zip'
adb reboot
```

### OpenBubbles Setup

Follow pairing instructions from:

- 👉 https://openbubbles.app/quickstart.html
- After pairing, disable its foreground service:

```bash
adb shell am start -a android.settings.APP_NOTIFICATION_SETTINGS \
--es android.provider.extra.APP_PACKAGE com.openbubbles.messaging
```
