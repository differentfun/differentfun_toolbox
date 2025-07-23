#!/bin/bash

input_dir=$(zenity --file-selection --directory --title="Select directory with frames")
if [[ -z "$input_dir" ]]; then
  zenity --error --text="No input directory selected."
  exit 1
fi

img_ext=$(zenity --list --radiolist \
  --title="Select frame format" \
  --column="Select" --column="Format" \
  TRUE "png" FALSE "jpg" FALSE "bmp")

if [[ -z "$img_ext" ]]; then
  zenity --error --text="No image format selected."
  exit 1
fi

fps=$(zenity --entry --title="Framerate" --text="Enter framerate (e.g. 24):" --entry-text="24")
if ! [[ "$fps" =~ ^[0-9]+$ ]]; then
  zenity --error --text="Invalid framerate."
  exit 1
fi

format=$(zenity --list --radiolist \
  --title="Select output video format" \
  --column="Select" --column="Format" \
  TRUE "mp4" FALSE "webm" FALSE "mkv")

if [[ -z "$format" ]]; then
  zenity --error --text="No format selected."
  exit 1
fi

output_path=$(zenity --file-selection --save --confirm-overwrite --title="Save output video as" --filename="output.$format")
if [[ -z "$output_path" ]]; then
  zenity --error --text="No output path provided."
  exit 1
fi

input_pattern="$input_dir/frame_%04d.$img_ext"
total_frames=$(ls "$input_dir"/*."$img_ext" 2>/dev/null | wc -l)

{
  echo "# Creating video from frames..."
  ffmpeg -y -framerate "$fps" -i "$input_pattern" -c:v libx264 -pix_fmt yuv420p "$output_path" 2>&1 | \
  while IFS= read -r line; do
    [[ "$line" =~ frame= *([0-9]+) ]] && {
      current=${BASH_REMATCH[1]}
      percent=$((current * 100 / total_frames))
      echo "$percent"
    }
  done
  echo "100"
} | zenity --progress --title="Building video..." --percentage=0 --auto-close --width=400

zenity --info --text="Video saved as:\n$output_path"
