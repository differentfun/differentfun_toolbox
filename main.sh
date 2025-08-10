#!/bin/bash

# Check if Zenity is installed
if ! command -v zenity >/dev/null; then
  echo "Zenity is required but not installed. Please install it first."
  exit 1
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLSET_DIR="$ROOT_DIR/toolset"
REQ_DIR="$ROOT_DIR/requirements"

# Check folders
if [[ ! -d "$TOOLSET_DIR" ]]; then
  zenity --error --title="Toolset not found" --text="The folder 'toolset' was not found in:\n$ROOT_DIR"
  exit 1
fi

if [[ ! -d "$REQ_DIR" ]]; then
  zenity --error --title="Requirements directory not found" --text="The folder 'requirements' was not found in:\n$ROOT_DIR"
  exit 1
fi

# Make scripts executable
chmod +x "$TOOLSET_DIR"/*.sh 2>/dev/null
chmod +x "$REQ_DIR"/*.sh 2>/dev/null

# Prompt to install requirements
if zenity --question --title="Install Requirements?" --text="Do you want to install requirements before launching the toolbox?"; then
  req_selection=$(zenity --list \
    --title="Select Your Distribution" \
    --width=400 --height=250 \
    --column="Installer" \
    "Install Requirements for Debian" \
    "Install Requirements for Fedora" \
    "Install Requirements for Arch" \
    "Install Requirements for openSUSE")

  [[ -z "$req_selection" ]] && exit 0

  case "$req_selection" in
    "Install Requirements for Debian") script="$REQ_DIR/requirements_debian.sh" ;;
    "Install Requirements for Fedora") script="$REQ_DIR/requirements_fedora.sh" ;;
    "Install Requirements for Arch") script="$REQ_DIR/requirements_arch.sh" ;;
    "Install Requirements for openSUSE") script="$REQ_DIR/requirements_opensuse.sh" ;;
    *) zenity --error --text="Invalid selection."; exit 1 ;;
  esac

  if [[ -x "$script" ]]; then
    "$script"
  else
    zenity --error --text="Installer script not found or not executable:\n$script"
  fi
fi

# --- MAIN MENU LOOP ---
while true; do
  category=$(zenity --list \
    --title="DifferentFun Multimedia Toolbox (Zenity GUI)" \
    --width=500 --height=300 \
    --column="Category" \
    "Audio / Video / Images" \
    "ISO Tools" \
    "ZIP Tools" \
    "Crypt & Decrypt Utils" \
    "Git & Dev" \
    "Look for Toolbox Updates")

  [[ -z "$category" ]] && break

  script=""
  tool=""

  case "$category" in
    "Audio / Video / Images")
      tool=$(zenity --list \
        --title="$category" \
        --width=400 --height=400 \
        --column="Tool" \
        "PNG Compressor" \
        "Audio Converter" \
        "YaBridge Manager" \
        "Image Converter" \
        "Video Converter" \
        "Video To Frames" \
        "Frames To Video" \
        "Reverse Image Search" \
        "Upload Image Online" \
        "Download from YouTube" \
        "Recursive File Date Changer")
      case "$tool" in
        "PNG Compressor") script="$TOOLSET_DIR/png_compressor.sh" ;;
        "Audio Converter") script="$TOOLSET_DIR/audio_converter.sh" ;;
        "YaBridge Manager") script="$TOOLSET_DIR/yabridge-manager.sh" ;;
        "Image Converter") script="$TOOLSET_DIR/image_converter.sh" ;;
        "Video Converter") script="$TOOLSET_DIR/video_converter.sh" ;;
        "Video To Frames") script="$TOOLSET_DIR/video_to_frames.sh" ;;
        "Frames To Video") script="$TOOLSET_DIR/frames_to_video.sh" ;;
        "Reverse Image Search") script="$TOOLSET_DIR/reverse_image_research.sh" ;;
        "Upload Image Online") script="$TOOLSET_DIR/image_uploader.sh" ;;
        "Download from YouTube") script="$TOOLSET_DIR/youtube_downloader.sh" ;;
        "Recursive File Date Changer") script="$TOOLSET_DIR/recursive_date_changer.sh" ;;
      esac
      ;;

    "ISO Tools")
      tool=$(zenity --list \
        --title="$category" \
        --width=400 --height=200 \
        --column="Tool" \
        "Create ISO From Folder" \
        "Unpack ISO To Folder")
      case "$tool" in
        "Create ISO From Folder") script="$TOOLSET_DIR/create_iso.sh" ;;
        "Unpack ISO To Folder") script="$TOOLSET_DIR/extract_iso.sh" ;;
      esac
      ;;

    "ZIP Tools")
      tool=$(zenity --list \
        --title="$category" \
        --width=400 --height=200 \
        --column="Tool" \
        "Create a splitted archive" \
        "Recombine a splitted archive")
      case "$tool" in
        "Create a splitted archive") script="$TOOLSET_DIR/zip_splitter.sh" ;;
        "Recombine a splitted archive") script="$TOOLSET_DIR/zip_recombine.sh" ;;
      esac
      ;;

    "Crypt & Decrypt Utils")
      script="$TOOLSET_DIR/gpg_tool.sh"
      ;;

    "Git & Dev")
      script="$TOOLSET_DIR/git_tools.sh"
      ;;

    "Look for Toolbox Updates")
      if [[ -d "$ROOT_DIR/.git" ]]; then
        cd "$ROOT_DIR" || exit 1
        git remote update > /dev/null 2>&1
        LOCAL=$(git rev-parse @)
        REMOTE=$(git rev-parse @{u})
        BASE=$(git merge-base @ @{u})

        if [[ $LOCAL = $REMOTE ]]; then
          zenity --info --title="Toolbox Update" --text="The toolbox is already up to date."
        elif [[ $LOCAL = $BASE ]]; then
          if git pull --ff-only; then
            zenity --info --title="Toolbox Updated" --text="The toolbox has been updated."
            chmod +x "$TOOLSET_DIR"/*.sh 2>/dev/null
          else
            zenity --error --title="Update Failed" --text="Failed to update toolbox."
          fi
        else
          zenity --warning --title="Manual Update Needed" \
            --text="Your local changes conflict with remote. Please update manually."
        fi
      else
        zenity --error --title="Not a Git Repository" \
          --text="The toolbox folder is not a Git repository.\nYou can clone it with:\n\n  git clone https://github.com/differentfun/differentfun_toolbox"
      fi
      ;;
  esac

  # Execute selected script
  if [[ -n "$script" && -x "$script" ]]; then
    "$script"
  elif [[ -n "$script" ]]; then
    zenity --error --text="Script not executable:\n$script"
  fi

  # Ask to continue or exit
  if ! zenity --question --title="Continue?" --text="Do you want to return to the toolbox menu?"; then
    break
  fi
done
