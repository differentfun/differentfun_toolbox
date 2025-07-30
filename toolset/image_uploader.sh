#!/bin/bash

# === SETTINGS ===
USER_AGENT="Mozilla/5.0 (X11; Linux x86_64)"
IMG_FILTER="*.png *.jpg *.jpeg *.webp *.gif"

# === FUNCTIONS ===
log_debug() {
    zenity --info --title="DEBUG" --text="$1"
}

upload_to_catbox() {
    curl -s -A "$USER_AGENT" -F "reqtype=fileupload" -F "fileToUpload=@$1" https://catbox.moe/user/api.php
}

open_tab() {
    xdg-open "$1" >/dev/null 2>&1 & disown
}

# === MAIN ===
img=$(zenity --file-selection --title="Select an image for reverse image search" --file-filter="Images | $IMG_FILTER")
[ -z "$img" ] && exit 0

#log_debug "Selected image:\n$img"

#zenity --info --text="Uploading image to catbox.moe..."
url=$(upload_to_catbox "$img")
#log_debug "Catbox response:\n$url"

if [[ "$url" =~ ^https?://.* ]]; then
    zenity --info --title="Success, uploaded" --text="$url"
else
    zenity --error --text="Image upload failed.\nPlease check your internet connection."
    exit 1
fi

exit 0
