#!/usr/bin/env bash
# Recursive File Date Changer (Zenity GUI)
# Changes mtime/atime of files and/or directories recursively.
# Requires: bash, zenity, find, stat, date (GNU coreutils), touch

set -euo pipefail

if ! command -v zenity >/dev/null; then
  echo "Zenity is not installed. Please install it and try again."
  exit 1
fi

req_bins=(find stat date touch)
for b in "${req_bins[@]}"; do
  command -v "$b" >/dev/null || { zenity --error --text="Required command not found: $b"; exit 1; }
done

LOG_FILE="$(mktemp -t datechanger.XXXXXX.log)"

# 1) Select working directory
TARGET_DIR=$(zenity --file-selection --directory --title="Select target directory (recursive)")
[[ -z "${TARGET_DIR:-}" ]] && exit 0

# 2) Select target type (files/dirs/both)
TYPE=$(zenity --list --radiolist \
  --title="What to modify?" \
  --width=420 --height=250 \
  --column="Select" --column="Type" --column="Description" \
  TRUE "files" "Modify only files" \
  FALSE "dirs" "Modify only directories" \
  FALSE "both" "Modify both files and directories")

[[ -z "${TYPE:-}" ]] && exit 0

case "$TYPE" in
  files) FIND_OPTS="-type f" ;;
  dirs) FIND_OPTS="-type d" ;;
  both) FIND_OPTS="" ;;
esac

# 3) Select which times to change
TIME_TYPE=$(zenity --list --checklist \
  --title="Which timestamps to change?" \
  --width=420 --height=250 \
  --column="Select" --column="Type" --column="Description" \
  TRUE "mtime" "Modification time" \
  FALSE "atime" "Access time")

[[ -z "${TIME_TYPE:-}" ]] && exit 0

# 4) Ask for new date/time
NEW_DATE=$(zenity --calendar --title="Select new date" --date-format="%Y-%m-%d")
[[ -z "${NEW_DATE:-}" ]] && exit 0

NEW_TIME=$(zenity --entry --title="Enter new time" --text="Format: HH:MM" --entry-text="12:00")
[[ -z "${NEW_TIME:-}" ]] && exit 0

# Validate time format
if ! date -d "$NEW_DATE $NEW_TIME" >/dev/null 2>&1; then
  zenity --error --text="Invalid date/time format."
  exit 1
fi

FINAL_TIMESTAMP=$(date -d "$NEW_DATE $NEW_TIME" +"%Y%m%d%H%M.%S")

# 5) Confirm
zenity --question --title="Confirm" --text="Apply changes recursively in:\n$TARGET_DIR\n\nTimestamp: $NEW_DATE $NEW_TIME\nTargets: $TYPE\nChange: $TIME_TYPE"
[[ $? -ne 0 ]] && exit 0

# 6) Perform changes
while IFS= read -r item; do
  touch_args=()
  [[ "$TIME_TYPE" == *"mtime"* ]] && touch_args+=("-m")
  [[ "$TIME_TYPE" == *"atime"* ]] && touch_args+=("-a")
  touch -t "$FINAL_TIMESTAMP" "${touch_args[@]}" "$item"
  echo "Changed: $item" >> "$LOG_FILE"
done < <(find "$TARGET_DIR" $FIND_OPTS)

zenity --info --title="Done" --text="Timestamps updated.\nLog file: $LOG_FILE"
