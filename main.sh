#!/bin/bash

# Get the absolute path to the folder where this script is located
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLSET_DIR="$ROOT_DIR/toolset"

# Check if toolset folder exists
if [[ ! -d "$TOOLSET_DIR" ]]; then
  zenity --error --title="Toolset not found" --text="The folder 'toolset' was not found in:\n$ROOT_DIR"
  exit 1
fi

# Make all .sh files in toolset executable
chmod +x "$TOOLSET_DIR"/*.sh 2>/dev/null

# Ask if user wants to install requirements
zenity --question \
  --title="Install Requirements?" \
  --text="Do you want to install requirements before launching the toolbox?"

if [[ $? -eq 0 ]]; then
  # User chose YES → show requirement installers
  req_selection=$(zenity --list \
    --title="Select Your Distribution" \
    --width=400 --height=200 \
    --column="Installer" \
    "Install Requirements for Debian")

  if [[ -z "$req_selection" ]]; then
    exit 0
  fi

  case "$req_selection" in
    "Install Requirements for Debian") script="$TOOLSET_DIR/requirements_debian.sh" ;;
    *) zenity --error --text="Invalid selection." ; exit 1 ;;
  esac

  if [[ -x "$script" ]]; then
    "$script"
  else
    zenity --error --text="Installer script not found or not executable:\n$script"
    exit 1
  fi
fi

# MAIN TOOL LIST MENU
while true; do
  selection=$(zenity --list \
    --title="Toolset Launcher" \
    --width=400 --height=400 \
    --column="Tool" \
    "PNG Compressor" \
    "Audio Converter" \
    "Image Converter" \
    "Video Converter" \
    "Video To Frames" \
    "Frames To Video" \
    "Create ISO From Folder" \
    "Unpack ISO To Folder")

  if [[ -z "$selection" ]]; then
    break
  fi

  case "$selection" in
    "PNG Compressor") script="$TOOLSET_DIR/png_compressor.sh" ;;
    "Audio Converter") script="$TOOLSET_DIR/audio_converter.sh" ;;
    "Image Converter") script="$TOOLSET_DIR/image_converter.sh" ;;
    "Video Converter") script="$TOOLSET_DIR/video_converter.sh" ;;
    "Video To Frames") script="$TOOLSET_DIR/video_to_frames.sh" ;;
    "Frames To Video") script="$TOOLSET_DIR/frames_to_video.sh" ;;
    "Create ISO From Folder") script="$TOOLSET_DIR/create_iso.sh" ;;
    "Unpack ISO To Folder") script="$TOOLSET_DIR/extract_iso.sh" ;;
    *) zenity --error --text="Invalid selection." ; continue ;;
  esac

  if [[ -x "$script" ]]; then
    "$script"
  else
    zenity --error --text="Script not found or not executable:\n$script"
  fi
done
