#!/bin/bash

# Show initial GUI notice
zenity --info \
  --title="Running Installer in Terminal" \
  --text="📢 This installer will run in the terminal.\n\nPlease check the terminal output for progress and possible errors."

echo -e "\n=== [ DifferentFun Toolbox Requirements Installer - Arch ] ==="

# Check for zenity
if ! command -v zenity >/dev/null 2>&1; then
  echo "❌ Zenity is not installed. Install it with: sudo pacman -S zenity"
  exit 1
fi

# Ask for sudo
echo -e "\n🔐 Asking for sudo access..."
sudo true || exit 1

# Update and install
echo -e "\n🔄 Updating package list..."
sudo pacman -Sy --noconfirm

echo -e "\n📦 Installing packages:"
echo "    - ffmpeg"
echo "    - pngquant"
echo "    - p7zip"
echo "    - cdrtools"
echo "    - zip"
echo "    - coreutils"
echo "    - gnupg"
echo ""

sudo pacman -S --noconfirm ffmpeg pngquant p7zip cdrtools zip coreutils gnupg

# Verify
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
