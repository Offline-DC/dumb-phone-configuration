## TCL Flip 2 Configuration

This document tracks working solutions for installing apps and getting developer/root access to the TCL Flip 2. Since this phone is built off of android

## 0. Prerequisite: Computer setup (Mac)

1. clone this repository and go into it:

```bash
git clone https://github.com/Offline-DC/dumb-phone-configuration.git
cd dumb-phone-configuration

brew install android-platform-tools
python3 -m pip install --user pyserial
```

2. Download APK files [here](https://drive.google.com/file/d/1IWL5lCAXYTrEpS8IhKjlE71zMbv-Tywd/view?usp=drive_link) and place them into the folder `tclprovision/apk/`

### 1. Run the install steps

Run the below scripts one at a time. You can repeat steps as needed if there are issues:

```bash
./flash_root.sh

./build_tcl_provision_zip.sh # can skip after doing once

# Automate wifi setup
# Optional but helps automate wifi adding
./wifi_1_install_ime.sh
./wifi_2_connect.sh "YourSSID" "YourPassword"
./wifi_3_cleanup.sh

./finish_magisk.sh

./setup_final_manual.sh
```

**Follow the instructions in the command line throughout**
