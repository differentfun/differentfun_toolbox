#!/bin/bash

# Ask the user to select one of the split parts
first_part=$(zenity --file-selection --title="Select the first part of the split archive")

if [ -z "$first_part" ]; then
    zenity --error --text="No file selected."
    exit 1
fi

# Get directory and base name
part_dir=$(dirname "$first_part")
part_base=$(basename "$first_part" | sed 's/[0-9]*$//')

# Ask for output directory
output_dir=$(zenity --file-selection --directory --title="Select output directory for reassembled archive")

if [ -z "$output_dir" ]; then
    zenity --error --text="No output directory selected."
    exit 1
fi

combined_file="$output_dir/${part_base}combined.zip"

# Progress bar
(
echo "10"
echo "# Combining parts into one archive..."
cat "$part_dir/${part_base}"* > "$combined_file"
echo "60"
echo "# Extracting archive..."
unzip -o "$combined_file" -d "$output_dir/extracted" > /dev/null
echo "90"
echo "# Cleaning up..."
# Optional: rm "$combined_file"
echo "100"
echo "# Done!"
) | zenity --progress \
  --title="Recombine Split Archive" \
  --text="Starting..." \
  --percentage=0 \
  --auto-close

# Check if user cancelled
if [[ $? -ne 0 ]]; then
    zenity --warning --text="Operation canceled."
    rm -f "$combined_file"
    exit 1
fi

zenity --info --text="Archive successfully reassembled and extracted to:\n$output_dir/extracted"
