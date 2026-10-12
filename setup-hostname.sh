#!/usr/bin/env bash
set -euo pipefail

read -p "PC name (current: $(hostnamectl hostname), leave empty to keep): " PC_NAME
if [[ -n "$PC_NAME" ]]; then
  # Sets the pretty name as typed, and derives the static hostname from it (spaces and special characters removed)
  sudo hostnamectl hostname "$PC_NAME"
  echo "PC name set to $(hostnamectl hostname). RESTART for it to show up everywhere."
fi
