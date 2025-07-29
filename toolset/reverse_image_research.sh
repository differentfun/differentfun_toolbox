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

open_search_engines() {
    local url="$1"
    
    # URL encode once for services that require it
    encoded_url=$(python3 -c "import urllib.parse; print(urllib.parse.quote('''$url'''))")
    
    open_tab "https://yandex.com/images/search?rpt=imageview&url=$url"
    open_tab "https://tineye.com/search?url=$url"
    open_tab "https://www.bing.com/images/searchbyimage?cbir=sbi&imgurl=$url"
    open_tab "https://iqdb.org/?url=$url"
    open_tab "https://saucenao.com/search.php?url=$url"
    open_tab "https://karmadecay.com/search?q=$encoded_url"
    open_tab "https://repostsleuth.com/search?url=$encoded_url"
}

# === MAIN ===
img=$(zenity --file-selection --title="Select an image for reverse image search" --file-filter="Images | $IMG_FILTER")
[ -z "$img" ] && exit 0

log_debug "Selected image:\n$img"

zenity --info --text="Uploading image to catbox.moe..."
url=$(upload_to_catbox "$img")
log_debug "Catbox response:\n$url"

if [[ "$url" =~ ^https?://.* ]]; then
    zenity --info --text="Image uploaded successfully.\n\nURL:\n$url"
    open_search_engines "$url"
else
    zenity --error --text="Image upload failed.\nPlease check your internet connection."
    exit 1
fi

exit 0
