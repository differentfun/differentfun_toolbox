#!/bin/bash

FOLDER=$(zenity --file-selection --directory --title="Select folder to create ISO from")
[[ -z "$FOLDER" ]] && exit 0

OUT=$(zenity --file-selection --save --confirm-overwrite --title="Save ISO as" --filename="output.iso")
[[ -z "$OUT" ]] && exit 0

(
  echo "0"
  sleep 0.5
  mkisofs -o "$OUT" -J -R "$FOLDER" 2>&1 | while read -r line; do
    echo "# $line"
  done
  echo "100"
) | zenity --progress --title="Creating ISO" --auto-close --auto-kill --text="Building ISO..."

if [[ $? -eq 0 ]]; then
  zenity --info --text="ISO created successfully:\n$OUT"
else
  zenity --error --text="Error creating ISO."
fi
