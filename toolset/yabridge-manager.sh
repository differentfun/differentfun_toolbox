#!/bin/bash

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SUDO_HELPER="$ROOT_DIR/requirements/sudo_utils.sh"
# shellcheck source=/dev/null
if [[ -f "$SUDO_HELPER" ]]; then
    source "$SUDO_HELPER"
else
    run_sudo() { sudo "$@"; }
fi

YABRIDGE_DIR="$HOME/.local/share/yabridge"
YABRIDGE_BIN="$YABRIDGE_DIR/yabridgectl"
RELEASE_URL="https://github.com/robbert-vdh/yabridge/releases/download/5.1.1/yabridge-5.1.1.tar.gz"

function install_yabridge() {
    zenity --question --text="Do you want to install or reinstall yabridge 5.1.1 now?"
    if [ $? -eq 0 ]; then
        mkdir -p "$YABRIDGE_DIR"
        TMPDIR=$(mktemp -d)
        cd "$TMPDIR" || exit 1
        echo "Downloading from $RELEASE_URL"
        wget "$RELEASE_URL"
        echo "Extracting to $YABRIDGE_DIR"
        tar -xavf yabridge-5.1.1.tar.gz -C "$YABRIDGE_DIR" --strip-components=1

        if ! echo "$PATH" | grep -q "$YABRIDGE_DIR"; then
            echo "export PATH=\"\$PATH:$YABRIDGE_DIR\"" >> "$HOME/.bashrc"
            export PATH="$PATH:$YABRIDGE_DIR"
            echo "Added $YABRIDGE_DIR to PATH"
        fi

        zenity --info --text="yabridge 5.1.1 installed successfully to:\n$YABRIDGE_DIR"
    fi
}

function fix_low_memory() {
    zenity --question --text="This will apply system-wide audio optimizations.\nContinue?"
    if [ $? -ne 0 ]; then return; fi

    echo "Adding user to audio group..."
    run_sudo usermod -aG audio "$USER"

    echo "Creating /etc/security/limits.d/audio.conf..."
    echo -e "@audio   -  rtprio     95\n@audio   -  memlock    unlimited\n@audio   -  nice       -19" | \
        run_sudo tee /etc/security/limits.d/audio.conf >/dev/null

    echo "Ensuring pam_limits is loaded..."
    if ! grep -q "pam_limits.so" /etc/pam.d/common-session; then
        echo "Adding 'session required pam_limits.so' to /etc/pam.d/common-session"
        echo "session required pam_limits.so" | run_sudo tee -a /etc/pam.d/common-session >/dev/null
    fi

    zenity --info --text="System audio limits updated.\n\nYou must **log out or reboot** to apply the changes."
}

function add_vst_dir() {
    DIR=$(zenity --file-selection --directory --title="Select a VST2 or VST3 directory to add")
    if [ -n "$DIR" ]; then
        echo "Adding VST directory: $DIR"
        "$YABRIDGE_BIN" add "$DIR"
        zenity --info --text="Directory added:\n$DIR"
    fi
}

function remove_vst_dir() {
    LIST=$("$YABRIDGE_BIN" list | awk '{print $1}')
    if [ -z "$LIST" ]; then
        zenity --info --text="No directories are currently added."
        return
    fi

    SELECTED=$(echo "$LIST" | zenity --list --title="Remove directory" --column="VST Directories" --height=300)
    if [ -n "$SELECTED" ]; then
        echo "Removing VST directory: $SELECTED"
        "$YABRIDGE_BIN" remove "$SELECTED"
        zenity --info --text="Removed:\n$SELECTED"
    fi
}

function clean_vsts() {
    zenity --question --text="Are you sure you want to remove all VST references?\n(This will not delete the plugins themselves)"
    if [ $? -eq 0 ]; then
        echo "Running: yabridgectl sync --clean"
        "$YABRIDGE_BIN" sync --clean
        zenity --info --text="All VST links cleaned."
    fi
}

function sync_vsts() {
    echo "Running: yabridgectl sync"
    "$YABRIDGE_BIN" sync
    zenity --info --text="VST plugins synced successfully."
}

function main_menu() {
    while true; do
        CHOICE=$(zenity --list --title="Yabridge Manager" \
            --column="Action" --height=400 --width=320 \
            "Install yabridge" \
            "Add VST directory" \
            "Remove VST directory" \
            "Clean all VSTs" \
            "Sync VSTs" \
            "Fix LowMemory" \
            "Exit")

        case "$CHOICE" in
            "Install yabridge") install_yabridge ;;
            "Add VST directory") add_vst_dir ;;
            "Remove VST directory") remove_vst_dir ;;
            "Clean all VSTs") clean_vsts ;;
            "Sync VSTs") sync_vsts ;;
            "Fix LowMemory") fix_low_memory ;;
            "Exit") break ;;
            *) break ;;
        esac
    done
}

if ! command -v yabridgectl &>/dev/null && [ ! -f "$YABRIDGE_BIN" ]; then
    install_yabridge
fi

if ! command -v yabridgectl &>/dev/null; then
    alias yabridgectl="$YABRIDGE_BIN"
fi

# ⚠️ Warning at startup
zenity --warning --title="⚠ Warning" --text="This script is tested ONLY on MX Linux!\nUse at your own risk."

main_menu
