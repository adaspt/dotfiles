# PC name. The base step after it asks for a restart, which makes the new name show up everywhere.

read -rp "PC name (current: $(hostnamectl hostname), leave empty to keep): " PC_NAME
if [[ -n "$PC_NAME" ]]; then
  # Sets the pretty name as typed, and derives the static hostname from it (spaces and special characters removed)
  sudo hostnamectl hostname "$PC_NAME"
  echo "PC name set to $(hostnamectl hostname)."
fi
