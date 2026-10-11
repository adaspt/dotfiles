#!/usr/bin/env bash
set -euo pipefail

# Proprietary NVIDIA driver from RPM Fusion, for cards the current driver branch supports (GTX 16xx and newer).
# Run after setup.sh and a restart, so the running kernel is the latest one.

HAS_NVIDIA=""
for dev in /sys/bus/pci/devices/*; do
  if [ "$(<"$dev/vendor")" = "0x10de" ] && [[ "$(<"$dev/class")" == 0x03* ]]; then
    HAS_NVIDIA=1
    break
  fi
done

if [ -z "$HAS_NVIDIA" ]; then
  echo "No NVIDIA GPU found."
  exit 1
fi

# ---------- Secure Boot ----------
# The kernel refuses unsigned modules, so akmods needs a signing key that the firmware trusts
if mokutil --sb-state 2>/dev/null | grep -q "SecureBoot enabled"; then
  MOK_CERT="/etc/pki/akmods/certs/public_key.der"
  sudo dnf install -y akmods mokutil openssl
  sudo test -e "$MOK_CERT" || sudo kmodgenca -a
  if ! sudo mokutil --test-key "$MOK_CERT" | grep -q "already enrolled"; then
    echo "Secure Boot is enabled. Choose a one-time password now, then on the next boot pick 'Enroll MOK' and type it in."
    sudo mokutil --import "$MOK_CERT"
  fi
fi

# ---------- Driver ----------
# RPM Fusion's NVIDIA repo comes with fedora-workstation-repositories, disabled unless third-party repos were enabled at install
sudo dnf config-manager setopt rpmfusion-nonfree-nvidia-driver.enabled=1
# akmod-nvidia: kernel module, rebuilt for every new kernel
# xorg-x11-drv-nvidia-cuda: nvidia-smi and NVENC/NVDEC
# libva-nvidia-driver: VA-API video decoding (browsers, video players)
sudo dnf install -y akmod-nvidia xorg-x11-drv-nvidia-cuda libva-nvidia-driver

# ---------- Kernel module ----------
# Build now instead of on the next boot, so a failed build shows up before the restart
echo "Building the NVIDIA kernel module, this can take a few minutes..."
sudo akmods --kernels "$(uname -r)"
if ! modinfo -F version nvidia >/dev/null 2>&1; then
  echo "The NVIDIA kernel module was not built for $(uname -r). See /var/cache/akmods/nvidia/ for the build log."
  exit 1
fi

echo "NVIDIA driver $(modinfo -F version nvidia) installed. Please RESTART your PC."
