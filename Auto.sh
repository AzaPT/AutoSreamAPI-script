#!/bin/bash

# =======================================================
#      EOS SDK Multi-Directory Patcher / Backup Tool
# =======================================================

# Array to store target directories
declare -a target_dirs
use_gui=false

# Check for Zenity (GUI Tool)
if command -v zenity &> /dev/null; then
    use_gui=true
    echo "GUI (Zenity) detected. Switching to graphical mode..."
else
    echo "Zenity not found. Using text-only mode."
fi

# =======================================================
# 1. Input Target Directories
# =======================================================
if [ "$use_gui" = true ]; then
    # Show info dialog
    zenity --info --title="EOS SDK Patcher" --text="Welcome.\n\nStep 1: You will now select the game folder(s).\nTo support all file managers, we will add folders one by one." --width=400

    # Loop to add folders one by one (Fixes Dolphin/KDE issue)
    while true; do
        # Select ONE directory
        new_dir=$(zenity --file-selection --directory --title="Select a Game Directory")

        # Handle Cancel button
        if [ -z "$new_dir" ]; then
            if [ ${#target_dirs[@]} -eq 0 ]; then
                echo "No directory selected. Exiting."
                exit 1
            else
                # If they cancelled but already added some folders, just proceed
                break
            fi
        fi

        target_dirs+=("$new_dir")

        # Ask if user wants to add another
        if ! zenity --question --title="Add another?" --text="Directory added:\n$new_dir\n\nDo you want to select ANOTHER game folder?"; then
            # User clicked No, break the loop
            break
        fi
    done

else
    # --- TEXT FALLBACK MODE ---
    while true; do
        if [ ${#target_dirs[@]} -eq 0 ]; then
            echo "Enter a game directory to scan (or type 'done' to finish):"
        else
            echo "Enter another directory (or type 'done' to proceed):"
        fi

        read -r -e input_dir

        # Clean up quotes from drag-and-drop
        input_dir="${input_dir%\"}"
        input_dir="${input_dir#\"}"

        if [[ "$input_dir" == "done" ]]; then
            if [ ${#target_dirs[@]} -eq 0 ]; then
                echo "Error: You must enter at least one directory."
                continue
            fi
            break
        fi

        if [ -d "$input_dir" ]; then
            target_dirs+=("$input_dir")
            echo "Added: $input_dir"
        else
            echo "Warning: Directory does not exist. Try again."
        fi
    done
fi

echo "-------------------------------------------------------"

# =======================================================
# 2. Input Replacement Source Directory
# =======================================================
replacement_dir=""

if [ "$use_gui" = true ]; then
    zenity --info --title="EOS SDK Patcher" --text="Step 2: Select the folder containing your NEW replacement DLL files.\n(Must contain EOSSDK-Win64-Shipping.dll or Win32 version)" --width=400

    while true; do
        replacement_dir=$(zenity --file-selection --directory --title="Select Replacement Source Folder")

        if [ -z "$replacement_dir" ]; then
            echo "Selection cancelled."
            exit 1
        fi

        # Validation
        if [[ -f "$replacement_dir/EOSSDK-Win64-Shipping.dll" ]] || [[ -f "$replacement_dir/EOSSDK-Win32-Shipping.dll" ]]; then
            break
        else
            zenity --error --text="Error: That folder does not contain the required EOSSDK files.\nPlease try again."
        fi
    done
else
    # --- TEXT FALLBACK MODE ---
    while true; do
        echo "Enter the folder containing the NEW replacement DLLs:"
        read -r -e replacement_dir

        # Clean up quotes
        replacement_dir="${replacement_dir%\"}"
        replacement_dir="${replacement_dir#\"}"

        if [ -d "$replacement_dir" ]; then
            if [[ -f "$replacement_dir/EOSSDK-Win64-Shipping.dll" ]] || [[ -f "$replacement_dir/EOSSDK-Win32-Shipping.dll" ]]; then
                break
            else
                echo "Error: That folder does not contain EOSSDK-Win64-Shipping.dll or Win32 version."
            fi
        else
            echo "Error: Directory does not exist."
        fi
    done
fi

echo "======================================================="
echo "Starting Scan and Patch Process..."
echo "======================================================="

count_patched=0
log_text=""

# 3. Loop through all provided directories
for dir in "${target_dirs[@]}"; do
    echo "Scanning: $dir"

    # Find files recursively
    find "$dir" -type f \( -name "EOSSDK-Win64-Shipping.dll" -o -name "EOSSDK-Win32-Shipping.dll" \) -print0 | while IFS= read -r -d '' game_file; do

        filename=$(basename "$game_file")
        dir_path=$(dirname "$game_file")
        backup_file="${game_file/.dll/_o.dll}"

        # Determine replacement based on filename (Handles both Win64 and Win32)
        replacement_src=""
        if [[ "$filename" == "EOSSDK-Win64-Shipping.dll" ]]; then
            replacement_src="$replacement_dir/EOSSDK-Win64-Shipping.dll"
        elif [[ "$filename" == "EOSSDK-Win32-Shipping.dll" ]]; then
            replacement_src="$replacement_dir/EOSSDK-Win32-Shipping.dll"
        fi

        if [ ! -f "$replacement_src" ]; then
            echo "  [SKIP] Found $filename, but matching replacement not found in source folder."
            continue
        fi

        # -------------------------------------------------------
        # CHECK: Already patched?
        # This checks both Win64 and Win32.
        # If the file on disk matches the replacement file byte-for-byte, we skip it.
        # -------------------------------------------------------
        if [ -f "$backup_file" ] && cmp -s "$game_file" "$replacement_src"; then
            echo "  -> Found: $game_file"
            echo "     [SKIP] $filename is already up-to-date (matches replacement)."
            continue
        fi

        echo "  -> Processing: $game_file"

        # BACKUP
        if [ -f "$backup_file" ]; then
            echo "     [INFO] Backup already exists. Skipping rename (Preserving original)."
        else
            mv "$game_file" "$backup_file"
            echo "     [OK] Renamed original to _o.dll"
        fi

        # COPY
        cp "$replacement_src" "$game_file"

        if [ $? -eq 0 ]; then
            echo "     [SUCCESS] Replaced $filename with new version."
        else
            echo "     [FAIL] Error copying file."
        fi

    done
done

echo "======================================================="
echo "All operations complete."

if [ "$use_gui" = true ]; then
    zenity --info --text="Patching process complete!\n\nCheck terminal for detailed logs." --title="Success"
fi
