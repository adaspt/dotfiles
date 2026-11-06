# Helpers shared by ./install and the steps. Sourced, not run.
# DOTFILES_DIR is set by ./install before this file is sourced.

die() {
  echo "$*" >&2
  exit 1
}

# ask "Question?" - yes only when the answer is y/Y
ask() {
  local reply
  read -rp "$1 (y/N) " reply
  [[ "$reply" == [yY] ]]
}

# confirm "Question?" - yes unless the answer is n/N
confirm() {
  local reply
  read -rp "$1 (Y/n) " reply
  [[ "$reply" != [nN] ]]
}

# needs_restart "reason" - ./install stops after the current step and asks for a restart
needs_restart() {
  echo "$*" >> "$RESTART_FLAG"
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

is_laptop() {
  case "$(hostnamectl chassis 2>/dev/null)" in
    laptop | convertible | tablet) return 0 ;;
    *) return 1 ;;
  esac
}
