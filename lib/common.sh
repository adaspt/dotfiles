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

# unlock_secrets - decrypt Backup/secrets.tar.gz.age from OneDrive into SECRETS_DIR, unless an earlier step
# of this ./install run already did. Asks for the age passphrase. Contents: ssh/ (for ~/.ssh), agersi-vpn.conf
unlock_secrets() {
  local archive="$HOME/OneDrive/Backup/secrets.tar.gz.age"
  [ ! -d "$SECRETS_DIR" ] || return 0
  [ -f "$archive" ] || die "$archive not found. Is OneDrive synced? See: journalctl --user -u onedrive"
  command -v age > /dev/null || sudo dnf install -y age
  # Into .part first, so a wrong passphrase doesn't leave a half-filled SECRETS_DIR behind
  rm -rf "$SECRETS_DIR.part"
  mkdir -m 700 "$SECRETS_DIR.part"
  age --decrypt "$archive" | tar -xz -C "$SECRETS_DIR.part"
  mv "$SECRETS_DIR.part" "$SECRETS_DIR"
}

# link_home - symlink every file in config/home to the same path under ~, e.g.
# config/home/.claude/CLAUDE.md -> ~/.claude/CLAUDE.md. Files, not folders, so ~/.claude keeps its own content
link_home() {
  local src="$DOTFILES_DIR/config/home" file rel
  while IFS= read -r -d '' file; do
    rel="${file#"$src/"}"
    mkdir -p "$(dirname "$HOME/$rel")"
    ln -sfn "$file" "$HOME/$rel"
  done < <(find "$src" -type f -print0)
}

# put PATH... [-- COMMAND...] - copy config/system/PATH to /PATH as root, then run COMMAND if any file changed:
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
    cmp -s "$DOTFILES_DIR/config/system/$file" "/$file" && continue
    echo "Installing /$file"
    sudo install -Dm644 "$DOTFILES_DIR/config/system/$file" "/$file" || die "Failed to install /$file"
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

# gpu_device_id VENDOR_ID - PCI device ID of that vendor's display controller, e.g. a7a0;
# fails when there is none (0x8086 Intel, 0x10de NVIDIA)
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

# has_gpu VENDOR_ID - true when a display controller from that PCI vendor is present
has_gpu() {
  gpu_device_id "$1" > /dev/null
}

# is_p14s_gen4 - true on the ThinkPad P14s Gen 4 (Intel, machine type 21HF). Its NVIDIA RTX A500 is
# defective, its USB controllers kept waking it from suspend, and i915 caused problems
is_p14s_gen4() {
  [[ "$(cat /sys/class/dmi/id/product_name 2>/dev/null)" == 21HF* ]]
}

# power_type - "laptop" when the PC has a battery, else "desktop". Picks the suspend settings,
# config/system/etc/dconf/db/gdm.d/00-power-TYPE
power_type() {
  if compgen -G "/sys/class/power_supply/BAT*" > /dev/null; then echo laptop; else echo desktop; fi
}

# nvidia_needs_driver - true when an NVIDIA GPU is present that should get the proprietary driver:
# any, except on the P14s Gen 4, where it is switched off
nvidia_needs_driver() {
  has_gpu 0x10de && ! is_p14s_gen4
}
