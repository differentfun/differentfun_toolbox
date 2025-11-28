#!/bin/bash

# Shared sudo wrapper that falls back to a GUI password prompt when no TTY is present.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ASKPASS="$SCRIPT_DIR/sudo_askpass.sh"

# Run sudo with askpass if stdout is not a terminal.
run_sudo() {
  if [ -t 1 ]; then
    sudo "$@"
    return $?
  fi

  if [[ -x "$ASKPASS" ]]; then
    SUDO_ASKPASS="$ASKPASS" sudo -A "$@"
    return $?
  fi

  if command -v zenity >/dev/null 2>&1; then
    zenity --error \
      --title="Cannot Elevate Privileges" \
      --text="Missing askpass helper:\n$ASKPASS"
  else
    echo "Cannot elevate privileges because askpass helper is missing: $ASKPASS" >&2
  fi
  return 1
}
