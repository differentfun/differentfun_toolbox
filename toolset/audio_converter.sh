#!/bin/bash

# 1. Select audio files
files=$(zenity --file-selection --multiple --separator="|" --title="Select audio files to convert" --file-filter="Audio files | *.mp3 *.wav *.flac *.ogg *.aac *.m4a *.opus")
if [[ -z "$files" ]]; then
  zenity --error --text="No files selected."
  exit 1
fi

# Show selected files in a Zenity list with sizes
IFS="|" read -ra file_array <<< "$files"
file_rows=()

for file in "${file_array[@]}"; do
  size=$(du -k "$file" | cut -f1)
  name=$(basename "$file")
  file_rows+=("$name" "${size}KB" "$file")
done

zenity --list \
  --title="Selected audio files to convert" \
  --width=800 --height=400 \
  --text="🟢 Press OK to proceed, or Cancel to abort." \
  --column="Filename" --column="Size" --column="Full Path" \
  "${file_rows[@]}"

if [[ $? -ne 0 ]]; then
  zenity --info --text="Operation cancelled."
  exit 1
fi

# 2. Choose output format
format=$(zenity --list --radiolist \
  --title="Select output format" \
  --column="Select" --column="Format" \
  TRUE "mp3" FALSE "m4a" FALSE "aac" FALSE "ogg" FALSE "wav" FALSE "flac" FALSE "opus")

if [[ -z "$format" ]]; then
  zenity --error --text="No format selected."
  exit 1
fi

# 3. Choose quality
if [[ "$format" == "ogg" ]]; then
  quality_choice=$(zenity --list --radiolist \
    --title="Select quality level (OGG - VBR)" \
    --column="Select" --column="Quality" \
    TRUE "Very High (q=10)" FALSE "High (q=7)" FALSE "Medium (q=5)" FALSE "Low (q=3)")
  case "$quality_choice" in
    *q=10*) quality_param="-q:a 10" ;;
    *q=7*) quality_param="-q:a 7" ;;
    *q=5*) quality_param="-q:a 5" ;;
    *q=3*) quality_param="-q:a 3" ;;
    *) quality_param="-q:a 5" ;;
  esac
else
  quality_choice=$(zenity --list --radiolist \
    --title="Select bitrate (CBR)" \
    --column="Select" --column="Bitrate" \
    TRUE "512k" FALSE "256k" FALSE "128k" FALSE "96k")
  case "$quality_choice" in
    "512k") quality_param="-b:a 512k" ;;
    "256k") quality_param="-b:a 256k" ;;
    "128k") quality_param="-b:a 128k" ;;
    "96k")  quality_param="-b:a 96k" ;;
    *) quality_param="-b:a 128k" ;;
  esac
fi

# 4. Codec based on selected format
case "$format" in
  "m4a"|"aac") codec_param="-c:a aac" ;;
  "ogg")      codec_param="-c:a libvorbis" ;;
  "mp3")      codec_param="-c:a libmp3lame" ;;
  "wav")      codec_param="-c:a pcm_s16le" ;;
  "flac")     codec_param="-c:a flac" ;;
  "opus")     codec_param="-c:a libopus" ;;
esac

# 5. Choose output folder
output_dir=$(zenity --file-selection --directory --title="Select output directory")
if [[ -z "$output_dir" ]]; then
  zenity --error --text="No output directory selected."
  exit 1
fi

# 6. Show global progress bar

# Crea file temporaneo per il riepilogo
summary_file=$(mktemp)

# Scrivi intestazione
echo "Filename | Original Size (KB) | Output Size (KB)" > "$summary_file"

(
total=${#file_array[@]}
count=0

for file in "${file_array[@]}"; do
  count=$((count + 1))
  percent=$((count * 100 / total))
  echo "# Converting: $(basename "$file")"
  
  input_size=$(du -k "$file" | cut -f1)
  base=$(basename "$file")
  name="${base%.*}"
  out_file="$output_dir/$name.$format"

  ffmpeg -y -i "$file" $codec_param $quality_param "$out_file"

  if [[ -f "$out_file" ]]; then
    new_size=$(du -k "$out_file" | cut -f1)
    echo "$base | ${input_size}KB | ${new_size}KB" >> "$summary_file"
  else
    echo "$base | ${input_size}KB | ERROR" >> "$summary_file"
  fi

  echo "$percent"
done
) | zenity --progress --title="Converting audio..." --percentage=0 --auto-close --width=400

# 7. Show result
zenity --text-info --title="Conversion result" --width=700 --height=400 --filename="$summary_file"

# Optional: remove temp file
rm "$summary_file"



