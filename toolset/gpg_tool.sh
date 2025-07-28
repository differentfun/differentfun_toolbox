#!/bin/bash

# Check for Zenity
if ! command -v zenity &> /dev/null; then
    echo "Zenity is not installed. Please install it first."
    exit 1
fi

# Check if gpg-agent is caching
check_gpg_agent() {
    gpg-connect-agent "GET_PASSPHRASE --no-ask" /bye > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        zenity --info --title="GPG Agent" --text="🔐 GPG agent is active. Passphrase may be cached."
    else
        zenity --warning --title="GPG Agent" --text="❗ GPG agent is not caching your passphrase.\nYou will be prompted for it."
    fi
}

# Encrypt a single file
encrypt_file() {
    input_file=$(zenity --file-selection --title="Select a file to encrypt")
    [ -z "$input_file" ] && exit 0
    gpg -c "$input_file"
    if [ $? -eq 0 ]; then
        zenity --question --text="✅ Encrypted: $input_file.gpg\n\nDo you want to delete the original file?"
        [ $? -eq 0 ] && rm "$input_file"
    else
        zenity --error --text="❌ Encryption failed."
    fi
}

# Decrypt a single file
decrypt_file() {
    input_file=$(zenity --file-selection --title="Select a .gpg file to decrypt")
    [ -z "$input_file" ] && exit 0
    if [[ "$input_file" != *.gpg ]]; then
        zenity --error --text="❌ File must have a .gpg extension."
        exit 1
    fi
    output_file="${input_file%.gpg}"
    gpg -d "$input_file" > "$output_file"
    if [ $? -eq 0 ]; then
        zenity --info --text="✅ Decrypted: $output_file"
    else
        zenity --error --text="❌ Decryption failed."
    fi
}

# Encrypt all files in a folder recursively (batch mode with one passphrase)
encrypt_folder_files() {
    folder=$(zenity --file-selection --directory --title="Select a folder to encrypt its files")
    [ -z "$folder" ] && exit 0

    # Ask once for the passphrase
    passphrase=$(zenity --password --title="Enter a passphrase to use for all files")
    [ -z "$passphrase" ] && exit 0

    # Encrypt all files (excluding .gpg) using batch mode
    find "$folder" \( -type f -not -name "*.gpg" \) -print0 | while IFS= read -r -d '' file; do
        echo "$passphrase" | gpg --batch --yes --passphrase-fd 0 -c "$file" && echo "Encrypted: $file.gpg"
    done

    # Ask if user wants to delete originals
    zenity --question --text="✅ All files encrypted.\n\nDo you want to delete the original files?"
    if [ $? -eq 0 ]; then
        find "$folder" \( -type f -not -name "*.gpg" \) -exec rm -f {} \;
        zenity --info --text="🗑️ Original files deleted."
    fi
}


# Decrypt all .gpg files in a folder recursively (with one passphrase)
decrypt_folder_files() {
    folder=$(zenity --file-selection --directory --title="Select a folder to decrypt its .gpg files")
    [ -z "$folder" ] && exit 0

    # Ask once for the passphrase
    passphrase=$(zenity --password --title="Enter the passphrase to decrypt files")
    [ -z "$passphrase" ] && exit 0

    # Decrypt all .gpg files using batch mode
    find "$folder" -type f -name "*.gpg" -print0 | while IFS= read -r -d '' file; do
        output_file="${file%.gpg}"
        echo "$passphrase" | gpg --batch --yes --passphrase-fd 0 -d "$file" > "$output_file" \
            && echo "Decrypted: $output_file"
    done

    # Ask if user wants to delete the encrypted files
    zenity --question --text="✅ All .gpg files decrypted.\n\nDo you want to delete the encrypted files?"
    if [ $? -eq 0 ]; then
        find "$folder" -type f -name "*.gpg" -exec rm -f {} \;
        zenity --info --text="🗑️ Encrypted files deleted."
    fi
}


# Main menu
check_gpg_agent

action=$(zenity --list --radiolist \
  --title="GPG Tool" \
  --text="What would you like to do?" \
  --width=500 --height=300 \
  --column="Select" --column="Action" \
  TRUE "Encrypt a single file" \
  FALSE "Decrypt a single .gpg file" \
  FALSE "Encrypt all files in a folder (recursively)" \
  FALSE "Decrypt all .gpg files in a folder (recursively)")

case "$action" in
    "Encrypt a single file")
        encrypt_file
        ;;
    "Decrypt a single .gpg file")
        decrypt_file
        ;;
    "Encrypt all files in a folder (recursively)")
        encrypt_folder_files
        ;;
    "Decrypt all .gpg files in a folder (recursively)")
        decrypt_folder_files
        ;;
    *)
        exit 0
        ;;
esac
