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

# Reuse consistent yt-dlp options (mainly to avoid hanging forever).
YT_DLP_BASE_OPTS=(--socket-timeout 15)

sanitize_for_filename() {
    local input="$1"
    local cleaned
    cleaned=$(echo "$input" | sed 's/[^a-zA-Z0-9._ -]/_/g' | tr ' ' '_')
    cleaned=${cleaned:0:60}
    if [[ -z "$cleaned" ]]; then
        cleaned="download"
    fi
    echo "$cleaned"
}

# === STEP 1: Ask for YouTube URL ===
VIDEO_URL=$(zenity --entry --title="YouTube Downloader" \
  --text="Enter the YouTube video URL:" \
  --width=600)

if [[ -z "$VIDEO_URL" ]]; then
    zenity --error --text="No URL entered. Exiting."
    exit 1
fi

# === STEP 2: Retrieve metadata with progress ===
INFO_TMP=$(mktemp)

(yt-dlp "${YT_DLP_BASE_OPTS[@]}" --skip-download --playlist-items 1 \
    --print "%(title)s" \
    --print "%(playlist_title)s" \
    --print "%(playlist_count)s" \
    "$VIDEO_URL" > "$INFO_TMP" 2>/dev/null) &
INFO_PID=$!

# Show a pulsating progress bar while it runs
(
  echo "10"
  echo "# Retrieving info..."
  while kill -0 $INFO_PID 2>/dev/null; do
    sleep 0.2
    echo "50"
  done
  echo "100"
) | zenity --progress \
  --title="Please wait" \
  --text="Retrieving video / playlist info..." \
  --pulsate \
  --no-cancel \
  --auto-close \
  --width=400

wait "$INFO_PID"

if [[ ! -s "$INFO_TMP" ]]; then
    rm "$INFO_TMP"
    zenity --error --text="Failed to retrieve video information. Check the URL."
    exit 1
fi

mapfile -t YT_INFO < "$INFO_TMP"
rm "$INFO_TMP"

RAW_TITLE="${YT_INFO[0]}"
PLAYLIST_TITLE="${YT_INFO[1]}"
PLAYLIST_COUNT="${YT_INFO[2]}"

if [[ -z "$RAW_TITLE" || "$RAW_TITLE" == "NA" ]]; then
    zenity --error --text="Failed to retrieve video title. Check the URL."
    exit 1
fi

if [[ "$PLAYLIST_TITLE" == "NA" ]]; then
    PLAYLIST_TITLE=""
fi

PLAYLIST_COUNT_NUM=0
if [[ "$PLAYLIST_COUNT" =~ ^[0-9]+$ ]]; then
    PLAYLIST_COUNT_NUM=$PLAYLIST_COUNT
fi

if (( PLAYLIST_COUNT_NUM > 1 )); then
    DISPLAY_TITLE=${PLAYLIST_TITLE:-$RAW_TITLE}
    zenity --info --title="Playlist Detected" --text="Detected playlist:\n\n$DISPLAY_TITLE\n\nVideos found: $PLAYLIST_COUNT_NUM\n\nThe entire playlist will be downloaded."
    IS_PLAYLIST=1
else
    DISPLAY_TITLE=$RAW_TITLE
    zenity --info --title="Video Title Found" --text="You are downloading:\n\n$DISPLAY_TITLE"
    IS_PLAYLIST=0
fi

# === STEP 3: Clean the title for filename ===
CLEAN_VIDEO_TITLE=$(sanitize_for_filename "$RAW_TITLE")
if [[ $IS_PLAYLIST -eq 1 && -n "$DISPLAY_TITLE" ]]; then
    CLEAN_PLAYLIST_TITLE=$(sanitize_for_filename "$DISPLAY_TITLE")
else
    CLEAN_PLAYLIST_TITLE="$CLEAN_VIDEO_TITLE"
fi

# === STEP 4: Let the user override the filename (single video only) ===
if [[ $IS_PLAYLIST -eq 0 ]]; then
    CUSTOM_NAME=$(zenity --entry --title="Nome file" \
      --text="Inserisci un nome personalizzato (senza estensione):" \
      --entry-text="$CLEAN_VIDEO_TITLE" \
      --width=600)

    if [[ $? -ne 0 ]]; then
        zenity --error --text="Nessun nome inserito. Uscita."
        exit 1
    fi

    if [[ -n "$CUSTOM_NAME" ]]; then
        CLEAN_VIDEO_TITLE=$(sanitize_for_filename "$CUSTOM_NAME")
    fi
fi

# === STEP 5: Choose download type ===
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

# === STEP 6: Choose quality ===
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

# === STEP 7: Choose output folder ===
DEST_DIR=$(zenity --file-selection --directory --title="Choose destination folder")
if [[ -z "$DEST_DIR" ]]; then
    zenity --error --text="No folder selected. Exiting."
    exit 1
fi

# === STEP 8: Build command ===
OUTPUT_PATH="$DEST_DIR/$CLEAN_VIDEO_TITLE"
PLAYLIST_OUTPUT_DIR="$DEST_DIR/$CLEAN_PLAYLIST_TITLE"
YT_PLAYLIST_ARGS=()
if [[ $IS_PLAYLIST -eq 1 ]]; then
    YT_PLAYLIST_ARGS=(--yes-playlist)
fi

if [[ "$TYPE" == "Video (MP4)" ]]; then
    case $QUALITY in
        "Best (max)") FORMAT="bestvideo+bestaudio" ;;
        "1080p") FORMAT="bestvideo[height<=1080]+bestaudio" ;;
        "720p") FORMAT="bestvideo[height<=720]+bestaudio" ;;
        "480p") FORMAT="bestvideo[height<=480]+bestaudio" ;;
        "360p") FORMAT="bestvideo[height<=360]+bestaudio" ;;
        *) FORMAT="bestvideo+bestaudio" ;;
    esac

    if [[ $IS_PLAYLIST -eq 1 ]]; then
        FINAL_OUTPUT="$PLAYLIST_OUTPUT_DIR"
        OUTPUT_TEMPLATE="$PLAYLIST_OUTPUT_DIR/%(playlist_index)03d - %(title).60s.%(ext)s"
    else
        FINAL_OUTPUT="$OUTPUT_PATH.mp4"
        OUTPUT_TEMPLATE="$FINAL_OUTPUT"
    fi

    CMD=(yt-dlp "${YT_DLP_BASE_OPTS[@]}" -f "$FORMAT" \
        --recode-video mp4 \
        -o "$OUTPUT_TEMPLATE")
    CMD+=("${YT_PLAYLIST_ARGS[@]}" "$VIDEO_URL")

else
    case $QUALITY in
        "Best") AUDIO_OPTS=() ;;
        "320kbps") AUDIO_OPTS=(--audio-quality 0) ;;
        "256kbps") AUDIO_OPTS=(--audio-quality 1) ;;
        "128kbps") AUDIO_OPTS=(--audio-quality 5) ;;
        *) AUDIO_OPTS=(--audio-quality 5) ;;
    esac

    if [[ $IS_PLAYLIST -eq 1 ]]; then
        FINAL_OUTPUT="$PLAYLIST_OUTPUT_DIR"
        OUTPUT_TEMPLATE="$PLAYLIST_OUTPUT_DIR/%(playlist_index)03d - %(title).60s.%(ext)s"
    else
        FINAL_OUTPUT="$OUTPUT_PATH.mp3"
        OUTPUT_TEMPLATE="$FINAL_OUTPUT"
    fi

    CMD=(yt-dlp "${YT_DLP_BASE_OPTS[@]}" -x --audio-format mp3 "${AUDIO_OPTS[@]}" \
        -o "$OUTPUT_TEMPLATE")
    CMD+=("${YT_PLAYLIST_ARGS[@]}" "$VIDEO_URL")
fi

# === STEP 9: Download with progress ===
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

# === STEP 10: Notify complete ===
if [[ $IS_PLAYLIST -eq 1 ]]; then
    zenity --info --title="Download Complete" --text="Playlist downloaded to:\n$FINAL_OUTPUT"
else
    zenity --info --title="Download Complete" --text="File downloaded to:\n$FINAL_OUTPUT"
fi
