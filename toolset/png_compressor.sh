#!/bin/bash

# 1. Select PNG files
files=$(zenity --file-selection --multiple --separator="|" --title="Select PNG files to compress" --file-filter="PNG files (png) | *.png")
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
  --title="Selected files to compress" \
  --width=800 --height=400 \
  --text="🟢 Press OK to start compression, or Cancel to abort." \
  --column="Filename" --column="Size" --column="Full Path" \
  "${file_rows[@]}"

if [[ $? -ne 0 ]]; then
  zenity --info --text="Operation cancelled."
  exit 1
fi

# 2. Choose compression level
compression_choice=$(zenity --list --radiolist \
  --title="Compression level" \
  --column="Select" --column="Level" \
  TRUE "Low" FALSE "Medium" FALSE "High")

if [[ -z "$compression_choice" ]]; then
  zenity --error --text="No compression level selected."
  exit 1
fi

# Map selection to pngquant parameter
case "$compression_choice" in
  "Low") CompressionLevel="--quality=79" ;;
  "Medium") CompressionLevel="--quality=85" ;;
  "High") CompressionLevel="--quality=90" ;;
esac

# 3. Overwrite original files?
zenity --question --text="Do you want to overwrite the original files?" --ok-label="Yes" --cancel-label="No"
overwrite=$?

# 3b. Ask output directory if not overwriting
if [[ "$overwrite" -ne 0 ]]; then
  output_dir=$(zenity --file-selection --directory --title="Select output directory for compressed files")
  if [[ -z "$output_dir" ]]; then
    zenity --error --text="No output directory selected."
    exit 1
  fi
fi

# 4. Compression with progress bar
summary_file=$(mktemp)
echo "Filename | Full Path | Original KB | Compressed KB" > "$summary_file"

# Define temp progress file
progress_file=$(mktemp)

# Progress logic
{
  total=${#file_array[@]}
  count=0

  for file in "${file_array[@]}"; do
    count=$((count + 1))
    percent=$((count * 100 / total))
    echo "$percent" > "$progress_file"

    original_size=$(du -k "$file" | cut -f1)
    base_name=$(basename "$file")

    if [[ "$overwrite" -eq 0 ]]; then
      echo -e "\n→ Compressing (overwrite): $base_name"
      pngquant $CompressionLevel --force --ext .png "$file"
      new_file="$file"
    else
      new_file="$output_dir/$base_name"
      echo -e "\n→ Compressing to output dir: $new_file"
      pngquant $CompressionLevel --output "$new_file" "$file"
    fi

    if [[ -f "$new_file" ]]; then
      compressed_size=$(du -k "$new_file" | cut -f1)
      echo "$base_name | $file | ${original_size}KB | ${compressed_size}KB" >> "$summary_file"
    else
      echo "$base_name | $file | ${original_size}KB | ERROR" >> "$summary_file"
    fi
  done
} &

# While compression runs, update progress bar
(
  while true; do
    [[ -f "$progress_file" ]] || break
    val=$(cat "$progress_file" 2>/dev/null)
    [[ -n "$val" ]] || continue
    echo "# Compressing files..."
    echo "$val"
    [[ "$val" -ge 100 ]] && break
    sleep 0.2
  done
) | zenity --progress --title="Compressing PNGs..." --percentage=0 --auto-close --width=400

# Cleanup progress file
rm -f "$progress_file"

# 5. Show summary
zenity --text-info --title="Compression result" --width=700 --height=400 --filename="$summary_file"
rm "$summary_file"

# 6. Optional desktop notification
if command -v notify-send &>/dev/null; then
  notify-send "PNG Compressor" "Compression completed successfully."
fi
