## TCL Flip 2 Configuration

This document tracks working solutions for installing apps and getting developer/root access to the TCL Flip 2. Since this phone is built off of android

## 1. Setup

Do setup in terminal:

1. Install Homebrew

```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

2. Install adb

```bash
brew install android-platform-tools
```

3. Install serial package:

```bash
python3 -m pip install --user pyserial
```

### 2. To allow app installation:

1. On TCL Flip 2, follow steps for **Developer access**
2. In command window `adb shell settings put global development_settings_enabled 1`
3. Unplug TCL from computer and turn off
4. Run `./example.sh` (worked on Mac or Linux)
5. Plug TCL back in
6. Unlock the bootloader to allow modified boot partition
   - `fastboot flashing unlock`
7. Flash boot partition
   - `fastboot flash boot neutron.img`
8. Reboot phone
   - `fastboot reboot`
9. Connect to wifi
10. Install Magisk
    - Dial `*#*#217703#*#*` to bring up list of apps
    - Select Magisk and allow to download full version.
      - **NOTE**: Magisk may not show up on the first boot or sometimes you cannot install APKs later. It's a timing issue with `ro.vendor.tct.endurance` getting set. Just reboot.
    - Select Magisk in notifications and allow to update and reboot.
11. Enable **Developer access** again
12. Enable APK install `*#*#2880#*#*`

### 3. To get higher resolution

Needed for WhatsApp and Uber (in-browser) to work

1. Enable **Developer access**
2. Higher resolution via `adb shell wm density 120`
   - You must do this or WhatsApp QR code won't work
3. Install WhatsApp via `adb install WhatsApp.spk`
4. make font in tcl flip largest
5. Make menu a list

### 4. Uber (in-browser)

- follow the **get higher resolution** steps
- in browser go to m.uber.com
- use mouse to go to login
- enter phone #, verify, then password
- Install apk from [here](https://github.com/Offline-DC/uber-launcher-android) and make it a key shortcut

### 5. WhatsApp

1. Follow steps **To allow app installation** and **To get higher resolution**
2. Install APK via `adb install WhatsApp.apk`
3. Make app a Shortcut on TCL (because it doesn't show up in launch icons)
4. During setup, do NOT enter phone number, link companion device

### Helpful links for how I figured out how to do these things

https://imgur.com/a/rooting-tcl-flip-2-dummies-yT5hbCm
https://www.reddit.com/r/dumbphones/comments/17aen23/comment/k5ethjg/
https://gist.github.com/neutronscott/2e4179af74c2fadec101a184fbb6a89e
https://github.com/neutronscott/flip2/wiki

### Developer access

1. Enable USB debugging
   - dial `*#*#DEBUG#*#*`
2. Plug in phone to computer
3. Run `adb devices`
4. Always allow USB debugging
5. Confirm you are authorized to access via `adb devices` again
