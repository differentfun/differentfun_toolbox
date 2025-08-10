#!/bin/bash

# Ask the user to select a folder to archive
folder=$(zenity --file-selection --directory --title="Select the folder to archive")

if [ -z "$folder" ]; then
    zenity --error --text="No folder selected."
    exit 1
fi

# Ask user for the maximum size of each part in MB
size_mb=$(zenity --entry --title="Split size" --text="Enter the maximum size for each part (in MB):")

# Validate input
if ! [[ "$size_mb" =~ ^[0-9]+$ ]] || [ "$size_mb" -le 0 ]; then
    zenity --error --text="Invalid input. Please enter a positive integer (MB)."
    exit 1
fi

# Convert MB to bytes
size_bytes=$((size_mb * 1024 * 1024))

# Ask user where to save the split files
output_dir=$(zenity --file-selection --directory --title="Select output directory for split parts")

if [ -z "$output_dir" ]; then
    zenity --error --text="No output directory selected."
    exit 1
fi

# Prepare variables
base_name=$(basename "$folder")
temp_zip="/tmp/${base_name}_temp.zip"
parent_dir=$(dirname "$folder")

# Show progress
(
echo "10"
echo "# Creating archive..."

# Go to parent directory and zip only the folder name (no full path)
cd "$parent_dir" || exit 1
zip -r "$temp_zip" "$base_name" > /dev/null

echo "60"
echo "# Splitting archive into ${size_mb}MB parts..."

split -b "$size_bytes" -d -a 3 "$temp_zip" "$output_dir/${base_name}_part_"

echo "90"
echo "# Cleaning up temporary files..."
rm -f "$temp_zip"

echo "100"
echo "# Done!"
) | zenity --progress \
  --title="Creating split archive" \
  --text="Starting..." \
  --percentage=0 \
  --auto-close

# Handle cancellation
if [[ $? -ne 0 ]]; then
    zenity --warning --text="Operation canceled."
    rm -f "$temp_zip"
    exit 1
fi

# Final message
zenity --info --text="Archive successfully split into parts of ${size_mb} MB.\nSaved to:\n$output_dir"
