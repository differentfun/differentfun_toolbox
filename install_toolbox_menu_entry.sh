#!/bin/bash

# Get the absolute path of this script
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAUNCHER="$ROOT_DIR/main.sh"
DESKTOP_FILE="/usr/share/applications/df-toolbox-launcher.desktop"
ICON_PATH="$ROOT_DIR/toolbox/icon.png"
SUDO_HELPER="$ROOT_DIR/requirements/sudo_utils.sh"

# Load sudo helper (GUI-friendly); fall back to plain sudo if missing.
if [[ -f "$SUDO_HELPER" ]]; then
  # shellcheck source=/dev/null
  source "$SUDO_HELPER"
else
  run_sudo() { sudo "$@"; }
fi

# Check if launcher script exists
if [[ ! -f "$LAUNCHER" ]]; then
  echo "Launcher script not found at: $LAUNCHER"
  exit 1
fi

# If icon not found, fallback to system icon
if [[ ! -f "$ICON_PATH" ]]; then
  ICON_PATH="utilities-terminal"  # system fallback
fi

# Create the .desktop file
cat > /tmp/df-toolbox-launcher.desktop <<EOF
[Desktop Entry]
Name=DifferentFun Toolbox
Comment=Launch the multimedia toolbox
Exec=$LAUNCHER
Icon=$ICON_PATH
Terminal=false
Type=Application
Categories=Utility;AudioVideo;
EOF
run_sudo mv /tmp/df-toolbox-launcher.desktop "$DESKTOP_FILE"

# Set correct permissions
run_sudo chmod 644 "$DESKTOP_FILE"

echo "✅ Menu entry created at: $DESKTOP_FILE"
