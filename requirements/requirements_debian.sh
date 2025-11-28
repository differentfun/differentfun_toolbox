#!/bin/bash

# Load sudo helper (GUI-friendly)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/sudo_utils.sh"

# Show initial GUI notice
zenity --info \
  --title="Installing Requirements" \
  --text="📢 The installer may ask for your password.\n\nLeave this window open until it finishes."

echo -e "\n=== [ DifferentFun Toolbox Requirements Installer - Debian ] ==="

# Check for zenity itself
if ! command -v zenity >/dev/null 2>&1; then
  echo "❌ Zenity is not installed. Install it with: sudo apt install zenity yt-dlp"
  exit 1
fi

# Ask for sudo once
echo -e "\n🔐 Asking for sudo access..."
run_sudo true || exit 1

# Update package list
echo -e "\n🔄 Updating package list..."
run_sudo apt update -y

# Install required packages
echo -e "\n📦 Installing packages:"
echo "    - ffmpeg"
echo "    - pngquant"
echo "    - p7zip-full"
echo "    - genisoimage"
echo "    - zip"
echo "    - coreutils"
echo "    - gnupg"
echo "    - yt-dlp"
echo ""

run_sudo apt install -y ffmpeg pngquant p7zip-full genisoimage zip coreutils gnupg yt-dlp 

# Verify installation
echo -e "\n🔎 Verifying installed tools..."
MISSING=""
for cmd in ffmpeg pngquant 7z mkisofs; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    MISSING+="$cmd "
  fi
done

if [[ -n "$MISSING" ]]; then
  echo -e "\n⚠️  Installation completed, but the following commands were not found:"
  echo "   $MISSING"
  exit 1
else
  echo -e "\n✅ All requirements successfully installed!"
fi
