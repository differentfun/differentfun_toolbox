#!/bin/bash

# === STEP 0: Check for dependencies ===
if ! command -v yt-dlp >/dev/null 2>&1; then
    zenity --error --text="yt-dlp is not installed. Please install it and try again."
    exit 1
fi

if ! command -v ffmpeg >/dev/null 2>&1; then
    zenity --error --text="ffmpeg is not installed. Please install it to enable proper video/audio merging."
    exit 1
fi

# === STEP 1: Ask for YouTube URL ===
VIDEO_URL=$(zenity --entry --title="YouTube Downloader" \
  --text="Enter the YouTube video URL:" \
  --width=600)

if [[ -z "$VIDEO_URL" ]]; then
    zenity --error --text="No URL entered. Exiting."
    exit 1
fi

# === STEP 2: Retrieve video title with progress ===
# Create a temp file for the title
TITLE_TMP=$(mktemp)

# Start fetching the title in background
(yt-dlp --get-title "$VIDEO_URL" > "$TITLE_TMP" 2>/dev/null) &

# Show a pulsating progress bar while it runs
(
  echo "10"
  echo "# Retrieving title..."
  while kill -0 $! 2>/dev/null; do
    sleep 0.2
    echo "50"
  done
  echo "100"
) | zenity --progress \
  --title="Please wait" \
  --text="Retrieving title..." \
  --pulsate \
  --no-cancel \
  --auto-close \
  --width=400

# Read the title
RAW_TITLE=$(cat "$TITLE_TMP")
rm "$TITLE_TMP"

if [[ -z "$RAW_TITLE" ]]; then
    zenity --error --text="Failed to retrieve video title. Check the URL."
    exit 1
fi


zenity --info --title="Video Title Found" --text="You are downloading:\n\n$RAW_TITLE"

# === STEP 3: Clean the title for filename ===
CLEAN_TITLE=$(echo "$RAW_TITLE" | sed 's/[^a-zA-Z0-9._ -]/_/g' | tr ' ' '_')
CLEAN_TITLE=${CLEAN_TITLE:0:60}

# === STEP 4: Choose download type ===
TYPE=$(zenity --list --radiolist \
  --title="Download Type" \
  --text="Select what you want to download:" \
  --column="Select" --column="Option" \
  TRUE "Video (MP4)" FALSE "Audio (MP3)" \
  --width=400 --height=200)

if [[ -z "$TYPE" ]]; then
    zenity --error --text="No option selected. Exiting."
    exit 1
fi

# === STEP 5: Choose quality ===
if [[ "$TYPE" == "Video (MP4)" ]]; then
    QUALITY=$(zenity --list --radiolist \
      --title="Video Quality" \
      --text="Select video resolution:" \
      --column="Select" --column="Quality" \
      TRUE "Best (max)" FALSE "1080p" FALSE "720p" FALSE "480p" FALSE "360p" \
      --width=400 --height=250)
    if [[ -z "$QUALITY" ]]; then
        zenity --error --text="No quality selected. Exiting."
        exit 1
    fi
else
    QUALITY=$(zenity --list --radiolist \
      --title="Audio Quality" \
      --text="Select audio bitrate:" \
      --column="Select" --column="Quality" \
      TRUE "Best" FALSE "320kbps" FALSE "256kbps" FALSE "128kbps" \
      --width=400 --height=250)
    if [[ -z "$QUALITY" ]]; then
        zenity --error --text="No quality selected. Exiting."
        exit 1
    fi
fi

# === STEP 6: Choose output folder ===
DEST_DIR=$(zenity --file-selection --directory --title="Choose destination folder")
if [[ -z "$DEST_DIR" ]]; then
    zenity --error --text="No folder selected. Exiting."
    exit 1
fi

# === STEP 7: Build command ===
OUTPUT_PATH="$DEST_DIR/$CLEAN_TITLE"

if [[ "$TYPE" == "Video (MP4)" ]]; then
    case $QUALITY in
        "Best (max)") FORMAT="bestvideo+bestaudio" ;;
        "1080p") FORMAT="bestvideo[height<=1080]+bestaudio" ;;
        "720p") FORMAT="bestvideo[height<=720]+bestaudio" ;;
        "480p") FORMAT="bestvideo[height<=480]+bestaudio" ;;
        "360p") FORMAT="bestvideo[height<=360]+bestaudio" ;;
        *) FORMAT="bestvideo+bestaudio" ;;
    esac

    FINAL_OUTPUT="$OUTPUT_PATH.mp4"

    CMD=(yt-dlp -f "$FORMAT" \
        --recode-video mp4 \
        -o "$FINAL_OUTPUT" \
        "$VIDEO_URL")

else
    case $QUALITY in
        "Best") AUDIO_OPTS=() ;;
        "320kbps") AUDIO_OPTS=(--audio-quality 0) ;;
        "256kbps") AUDIO_OPTS=(--audio-quality 1) ;;
        "128kbps") AUDIO_OPTS=(--audio-quality 5) ;;
        *) AUDIO_OPTS=(--audio-quality 5) ;;
    esac

    FINAL_OUTPUT="$OUTPUT_PATH.mp3"

    CMD=(yt-dlp -x --audio-format mp3 "${AUDIO_OPTS[@]}" \
        -o "$FINAL_OUTPUT" \
        "$VIDEO_URL")
fi

# === STEP 8: Download with progress ===
(
    "${CMD[@]}"
) | zenity --progress \
  --title="Downloading..." \
  --text="Download in progress..." \
  --pulsate \
  --auto-close \
  --width=400

if [[ $? -ne 0 ]]; then
    zenity --error --text="Download failed or was cancelled."
    exit 1
fi

# === STEP 9: Notify complete ===
zenity --info --title="Download Complete" --text="File downloaded to:\n$FINAL_OUTPUT"
