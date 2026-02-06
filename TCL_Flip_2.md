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

2. Download APK files [here](https://drive.google.com/file/d/1IWL5lCAXYTrEpS8IhKjlE71zMbv-Tywd/view?usp=drive_link). Unzip and place them into the folder `apk/`

### 1. Run the install steps

Run the below scripts one at a time:

```bash
./flash_root.sh

# (Optional) Automate wifi connection
# Optional but helps automate wifi adding
./wifi_install.sh "YourSSID" "YourPassword" # Replace with your wifi/password

./install_magisk.sh

./add_apks.sh

./add_modules.sh

./setup_final_manual.sh
```

**Follow the instructions in the command line throughout**
