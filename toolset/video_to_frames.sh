#!/bin/bash

video_file=$(zenity --file-selection --title="Select video file" --file-filter="Video files | *.mp4 *.mkv *.avi *.mov *.webm *.flv *.wmv *.mpeg *.mpg *.3gp *.m4v")
if [[ -z "$video_file" ]]; then
  zenity --error --text="No video selected."
  exit 1
fi

output_dir=$(zenity --file-selection --directory --title="Select output directory for frames")
if [[ -z "$output_dir" ]]; then
  zenity --error --text="No output directory selected."
  exit 1
fi

format=$(zenity --list --radiolist \
  --title="Select image format" \
  --column="Select" --column="Format" \
  TRUE "png" FALSE "jpg" FALSE "bmp")

if [[ -z "$format" ]]; then
  zenity --error --text="No format selected."
  exit 1
fi

mode=$(zenity --list --radiolist \
  --title="Frame Extraction Mode" \
  --column="Select" --column="Mode" \
  TRUE "Extract every frame" FALSE "Extract 1 frame every N seconds")

if [[ "$mode" == "Extract 1 frame every N seconds" ]]; then
  interval=$(zenity --entry --title="Frame Interval" --text="Enter number of seconds between frames:" --entry-text="1")
  if ! [[ "$interval" =~ ^[0-9]+$ ]]; then
    zenity --error --text="Invalid interval."
    exit 1
  fi
  filter="-vf fps=1/$interval"
else
  filter=""
fi

output_pattern="$output_dir/frame_%04d.$format"
duration=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$video_file")
duration=${duration%.*}

{
  echo "# Extracting frames..."
  ffmpeg -y -i "$video_file" $filter "$output_pattern" 2>&1 | \
  while IFS= read -r line; do
    [[ "$line" =~ time=([0-9:.]+) ]] && {
      t=${BASH_REMATCH[1]}
      IFS=: read -r hh mm ss <<< "$t"
      elapsed=$(echo "$hh*3600 + $mm*60 + ${ss%.*}" | bc)
      percent=$((elapsed * 100 / duration))
      echo "$percent"
    }
  done
  echo "100"
} | zenity --progress --title="Extracting frames..." --percentage=0 --auto-close --width=400

zenity --info --text="Frames saved to:\n$output_dir"
