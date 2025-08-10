#!/bin/bash

# 1. Select image files
files=$(zenity --file-selection --multiple --separator="|" --title="Select images to convert" --file-filter="Images | *.jpg *.jpeg *.png *.webp *.bmp *.tiff *.tif *.gif *.avif")
if [[ -z "$files" ]]; then
  zenity --error --text="No images selected."
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
  --title="Selected images to convert" \
  --width=800 --height=400 \
  --text="🟢 Press OK to proceed, or Cancel to abort." \
  --column="Filename" --column="Size" --column="Full Path" \
  "${file_rows[@]}"

if [[ $? -ne 0 ]]; then
  zenity --info --text="Operation cancelled."
  exit 1
fi

# 2. Choose output format from list
format=$(zenity --list --radiolist \
  --title="Select output image format" \
  --column="Select" --column="Format" \
  TRUE "png" \
  FALSE "jpg" \
  FALSE "webp" \
  FALSE "bmp" \
  FALSE "tiff" \
  FALSE "gif" \
  FALSE "avif")

# 2b. If format is lossy, ask for quality level
quality_param=""
if [[ "$format" == "jpg" || "$format" == "webp" || "$format" == "avif" ]]; then
  quality=$(zenity --scale \
    --title="Select Quality Level" \
    --text="Choose output quality for $format (100 = best quality)" \
    --min-value=10 --max-value=100 --value=90)

  if [[ -z "$quality" ]]; then
    zenity --error --text="No quality selected."
    exit 1
  fi

  if [[ "$format" == "jpg" ]]; then
    quality_param="-qscale:v $((101 - quality))"
    # ffmpeg uses 1 (best) to 31 (worst) for JPG
    # So we invert: quality 100 → qscale 1, quality 90 → qscale 11, etc.
  else
    quality_param="-q:v $quality"
    # For webp / avif: higher is better (0–100)
  fi
fi

if [[ -z "$format" ]]; then
  zenity --error --text="No output format selected."
  exit 1
fi

# 3. Choose output directory
output_dir=$(zenity --file-selection --directory --title="Select output directory")
if [[ -z "$output_dir" ]]; then
  zenity --error --text="No output directory selected."
  exit 1
fi

# 4. Progress + Conversion
summary_file=$(mktemp)
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

  ffmpeg -y -i "$file" $quality_param "$out_file" < /dev/null &> /dev/null

  if [[ -f "$out_file" ]]; then
    output_size=$(du -k "$out_file" | cut -f1)
    echo "$base | ${input_size}KB | ${output_size}KB" >> "$summary_file"
  else
    echo "$base | ${input_size}KB | ERROR" >> "$summary_file"
  fi

  echo "$percent"
done
) | zenity --progress --title="Converting images..." --percentage=0 --auto-close --width=400

# 5. Show result
zenity --text-info --title="Conversion result" --width=700 --height=400 --filename="$summary_file"
rm "$summary_file"

# Optional desktop notification
if command -v notify-send &>/dev/null; then
  notify-send "Image Converter" "Image conversion completed."
fi
