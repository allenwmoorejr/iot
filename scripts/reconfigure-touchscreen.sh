#!/usr/bin/env bash
# Apply libinput/udev tuning to make common Raspberry Pi touchscreens feel more responsive.
# Run this on the Pi with sudo: sudo ./scripts/reconfigure-touchscreen.sh
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root (sudo)." >&2
  exit 1
fi

HWDB_PATH="/etc/udev/hwdb.d/99-car-touchscreen.hwdb"

cat >"${HWDB_PATH}" <<'HWDB'
# Touchscreen responsiveness tuning for the Raspberry Pi dashboard
# Applies to the official 7" DSI display (FT5406) and common Goodix/GT911 controllers.
evdev:name:FT5406*:dmi:*Raspberry_Pi*
 LIBINPUT_ATTR_TOUCH_SIZE_RANGE=0:3
 LIBINPUT_ATTR_PRESSURE_RANGE=0:15
 LIBINPUT_ATTR_PALM_PRESSURE_THRESHOLD=120
 LIBINPUT_ATTR_TOUCHSCREEN_SMOOTHING=true
 LIBINPUT_ATTR_TOUCHSCREEN_TAP_JITTER=8

# Goodix/GT911 fallback
# These devices are widely used on HDMI touch overlays and USB touch kits.
evdev:name:Goodix*:dmi:*Raspberry_Pi*|evdev:name:GT911*:dmi:*Raspberry_Pi*
 LIBINPUT_ATTR_TOUCH_SIZE_RANGE=0:3
 LIBINPUT_ATTR_PRESSURE_RANGE=0:15
 LIBINPUT_ATTR_PALM_PRESSURE_THRESHOLD=120
 LIBINPUT_ATTR_TOUCHSCREEN_SMOOTHING=true
 LIBINPUT_ATTR_TOUCHSCREEN_TAP_JITTER=8
HWDB

# Refresh udev database so the new attributes are picked up.
systemd-hwdb update
udevadm trigger /dev/input/event*

echo "Touchscreen tuning installed at ${HWDB_PATH}. Reboot to ensure the new libinput attributes take effect."
