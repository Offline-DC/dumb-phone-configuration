## TCL Flip 2 Configuration

This document tracks working solutions for installing apps and getting developer/root access to the TCL Flip 2. Since this phone is built off of android

## 0. Prerequisite: Computer setup (Mac)

1. clone this repository and go into it. Also make sure you have python with pyserial installed, as well as android platform tools for adb and fastboot:

```bash
git clone https://github.com/Offline-DC/dumb-phone-configuration.git
cd dumb-phone-configuration

brew install android-platform-tools
python3 -m pip install --user pyserial
```

2. Download APK files [here](https://drive.google.com/file/d/1-NKsyu-QicYRtTOZXG2yWKrFmKFPoKOx/view?usp=sharing). Unzip and place them into the folder `apk/`

### 1. Run the install steps

1. Make sure phone is turned completely off and plugged in.

2. Run the below script, then plug your phone in.

```bash

# PETE VERSION:
./full_flash.sh --version pete

```

**Follow the instructions in the command line throughout**
