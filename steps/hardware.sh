# GPU drivers and power tweaks:
#   ThinkPad P14s Gen 4 -> NVIDIA RTX A500 switched off, because it is defective;
#                          USB controllers (XHCI) can't wake it from suspend, because they kept waking it;
#                          xe driver instead of i915, which caused problems (newer Intel GPUs use xe already)
#   any other NVIDIA    -> proprietary NVIDIA driver
#
# The base step's upgrade can install a newer kernel without a restart before this step, so kernel
# modules and arguments are handled for the kernel the next boot starts, not the running one.

# Version of the default boot kernel, e.g. 7.2.15-300.fc45.x86_64
boot_kernel() {
  local path
  path="$(sudo grubby --default-kernel)"
  echo "${path#/boot/vmlinuz-}"
}

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
  local device_id kernel boot_args
  device_id="$(gpu_device_id 0x8086)"
  kernel="$(boot_kernel)"
  boot_args="$(sudo grubby --info=DEFAULT)"

  if ! modinfo -k "$kernel" xe >/dev/null 2>&1; then
    echo "Kernel $kernel has no xe module, keeping i915."
    return 0
  fi

  # xe only binds to pre-Lunar Lake GPUs when forced, and i915 has to be told to let go of the device
  if [[ "$boot_args" != *"xe.force_probe=$device_id"* ]]; then
    sudo grubby --update-kernel=ALL --args="i915.force_probe=!$device_id xe.force_probe=$device_id"
    echo "To go back to i915: sudo grubby --update-kernel=ALL --remove-args=\"i915.force_probe xe.force_probe\""
    needs_restart "xe driver enabled for device $device_id"
  fi
}

# Proprietary NVIDIA driver from RPM Fusion, for cards the current driver branch supports (GTX 16xx and newer)
nvidia_driver() {
  # With Secure Boot the kernel refuses the unsigned module and the desktop falls back to nouveau
  if mokutil --sb-state 2>/dev/null | grep -q "SecureBoot enabled"; then
    die "Secure Boot is enabled, so the NVIDIA module wouldn't load. Turn it off in the firmware settings and run this step again."
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
  local kernel
  kernel="$(boot_kernel)"
  echo "Building the NVIDIA kernel module for $kernel, this can take a few minutes..."
  sudo akmods --kernels "$kernel"
  if ! modinfo -k "$kernel" -F version nvidia >/dev/null 2>&1; then
    die "The NVIDIA kernel module was not built for $kernel. See /var/cache/akmods/nvidia/ for the build log."
  fi
  echo "NVIDIA driver $(modinfo -k "$kernel" -F version nvidia) installed."
  needs_restart "NVIDIA driver installed"
}

echo "Detected: $(hostnamectl chassis 2>/dev/null || echo desktop)"

if is_p14s_gen4; then
  disable_nvidia
  disable_usb_wakeup
  intel_xe_driver
elif has_gpu 0x10de; then
  nvidia_driver
fi
