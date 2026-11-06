# GPU drivers and power tweaks, chosen from the detected hardware:
#   laptop with NVIDIA  -> NVIDIA GPU switched off (Intel only, better battery)
#   laptop              -> USB controllers (XHCI) can't wake it from suspend
#   laptop with Intel   -> xe driver instead of i915
#   desktop with NVIDIA -> proprietary NVIDIA driver
# Runs after the base step's restart, so the running kernel is the latest one.

apply_nvidia_isolation() {
  sudo udevadm control --reload-rules
  sudo udevadm trigger
  echo "Regenerating initramfs images..."
  sudo dracut --regenerate-all --force
  needs_restart "NVIDIA GPU switched off"
}

disable_nvidia() {
  put etc/udev/rules.d/00-remove-nvidia.rules etc/modprobe.d/blacklist-nvidia.conf -- apply_nvidia_isolation
}

disable_usb_wakeup() {
  put etc/tmpfiles.d/disable-wakeup.conf -- needs_restart "USB wakeup disabled"
}

intel_xe_driver() {
  local device_id
  device_id="$(gpu_device_id 0x8086)"

  if ! modinfo xe >/dev/null 2>&1; then
    echo "The running kernel has no xe module, keeping i915."
    return 0
  fi

  # xe only binds to pre-Lunar Lake GPUs when forced, and i915 has to be told to let go of the device
  if ! grep -q "xe.force_probe=$device_id" /proc/cmdline; then
    sudo grubby --update-kernel=ALL --args="i915.force_probe=!$device_id xe.force_probe=$device_id"
    echo "To go back to i915: sudo grubby --update-kernel=ALL --remove-args=\"i915.force_probe xe.force_probe\""
    needs_restart "xe driver enabled for device $device_id"
  fi
}

# Proprietary NVIDIA driver from RPM Fusion, for cards the current driver branch supports (GTX 16xx and newer)
nvidia_driver() {
  # ---------- Secure Boot ----------
  # The kernel refuses unsigned modules, so akmods needs a signing key that the firmware trusts
  if mokutil --sb-state 2>/dev/null | grep -q "SecureBoot enabled"; then
    local mok_cert="/etc/pki/akmods/certs/public_key.der"
    sudo dnf install -y akmods mokutil openssl
    sudo test -e "$mok_cert" || sudo kmodgenca -a
    if ! sudo mokutil --test-key "$mok_cert" | grep -q "already enrolled"; then
      echo "Secure Boot is enabled. Choose a one-time password now, then on the next boot pick 'Enroll MOK' and type it in."
      sudo mokutil --import "$mok_cert"
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
    die "The NVIDIA kernel module was not built for $(uname -r). See /var/cache/akmods/nvidia/ for the build log."
  fi
  echo "NVIDIA driver $(modinfo -F version nvidia) installed."
  needs_restart "NVIDIA driver installed"
}

if is_laptop; then
  echo "Detected: laptop"
  if has_gpu 0x10de && confirm "Switch off the NVIDIA GPU?"; then
    disable_nvidia
  fi
  if confirm "Stop USB controllers from waking the laptop from suspend?"; then
    disable_usb_wakeup
  fi
  if has_gpu 0x8086 && confirm "Use the xe driver for the Intel GPU?"; then
    intel_xe_driver
  fi
else
  echo "Detected: $(hostnamectl chassis 2>/dev/null || echo desktop)"
  if has_gpu 0x10de && confirm "Install the proprietary NVIDIA driver?"; then
    nvidia_driver
  fi
fi
