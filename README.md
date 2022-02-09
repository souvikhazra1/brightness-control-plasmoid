# Brightness Control Plasmoid
Simple plasmoid to control brightness of external monitors using DDC

# Prerequisites
* Install `ddcutil`
* Add your current user to i2c group `sudo usermod -a -G i2c your-username`. To know your username run `whoami` without `sudo`.
* Now logout and login or allow full r/w to i2c devices for current session `sudo chmod a+rw /dev/i2c-*`.

# Installation
* Before installation run `ddcutil detect` to check if it detects any supported monitor.
* Install `cmake`, `extra-cmake-modules` and `make` as build tools.
* Use `install.sh` and `uninstall.sh` to install and uninstall.

---
# Screenshots

![Screenshot 1](screenshots/1.png?raw=true)