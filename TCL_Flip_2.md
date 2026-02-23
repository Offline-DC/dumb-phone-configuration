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

2. Download APK files [here](https://drive.google.com/file/d/1C573TRqz1oozGWBFimsxKqb8U3BYYHny/view?usp=sharing). Unzip and place them into the folder `apk/`

### 1. Run the install steps

1. Make sure phone is turned completely off and plugged in.

2. Run the below script, then plug your phone in.

```bash

# Versions:
# 0.2.0 Pete version
# 0.3.0 March Alpha Version
./full_flash.sh --version "0.3.0"

```

**Follow the instructions in the command line throughout**
