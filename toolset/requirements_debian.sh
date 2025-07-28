#!/bin/bash

# Check for zenity
if ! command -v zenity >/dev/null 2>&1; then
  echo "Zenity is not installed. Please install it with: sudo apt install zenity"
  exit 1
fi

# Build installer command into a temporary script
INSTALL_SCRIPT=$(mktemp)

cat << 'EOF' > "$INSTALL_SCRIPT"
#!/bin/bash

apt update -y
apt install -y ffmpeg pngquant p7zip-full genisoimage zip coreutils gnupg
EOF

chmod +x "$INSTALL_SCRIPT"

# Run installer script with GUI sudo prompt
(
echo "10"
echo "# Requesting admin privileges..."
sleep 1

echo "30"
echo "# Installing required packages..."

if pkexec "$INSTALL_SCRIPT"; then
  echo "70"
  echo "# Verifying installed tools..."

  MISSING=""
  for cmd in ffmpeg pngquant 7z mkisofs; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      MISSING+="$cmd "
    fi
  done

  echo "100"
else
  echo "100"
  exit 1
fi

) | zenity --progress --title="Installing Requirements" \
  --text="Installing packages..." \
  --percentage=0 --auto-close --auto-kill

if [[ $? -eq 0 ]]; then
  if [[ -n "$MISSING" ]]; then
    zenity --warning --text="Installation finished, but the following commands were not found:\n$MISSING\nPlease check the terminal for any errors."
  else
    zenity --info --text="All requirements were successfully installed."
  fi
else
  zenity --error --text="Installation was cancelled or failed."
fi

rm -f "$INSTALL_SCRIPT"
