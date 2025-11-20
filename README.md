EOS SDK Patcher & Backup Tool

A Bash script designed to automate the replacement of Epic Online Services (EOS) SDK DLL files (EOSSDK-Win64-Shipping.dll or EOSSDK-Win32-Shipping.dll) in game directories.

It features automatic backups, smart version checking to prevent redundant patching, and a simple GUI for ease of use on Linux/Steam Deck.

Features

Hybrid Interface: Automatically detects if zenity is installed to show a GUI. Falls back to a text-based terminal interface if not.

Multi-Directory Support: Allows you to patch multiple game folders in a single run.

Smart Architecture Detection: Automatically detects whether the game needs the Win64 or Win32 version and selects the correct replacement file.

Safety First:

Creates a backup of the original file (e.g., EOSSDK-Win64-Shipping_o.dll) before replacing.

Preserves Backups: If a backup already exists (from a previous run), it will not overwrite it, ensuring your original file remains safe.

Redundancy Check: If the file currently in the game folder is identical to the replacement file, the script skips it to save time.

Dolphin/KDE Friendly: The GUI allows adding folders one by one to work around selection limitations in some Linux file managers.

Prerequisites

Linux OS (Steam Deck / SteamOS supported)

Bash (Standard on almost all Linux distros)

Zenity (Optional: Required for the GUI mode. Usually pre-installed on Ubuntu, SteamOS, etc.)

Installation

Download the patch_eossdk.sh script.

Open your terminal and navigate to the folder where you saved the script.

Make the script executable by running:

chmod +x patch_eossdk.sh


Usage

1. Prepare your Replacement Files

Create a folder somewhere on your computer (e.g., ~/Downloads/EOS_Fix/) and place your modified .dll files inside it.

The folder must contain at least one of the following:

EOSSDK-Win64-Shipping.dll

EOSSDK-Win32-Shipping.dll

2. Run the Script

Open a terminal and run:

./patch_eossdk.sh


3. Follow the Instructions

GUI Mode (Zenity)

A dialog will ask you to select a game directory.

After selecting one, it will ask if you want to add another. Click No when finished.

A second dialog will ask you to select the folder containing your replacement DLLs.

The script will run and show a success message when done.

Text Mode (Terminal)

Paste the full path to your game directory.

Type done when you are finished adding directories.

Paste the full path to the folder containing your replacement DLLs.

The script will print the status of every file processed.

How the Patch Logic Works

When scanning a game folder, the script performs these checks in order:

Detection: It looks for EOSSDK-Win64-Shipping.dll or EOSSDK-Win32-Shipping.dll.

Matching: It checks your replacement folder for the corresponding version. If you only have the 64-bit replacement, it will skip 32-bit game files.

Verification:

It checks if a backup (_o.dll) already exists.

It compares the current game file against your replacement file.

If the backup exists AND the current file matches the replacement: It skips the file (reports "Already patched").

Backup: If not skipped, it renames the original game file to ..._o.dll.

Replace: It copies your new file into the game folder.
