#!/usr/bin/env bash
set -euo pipefail

# ---------- xe driver instead of i915 ----------
# PCI device ID of the Intel display controller, e.g. a7a0
DEVICE_ID=""
for dev in /sys/bus/pci/devices/*; do
  if [ "$(<"$dev/vendor")" = "0x8086" ] && [[ "$(<"$dev/class")" == 0x03* ]]; then
    DEVICE_ID="$(<"$dev/device")"
    DEVICE_ID="${DEVICE_ID#0x}"
    break
  fi
done

if [ -z "$DEVICE_ID" ]; then
  echo "No Intel GPU found."
  exit 1
fi

if ! modinfo xe >/dev/null 2>&1; then
  echo "The running kernel has no xe module."
  exit 1
fi

# xe only binds to pre-Lunar Lake GPUs when forced, and i915 has to be told to let go of the device
sudo grubby --update-kernel=ALL --args="i915.force_probe=!$DEVICE_ID xe.force_probe=$DEVICE_ID"

echo "xe driver enabled for device $DEVICE_ID. Please RESTART your PC."
echo "To go back to i915: sudo grubby --update-kernel=ALL --remove-args=\"i915.force_probe xe.force_probe\""
