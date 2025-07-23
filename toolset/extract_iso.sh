#!/bin/bash

ISO=$(zenity --file-selection --title="Select ISO file to extract")
[[ -z "$ISO" ]] && exit 0

DEST=$(zenity --file-selection --directory --title="Select destination folder")
[[ -z "$DEST" ]] && exit 0

(
  echo "0"
  sleep 0.5
  7z x "$ISO" -o"$DEST" -y | while read -r line; do
    echo "# $line"
  done
  echo "100"
) | zenity --progress --title="Extracting ISO" --auto-close --auto-kill --text="Extracting files..."

if [[ $? -eq 0 ]]; then
  zenity --info --text="ISO extracted to:\n$DEST"
else
  zenity --error --text="Error extracting ISO."
fi
