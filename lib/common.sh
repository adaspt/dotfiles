# Helpers shared by ./install and the steps. Sourced, not run.
# DOTFILES_DIR is set by ./install before this file is sourced.

die() {
  echo "$*" >&2
  exit 1
}

# needs_restart "reason" - ./install lists the reason at the end and asks for one restart
needs_restart() {
  echo "$*" >> "$RESTART_FILE"
}

# install_packages NAME - dnf install everything listed in packages/NAME.txt
install_packages() {
  local pkgs
  mapfile -t pkgs < <(sed 's/#.*//' "$DOTFILES_DIR/packages/$1.txt" | xargs -n1)
  sudo dnf install -y "${pkgs[@]}"
}

# link SRC DEST - symlink a file from the repo (SRC is relative to it) into place
link() {
  mkdir -p "$(dirname "$2")"
  ln -sfn "$DOTFILES_DIR/$1" "$2"
}

# put PATH... [-- COMMAND...] - copy files/PATH to /PATH as root, then run COMMAND if any file changed:
#   put etc/sysctl.d/foo.conf -- sudo sysctl --system
# COMMAND can be a function defined in the step. If it fails, the step fails, and the next run
# retries it even though the files are now up to date (a pending marker remembers it).
# Call it as a plain statement, never as `if put ...` or `put ... || ...`: bash switches off
# `set -e` inside anything used as a condition, so failures would go unnoticed.
put() {
  local files=() file changed=""
  while [ $# -gt 0 ] && [ "$1" != "--" ]; do
    files+=("$1")
    shift
  done
  [ $# -gt 0 ] && shift # the --

  for file in "${files[@]}"; do
    cmp -s "$DOTFILES_DIR/files/$file" "/$file" && continue
    echo "Installing /$file"
    sudo install -Dm644 "$DOTFILES_DIR/files/$file" "/$file" || die "Failed to install /$file"
    changed=1
  done

  [ $# -gt 0 ] || return 0
  local pending="$STATE_DIR/pending/$(printf '%s+' "${files[@]}" | tr '/' '_')"
  [ -n "$changed" ] || [ -f "$pending" ] || return 0
  mkdir -p "$(dirname "$pending")"
  touch "$pending"
  "$@"
  rm -f "$pending"
}

# has_gpu VENDOR_ID - true when a display controller from that PCI vendor is present (0x8086 Intel, 0x10de NVIDIA)
has_gpu() {
  local dev
  for dev in /sys/bus/pci/devices/*; do
    [ "$(<"$dev/vendor")" = "$1" ] && [[ "$(<"$dev/class")" == 0x03* ]] && return 0
  done
  return 1
}

# gpu_device_id VENDOR_ID - PCI device ID of that vendor's display controller, e.g. a7a0
gpu_device_id() {
  local dev id
  for dev in /sys/bus/pci/devices/*; do
    if [ "$(<"$dev/vendor")" = "$1" ] && [[ "$(<"$dev/class")" == 0x03* ]]; then
      id="$(<"$dev/device")"
      echo "${id#0x}"
      return 0
    fi
  done
  return 1
}

# is_p14s_gen4 - true on the ThinkPad P14s Gen 4 (Intel, machine type 21HF). Its NVIDIA RTX A500 is
# defective, its USB controllers kept waking it from suspend, and i915 caused problems
is_p14s_gen4() {
  [[ "$(cat /sys/class/dmi/id/product_name 2>/dev/null)" == 21HF* ]]
}

# power_type - "laptop" when the PC has a battery, else "desktop". Picks the suspend settings,
# files/etc/dconf/db/gdm.d/00-power-TYPE
power_type() {
  if compgen -G "/sys/class/power_supply/BAT*" > /dev/null; then echo laptop; else echo desktop; fi
}

# nvidia_needs_driver - true when an NVIDIA GPU is present that should get the proprietary driver:
# any, except on the P14s Gen 4, where it is switched off
nvidia_needs_driver() {
  has_gpu 0x10de && ! is_p14s_gen4
}
