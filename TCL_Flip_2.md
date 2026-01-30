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
3. Unplug TCL from computer and turn off
4. Run `./example.sh` in command window (Mac or Linux)
5. Plug TCL back on
6. Unlock the bootloader to allow modified boot partition
   - Run command `fastboot flashing unlock`
   - Then, hit Volume up on TCL
7. Flash boot partition
   - Run command `fastboot flash boot neutron.img`
8. Reboot phone
   - Run command `fastboot reboot`
9. Connect to wifi
   - GA Wifi Password: `3WJs72unEDFgDHPwjA72`
10. Finish setup and restart phone at home page
11. Install Magisk
    - Dial `*#*#217703#*#*` to bring up list of apps
    - Do Magisk install
    - Wait for Magisk to finish install (will get notification) and then in notifications open Magisk and do reboot.
    - Select Magisk in notifications and allow to update and reboot.
12. Enable **Developer access** again
13. Enable APK install `*#*#2880#*#*`

### 3. To get higher resolution

Needed for WhatsApp and Uber (in-browser) to work

1. Enable **Developer access**
2. Higher resolution via `adb shell wm density 120`
   - You must do this or WhatsApp QR code & Uber won't work
3. make font in tcl flip largest (Settings -> Display -> Font size -> Largest)
4. Make menu a list (Settings -> Display -> Menu layout -> List)

### 4. Uber (in-browser) and WhatsApp

1. Download WhatsApp apk into this project folder. Apk is [here](https://drive.google.com/file/d/1ESycIkwHVfv1qAAAnN4bpryRL3h_HSpN/view?usp=sharing). You only have to do this once
2. Install WhatsApp via `adb install WhatsApp.apk`.
3. Install Uber via `adb install uber-repo.apk`
4. Make "Uber" app the shortcut for right keypad (Settings -> Phone Settings -> Key shortcuts).

- Go to keypad, hit "set", then the app, then save

5. Make "WhatsApp" app the shortcut for left keypad (Settings -> Phone Settings -> Key shortcuts)

6. Confirm they both open via left and right keypad on homepage

### Helpful links for how I figured out how to do these things

https://imgur.com/a/rooting-tcl-flip-2-dummies-yT5hbCm
https://www.reddit.com/r/dumbphones/comments/17aen23/comment/k5ethjg/
https://gist.github.com/neutronscott/2e4179af74c2fadec101a184fbb6a89e
https://github.com/neutronscott/flip2/wiki

### Developer access

1. Enable USB debugging
   - dial `*#*#33284#*#*`
2. Plug in phone to computer
3. Run `adb devices`
4. Always allow USB debugging
5. Confirm you are authorized to access via `adb devices` again
