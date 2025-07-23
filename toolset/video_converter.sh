#!/bin/bash

# 1. Select video files
files=$(zenity --file-selection --multiple --separator="|" \
  --title="Select video files to convert" \
  --file-filter="Video files | *.mp4 *.mkv *.avi *.mov *.webm *.flv *.wmv *.mpeg *.mpg *.3gp *.m4v")

if [[ -z "$files" ]]; then
  zenity --error --text="No files selected."
  exit 1
fi

IFS="|" read -ra file_array <<< "$files"
file_rows=()
for file in "${file_array[@]}"; do
  size=$(du -k "$file" | cut -f1)
  name=$(basename "$file")
  file_rows+=("$name" "${size}KB" "$file")
done

zenity --list \
  --title="Selected videos to convert" \
  --width=800 --height=400 \
  --text="🟢 Press OK to start, or Cancel to abort." \
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
  TRUE "mp4" FALSE "webm" FALSE "mkv" FALSE "mov" FALSE "flv")

if [[ -z "$format" ]]; then
  zenity --error --text="No format selected."
  exit 1
fi

# 3. Choose hardware acceleration
hw_accel=$(zenity --list --radiolist \
  --title="Hardware Acceleration" \
  --column="Select" --column="Method" \
  FALSE "CUDA" FALSE "INTEL" FALSE "AMD" TRUE "No Acceleration")

case "$hw_accel" in
  "CUDA")  hwaccel="-hwaccel cuda"; codec="-c:v h264_nvenc -preset slow" ;;
  "INTEL") hwaccel="-hwaccel qsv";  codec="-c:v h264_qsv -preset slow" ;;
  "AMD")   hwaccel="-hwaccel dxva2"; codec="-c:v h264_amf -preset slow" ;;
  "No Acceleration") hwaccel=""; codec="-c:v libx264 -preset slow" ;;
  *) zenity --error --text="Invalid selection."; exit 1;;
esac

if [[ "$format" == "webm" ]]; then
  codec="-c:v libvpx-vp9 -b:v 0"
fi

# 4. Choose compression level
compression=$(zenity --list --radiolist \
  --title="Compression Level" \
  --column="Select" --column="Level" \
  TRUE "SUPERIOR" FALSE "EXTREME" FALSE "HIGH" FALSE "MEDIUM" FALSE "LOW")

if [[ -z "$compression" ]]; then
  zenity --error --text="No compression level selected."
  exit 1
fi

if [[ "$format" == "webm" || "$hw_accel" != "No Acceleration" ]]; then
  case "$compression" in
    "SUPERIOR") compression_param="-qp 35" ;;
    "EXTREME")  compression_param="-qp 30" ;;
    "HIGH")     compression_param="-qp 25" ;;
    "MEDIUM")   compression_param="-qp 20" ;;
    "LOW")      compression_param="-qp 15" ;;
  esac
else
  case "$compression" in
    "SUPERIOR") compression_param="-crf 28 -tune film" ;;
    "EXTREME")  compression_param="-crf 22 -tune film" ;;
    "HIGH")     compression_param="-crf 18 -tune film" ;;
    "MEDIUM")   compression_param="-crf 16 -tune film" ;;
    "LOW")      compression_param="-crf 12" ;;
  esac
fi

# 5. Ask for optional resize
res=$(zenity --forms --title="Resize (Optional)" \
  --text="Leave blank to keep original size." \
  --add-entry="Width (e.g. 1920)" \
  --add-entry="Height (e.g. 1080)")

IFS="|" read -r width height <<< "$res"
resize_param=""
if [[ -n "$width" && -n "$height" ]]; then
  resize_param="-s ${width}x${height}"
fi

# 6. Choose audio handling
audio_choice=$(zenity --list --radiolist \
  --title="Audio options" \
  --column="Select" --column="Option" \
  TRUE "Keep original audio" FALSE "Convert to AAC (libfdk_aac)" FALSE "Convert to MP3 (libmp3lame)" FALSE "Remove audio")

case "$audio_choice" in
  "Keep original audio") audio_param="-c:a copy" ;;
  "Convert to AAC (libfdk_aac)") audio_param="-c:a libfdk_aac -b:a 192k" ;;
  "Convert to MP3 (libmp3lame)") audio_param="-c:a libmp3lame -b:a 192k" ;;
  "Remove audio") audio_param="-an" ;;
  *) zenity --error --text="Invalid audio selection."; exit 1;;
esac

# 7. Choose output directory
output_dir=$(zenity --file-selection --directory --title="Select output directory")
if [[ -z "$output_dir" ]]; then
  zenity --error --text="No output directory selected."
  exit 1
fi

# 8. Conversion with progress
summary_file=$(mktemp)
echo "Filename | Original Size (KB) | Output Size (KB)" > "$summary_file"

(
total=${#file_array[@]}
count=0
for file in "${file_array[@]}"; do
  count=$((count + 1))
  percent=$((count * 100 / total))
  echo "# Converting: $(basename "$file")"

  original_size=$(du -k "$file" | cut -f1)
  base=$(basename "$file")
  name="${base%.*}"
  out_file="$output_dir/$name.$format"

  ffmpeg -y $hwaccel -i "$file" $codec $compression_param $resize_param $audio_param "$out_file"

  if [[ -f "$out_file" ]]; then
    new_size=$(du -k "$out_file" | cut -f1)
    echo "$base | ${original_size}KB | ${new_size}KB" >> "$summary_file"
  else
    echo "$base | ${original_size}KB | ERROR" >> "$summary_file"
  fi

  echo "$percent"
done
) | zenity --progress --title="Converting videos..." --percentage=0 --auto-close --width=400

zenity --text-info --title="Conversion result" --width=700 --height=400 --filename="$summary_file"
rm "$summary_file"
