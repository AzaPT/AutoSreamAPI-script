Prerequisites

Linux OS (Steam Deck / SteamOS supported)

Bash (Standard on almost all Linux distros)

Zenity (Optional: Required for the GUI mode. Usually pre-installed on Ubuntu, SteamOS, etc.)

Installation

Download the script.

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

	./Auto.sh


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
