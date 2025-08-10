#!/bin/bash

# Get the absolute path of this script
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAUNCHER="$ROOT_DIR/main.sh"
DESKTOP_FILE="/usr/share/applications/df-toolbox-launcher.desktop"
ICON_PATH="$ROOT_DIR/toolbox/icon.png"

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
sudo bash -c "cat > '$DESKTOP_FILE'" <<EOF
[Desktop Entry]
Name=DifferentFun Toolbox
Comment=Launch the multimedia toolbox
Exec=$LAUNCHER
Icon=$ICON_PATH
Terminal=true
Type=Application
Categories=Utility;AudioVideo;
EOF

# Set correct permissions
sudo chmod 644 "$DESKTOP_FILE"

echo "✅ Menu entry created at: $DESKTOP_FILE"
