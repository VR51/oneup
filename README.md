# OneUp!

MAME and QMC2 Installer. Bash script to download MAME and QMC2 source files then build and install them.

Compiles both from source and installs the binaries and files to their expected locations.

For OS: Linux

Tested With: Ubuntu flavours

- Lead Author: Lee Hodson
- Donate: https://paypal.me/vr51
- Website: https://journalxtra.com/gaming/mame-qmc2-installer/
- This Release: 4th Mar. 2018
- First Written: 27th Feb. 2018
- First Release: 27th Feb. 2018

Copyright 2018 OneUP! <https://journalxtra.com>

License: GPL3

Programmer: Lee Hodson <journalxtra.com>, VR51 <vr51.com>

Use of this program is at your own risk

# USE TO:

1) Install/Update MAME from source (includes tools)
2) Install/Update QMC2 from source (includes QMC2, QMC2 Arcade, QCHDMAN and the man help pages)
3) Update MAME default data files: artwork, bgfx, ctrlr, hash, keymaps, language, plugins, roms and samples.
4) Create default output data directories: cfg, nvram, memcard, inp, sta, snap, diff and comments
5) Delete, or not, stale files before new files are downloaded. Option set affects only actions committed.
6) Set the number of parallel jobs make should use during build process.
7) Install packages required to successfully build MAME and QMC2. This option shows until used.

# DETAILED INSTRCTIONS

[https://journalxtra.com/gaming/mame-qmc2-installer/](https://journalxtra.com/gaming/mame-qmc2-installer/)

# TO RUN:

Download the script [from here](https://github.com/VR51/oneup/blob/master/oneup.sh)

Ensure the script is executable.

- Right-click > properties > Executable
- OR
- chmod u+x oneup.sh

Launch by clicking the script file or by typing bash oneup.sh at the command line.

-	MAME will be compiled in /home/USER/src/mame
-	QMC2 will be compiled in /home/USER/src/qmc2
-	MAME and QMC2 will install to their default locations
-	MAME default data files will be installed to /home/USER/.mame/
-	MAME default output data directories will be installed to /home/USER/.mame/
- This installer assumes SDL2 and QT5 can be installed into the active system without conflicts.
- Files that exist in $HOME/src/mame and $HOME/src/qmc2 will be overwritten or updated by this program.

OneUp! uses sudo privileges to install compiled binaries and during file updates.

OneUp! asks for sudo permissions when installing software and/or when it is about to remove stale directories. Directories are not removed with sudo privileges. OneUp! uses sudo to change the user and owner of the directories and files to be removed or overwritten so that they can be removed or overwritten under the active user's credentials.

# LIMITATIONS

You will need game and arcade ROMs to use MAME enjoyably.

Visit https://journalxtra.com/gaming/download-complete-sets-of-mess-and-mame-roms/ to find some.

# CHANGE LOG

## 1.0.1

- New options
- Redesigned code
- Redesigned options layout
