## TCL Flip 2 Configuration

This document tracks working solutions for installing apps and getting developer/root access to the TCL Flip 2. Since this phone is built off of android

## 1. Setup

Do setup in terminal. Terminal is an app on your mac.

1. clone this repository and go into it:

```bash
git clone https://github.com/Offline-DC/dumb-phone-configuration.git

cd dumb-phone-configuration
```

2. Install Homebrew in your Terminal.

```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

3. Close and Reopen Terminal app, then run:

```bash
cd dumb-phone-configuration # or whatever gets you back to your repo
```

4. Install adb

```bash
brew install android-platform-tools
```

5. Install serial package:

```bash
python3 -m pip install --user pyserial
```

### 2. To allow app installation:

1. On TCL Flip 2, follow steps for **Developer access** [here](#4-uber-in-browser-and-whatsapp) (at the bottom of these instructions)
2. In command window `adb shell settings put global development_settings_enabled 1`
3. `adb shell reboot -p`
4. Unplug TCL let turn completely off
5. Run `./example.sh` in command window (Mac or Linux) then plug TCL back in
6. Run command `fastboot flashing unlock`
7. hit Volume up on TCL
8. Run command `fastboot flash boot neutron.img`
9. Run command `fastboot reboot`
10. Go through initial setup screens, skip WiFi step
11. Enable **Developer access** again
12. `adb shell reboot`
13. Wait till back on then `adb shell`
14. `su`
15. Follow instructions on phone to grant user root access
16. Wait for Magisk to finish install (will get notification) and then in notifications open Magisk and do reboot.

### 3. To get higher resolution

Needed for WhatsApp and Uber (in-browser) to work

Higher resolution via `adb shell wm density 120`

- You must do this or WhatsApp QR code & Uber won't work

### 4. Uber (in-browser) and WhatsApp

1. Download WhatsApp apk into this project folder. Apk is [here](https://drive.google.com/file/d/1ESycIkwHVfv1qAAAnN4bpryRL3h_HSpN/view?usp=sharing). You only have to do this once
2. Install WhatsApp via `adb install WhatsApp.apk`.
3. Install Uber via `adb install uber-repo.apk`

### BETA-INSTRUCTIONS

1. Download vMouse and install (run one at a time):

```bash
adb push FlipMouse.zip /sdcard/Download
adb shell
su ## Then follow dialogue to grant access
# if needed: adb shell am start -n com.topjohnwu.magisk/.ui.MainActivity
magisk --install-module /sdcard/Download/FlipMouse.zip

# Instructions for removing star shortcut to favorites
adb shell
su
mkdir -p /data/adb/modules/keyremap/system/usr/keylayout
cd /data/adb/modules/keyremap
cat > module.prop <<EOF
id=keyremap
name=Key Remap
version=1.0
versionCode=1
author=Custom
description=Remap Favorite Contacts key so it no longer launches Contacts
EOF
cp /system/usr/keylayout/matrix-keypad.kl system/usr/keylayout/
sed -i 's/FAVORITE_CONTACTS/FOCUS/' system/usr/keylayout/matrix-keypad.kl
chmod -R 755 /data/adb/modules/keyremap
reboot
```

2. Install apps

```bash
adb install apk/WhatsApp.apk
adb install apk/uber-repo.apk
adb install apk/launcher.apk
adb install-multiple \
   apk/openbubbles/base.apk \
   apk/openbubbles/split_config.armeabi_v7a.apk \
   apk/openbubbles/split_config.en.apk \
   apk/openbubbles/split_config.ldpi.apk
adb install apk/googlemaps/maps.apk
adb install apk/apple-music.apk
adb install-multiple \
   apk/contacticloudsync/base.apk \
   apk/contacticloudsync/split_config.armeabi_v7a.apk \
   apk/contacticloudsync/split_config.en.apk \
   apk/contacticloudsync/split_config.ldpi.apk
adb install apk/azure-authenticator.apk
```

3. Select launcher (run one at a time)

```bash
adb shell am start -a android.settings.HOME_SETTINGS
## after this select Mini List Launcher
adb shell pm disable-user --user 0 com.android.launcher3
adb shell am start -a android.settings.ACTION_NOTIFICATION_LISTENER_SETTINGS
# After this allow notification access
```

4. Reboot `adb reboot`

5. [Self-host open bubbles quick start](https://openbubbles.app/quickstart.html)

- Go through to scanning on the phone.
- Turn off foreground service:
  - `adb shell am start -a android.settings.APP_NOTIFICATION_SETTINGS \
--es android.provider.extra.APP_PACKAGE com.openbubbles.messaging`

6. Disa

### Helpful links for how I figured out how to do these things

https://imgur.com/a/rooting-tcl-flip-2-dummies-yT5hbCm
https://www.reddit.com/r/dumbphones/comments/17aen23/comment/k5ethjg/
https://gist.github.com/neutronscott/2e4179af74c2fadec101a184fbb6a89e
https://github.com/neutronscott/flip2/wiki
https://www.reddit.com/r/dumbphones/comments/1756fqz/tcl_flip_2_virtual_mouse/

### Developer access

1. Enable USB debugging
   - dial `*#*#33284#*#*`
2. Plug in phone to computer
3. Run `adb devices`
4. Always allow USB debugging
5. Confirm you are authorized to access via `adb devices` again
