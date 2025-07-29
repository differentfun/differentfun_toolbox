#!/bin/bash

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLSET_DIR="$ROOT_DIR/toolset"

if [[ ! -d "$TOOLSET_DIR" ]]; then
  zenity --error --title="Toolset not found" --text="The folder 'toolset' was not found in:\n$ROOT_DIR"
  exit 1
fi

chmod +x "$TOOLSET_DIR"/*.sh 2>/dev/null

# Install requirements?
zenity --question \
  --title="Install Requirements?" \
  --text="Do you want to install requirements before launching the toolbox?"

if [[ $? -eq 0 ]]; then
  req_selection=$(zenity --list \
    --title="Select Your Distribution" \
    --width=400 --height=200 \
    --column="Installer" \
    "Install Requirements for Debian")

  [[ -z "$req_selection" ]] && exit 0

  case "$req_selection" in
    "Install Requirements for Debian") script="$TOOLSET_DIR/requirements_debian.sh" ;;
    *) zenity --error --text="Invalid selection." ; exit 1 ;;
  esac

  [[ -x "$script" ]] && "$script" || zenity --error --text="Installer script not found or not executable:\n$script"
fi

# --- MAIN MENU LOOP ---
while true; do
  category=$(zenity --list \
    --title="Toolbox Categories" \
    --width=400 --height=300 \
    --column="Category" \
    "Audio / Video / Images" \
    "ISO Tools" \
    "ZIP Tools" \
    "Crypt & Decript Utils" \
    "Git & Dev")

  [[ -z "$category" ]] && break

  case "$category" in
    "Audio / Video / Images")
      tool=$(zenity --list \
        --title="$category" \
        --width=400 --height=400 \
        --column="Tool" \
        "PNG Compressor" \
        "Audio Converter" \
        "Image Converter" \
        "Video Converter" \
        "Video To Frames" \
        "Frames To Video")
      case "$tool" in
        "PNG Compressor") script="$TOOLSET_DIR/png_compressor.sh" ;;
        "Audio Converter") script="$TOOLSET_DIR/audio_converter.sh" ;;
        "Image Converter") script="$TOOLSET_DIR/image_converter.sh" ;;
        "Video Converter") script="$TOOLSET_DIR/video_converter.sh" ;;
        "Video To Frames") script="$TOOLSET_DIR/video_to_frames.sh" ;;
        "Frames To Video") script="$TOOLSET_DIR/frames_to_video.sh" ;;
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

    "Crypt & Decript Utils")
      script="$TOOLSET_DIR/gpg_tool.sh"
      ;;

    "Git & Dev")
      script="$TOOLSET_DIR/git_tools.sh"
      ;;
  esac

  # Execute selected script
  if [[ -n "$script" && -x "$script" ]]; then
    "$script"
  elif [[ -n "$script" ]]; then
    zenity --error --text="Script not executable:\n$script"
  fi

  unset script tool
done
