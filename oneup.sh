#!/bin/bash
clear
# set -x
###
#
#	OneUP! 1.0.0
#
#	MAME and QMC2 installer & updater.
# Compiles both from source and installs the binaries and files to their expected locations.
#
#	For OS: Linux
#	Tested With: Ubuntu flavours
#
#	Lead Author: Lee Hodson
#	Donate: https://paypal.me/vr51
#	Website: https://journalxtra.com/gaming/mame-qmc2-installer/
#	This Release: 27th Feb. 2018
#	First Written: 27th Feb. 2018
#	First Release: 27th Feb. 2018
#
#	Copyright 2018 OneUP! <https://journalxtra.com>
#	License: GPL3
#
#	Programmer: Lee Hodson <journalxtra.com>, VR51 <vr51.com>
#
#	Use of this program is at your own risk
#
#	USE TO:
#
#	  1) Install MAME from source
#	  2) Update MAME from source
#		3) Install QMC2 from source
#		4) Update QMC2 from source
#		5) Update MAME default data files: artwork, bgfx, ctrlr, hash, keymaps, language, plugins, roms, samples.
#		6) Create default output data directories: cfg nvram memcard inp sta snap diff comments
#		7) Delete, or not, stale files before new files are downloaded. Option set affects only actions committed.
#		8) Install packages required to successfully build MAME and QMC2. This option shows until used.
#
#	TO RUN:
#
#	  Ensure the script is executable.
#
#			Right-click > properties > Executable
#     OR
#			chmod u+x oneup.sh
#
#		Launch by clicking the script file or by typing bash oneup.sh at the command line.
#
#   MAME will be compiled in /home/USER/src/mame
#   QMC2 will be compiled in /home/USER/src/qmc2
#		MAME and QMC2 will install to their default locations
#		MAME default data files will be installed to /home/USER/.mame/
#		MAME default output data directories will be installed to /home/USER/.mame/
#		This installer assumes SDL2 and QT5 can be installed into the active system without conflicts.
#		Files that exist in $HOME/src/mame and $HOME/src/qmc2 will be overwritten or updated by this program.
#
#		OneUp! uses sudo privileges to install compiled binaries and during file updates.
#
#		OneUp! asks for sudo permissions when installing software and/or when it is about to remove stale directories.
#   Directories are not removed with sudo privileges.
#   OneUp! uses sudo to change the user and owner of the directories and files to be removed or overwritten
#   so that they can be removed or overwritten under the active user's credentials.
#
#	LIMITATIONS
#
#		You will need game and arcade ROMs to use MAME enjoyably.
#   Visit https://journalxtra.com/gaming/download-complete-sets-of-mess-and-mame-roms/ to find some.
#
###

## User Editable Options

mameloc='https://github.com/mamedev/mame.git' # MAME Git directory
qmc2loc='https://svn.code.sf.net/p/qmc2/code/trunk' # SVN path of QMC2
mameinst='/usr/games' # MAME installation path. Where should the compiled binary be installed to? Exact path. No trailing slash.
mamesearchpath='/usr/share/games/mame' # Default location for MAME data files. Exact path. No trailing slash. This mirrors $HOME/.mame.
mamesearchpath2='/usr/local/share/games/mame' # Default location for MAME data files. Exact path. No trailing slash. This mirrors $HOME/.mame.

user=$(whoami) # Current User
group=$(id -g -n $user) # Current user's primary group

# Internal Settings - These do not usually need to be manually changed

declare -a conf

conf[0]=0 # Essentials # Install build essential software. 0 = Not done, 1 = Done
conf[1]=0 # Clean Stale # Remove old build files before recompilation? 0/1. 0 = No, 1 = Yes.
conf[2]=5 # CPU Cores # Number of CPU cores to employ to build binaries. Maximum value is total number of CPU cores + 1. More cores  = faster build time. If you have a quadcore, set to 4+1 i.e 5 cores.
conf[3]=$(mame -? | grep 'MAME v') # Installed MAME Version
conf[4]=$(grep 'INDEX - v' "/usr/local/share/qmc2/doc/html/us/index.html" | sed -E "s#</?font.{0,10}>##g" | tr -d '[:space:]') # Installed QMC2 Version


## END User Options

# Set Menu Options
declare -a menu=( 'Install MAME' 'Install QMC2' 'Update MAME' 'Update QMC2' 'Update MAME Data Files' 'Create MAME Data Directories' 'Remove Stale Source Files Before Builds' 'Install Essential Build Packages' )

# Other settings

bold=$(tput bold)
normal=$(tput sgr0)

# Locate Where We Are
filepath="$( echo $PWD )"
# A Little precaution
cd "$filepath"


# Make SRC directory

if test ! -d "$HOME/src"; then
	mkdir "$HOME/src"
fi


function oneup_run() {
	# Check for terminal then run else just run program
	tty -s
	if test "$?" -ne 0 ; then
		oneup_launch
	else
		oneup_prompt "${menu[*]}"
	fi
	
}

function oneup_prompt() {

  while true; do

		if test ${conf[0]} == '1' ; then
			unset menu[7] # Count starts at 0
		fi
  
		printf $bold
		printf "Menu\n\n"
		printf $normal
  
		n=1
		for i in "${menu[@]}"; do
			printf "$n) $i\n"
			let n=n+1
		done
		
		printf "\n0) Exit\n"
		
		# Notices

		printf $bold

			if [ ${conf[0]} == 0 ]; then
				printf "\nSuccessful build of MAME and QMC2 requires software packages installed by option 8. You should probably install these now. This message and Option 8 will not show once this is done.\n"
			fi

			printf "\nGeneral Settings\n"

		printf $normal
		
			if [ ${conf[1]} == 0 ]; then
				printf "\nYes, delete old source files before action is committed."
			else
				printf "\nNo, do not delete old source files before action is committed."
			fi
			
			let cores=${conf[2]}-1
			printf "\nUse $cores CPU cores to compile source.\n"

			printf $bold
				printf "\nGeneral Info\n"
			printf $normal
						
			printf "\nSystem MAME: ${conf[3]}"
			printf "\nSystem QMC2: ${conf[4]}\n"

		printf $bold
			printf "\nChoose Wisely: "
		printf $normal
		read REPLY
		
	
		case $REPLY in
		
		
		1) # Install MAME

			printf "\nInstalling MAME. This may take a few moments.\n"

			cd "$HOME/src"
			
			# Reset permissions & maybe start with a clean slate OR just download
			if test -d "$HOME/src/mame" ; then
			
				sudo chown -R $user:$group "$HOME/src/mame"
				
				if [ $conf[1] == 1 ]; then
				
					rm -r -f "$HOME/src/mame"
					git clone "$mameloc"
					
				else
				
					cd "$HOME/src/mame"
					git pull -p
					
				fi
				
			else

				git clone "$mameloc"

			fi

			cd "$HOME/src/mame"
			
			make -j$cores TOOLS=1
		
			if test -f "$HOME/src/mame/mame64"; then
				sudo cp -f "$HOME/src/mame/mame64" "$mameinst/mame"
			fi
			
			if test -f "$HOME/src/mame/mame32"; then
				sudo cp -f "$HOME/src/mame/mame32" "$mameinst/mame"
			fi
			
			if test -f "$HOME/src/mame/mame"; then
				sudo cp -f "$HOME/src/mame/mame" "$mameinst/mame"
			fi
			
			sudo ldconfig
			make clean
			
			printf "\nMAME has been built from source and installed ready for use.\n"
			printf "\nPress ANY key\n"
			read something
			clear

		;;
		
		2) # Install QMC2
		
			printf "\nInstalling QMC2. This may take a few moments.\n"

			cd "$HOME/src"

			# Reset permissions & maybe start with a clean slate
			if test -d "$HOME/src/qmc2" ; then
				sudo chown -R $user:$group "$HOME/src/qmc2"
				if [ $conf[1] == 1 ]; then
					rm -r -f "$HOME/src/qmc2"
				fi
			fi
			
			# Download, build and install
			svn co "$qmc2loc" qmc2
			cd "$HOME/src/qmc2"
 
			make -j${conf[2]} DISTCFG=1
			sudo make install DISTCFG=1
			make -j${conf[2]} arcade DISTCFG=1
			sudo make arcade-install DISTCFG=1
			make -j${conf[2]} qchdman DISTCFG=1
			sudo make qchdman-install DISTCFG=1
			make -j${conf[2]} man
			sudo make man-install
			make distclean DISTCFG=1
			sudo ldconfig
			make clean
		
			printf "\nQMC2 has been built from source and installed ready for use.\n"
			read something
			clear
			
		;;
		
		3) # Update MAME -- Currently the same as initial install process
		
			printf "\nUpdating MAME. This may take a few moments.\n"

			cd "$HOME/src"
			
			# Reset permissions & maybe start with a clean slate OR just download them
			if test -d "$HOME/src/mame" ; then
			
				sudo chown -R $user:$group "$HOME/src/mame"
				
				if [ $conf[1] == 1 ]; then
				
					rm -r -f "$HOME/src/mame"
					git clone "$mameloc"
					
				else
				
					cd "$HOME/src/mame"
					git pull -p
					
				fi

			else
			
				git clone "$mameloc"
				
			fi
			
			cd "$HOME/src/mame"
			
			make -j${conf[2]} TOOLS=1
			
			if test -f "$HOME/src/mame/mame64"; then
				sudo cp -f "$HOME/src/mame/mame64" "$mameinst/mame"
			fi
			
			if test -f "$HOME/src/mame/mame32"; then
				sudo cp -f "$HOME/src/mame/mame32" "$mameinst/mame"
			fi
			
			if test -f "$HOME/src/mame/mame"; then
				sudo cp -f "$HOME/src/mame/mame" "$mameinst/mame"
			fi
			
			sudo ldconfig
			make clean
		
			printf "\nMAME has been rebuilt from source and installed ready for use.\n"
			printf "\nPress ANY key\n"
			read something
			clear
			
		;;
		
		4) # Update QMC2
		
			printf "\nUpdating QMC2. This may take a few moments.\n"
		
			# Update package files, build and install
			cd "$HOME/src/qmc2"
			svn update
 
			make -j${conf[2]} DISTCFG=1
			sudo make install DISTCFG=1
			make -j${conf[2]} arcade DISTCFG=1
			sudo make arcade-install DISTCFG=1
			make -j${conf[2]} qchdman DISTCFG=1
			sudo make qchdman-install DISTCFG=1
			make -j${conf[2]} man
			sudo make man-install
			make distclean DISTCFG=1
			sudo ldconfig
			make clean
		
			printf "\nQMC2 has been updated ready for use."
			printf "\nRemember to clear QMC2 software caches from QMC2 > Tools > Clean Up > Clear All Emulator Caches."
			printf "\nAlternatively, launch QMC2 from the command line with$bold qmc2 -cc$normal\n"
			printf "\nPress ANY key\n"
			read something
			clear
			
		;;

		5) # Update MAME data files
		
			printf "\nUpdating MAME data files. This shouldn't take long.\n"

			cd "$HOME/src"
			
			# Reset permissions & maybe start with a clean slate OR just download them
			if test -d "$HOME/src/mame" ; then
			
				sudo chown -R $user:$group "$HOME/src/mame"
				
				if [ $conf[1] == 1 ]; then
				
					rm -r -f "$HOME/src/mame"
					git clone "$mameloc"
					
				else
				
					cd "$HOME/src/mame"
					git pull -p
					
				fi

			else
			
				git clone "$mameloc"
				
			fi
			
			cd "$HOME/src/mame"

			# Copy data files to where needed
			unset files
			files=( artwork bgfx ctrlr hash keymaps language plugins roms samples )
			for i in "${files[@]}"; do
				cp -f -R "$HOME/src/mame/$i" "$HOME/.mame/"
				sudo cp -f -R "$HOME/src/mame/$i" "$mamesearchpath/"
				sudo cp -f -R "$HOME/src/mame/$i" "$mamesearchpath2/"
			done
			
			sudo cp -f -R "$HOME/src/mame/ini/presets" "/etc/mame/"

			printf "\nMAME basic data files have been copied to $HOME/.mame\n"
			printf "\nIf you use QMC2 you will need to clean its software caches to reinitialise the lists of usable software and ROMs. Newly available software will not display in the QMC2 software lists until the caches are cleaned.\n"
			printf "\nClear QMC2 software caches from QMC2 > Tools > Clean Up > Clear All Emulator Caches."
			printf "\nAlternatively, launch QMC2 from the command line with$bold qmc2 -cc$normal\n"
			printf "\nPress ANY key\n"
			read something
			clear

		;;
		
		
		6) # Create MAME data output directories
		
			printf "\nCreating MAME output data directories.\n"

			# Create default data output directories unless they already exist
			unset files
			files=( cfg nvram memcard inp sta snap diff comments )
			for i in "${files[@]}"; do
				if test ! -d "$HOME/.mame/$i"; then
					mkdir "$HOME/.mame/$i"
				fi
			done

			printf "\nMAME data output directories have been added to $HOME/.mame\n"
			printf "\nPress ANY key\n"
			read something
			clear

		;;

		7) # Download Fresh Source Files

			if test ${conf[1]} == 0; then
				sed -i -E "0,/conf\[1\]=0/s/conf\[1\]=0/conf\[1\]=1/" "$0"
				conf[1]=1
			else
				sed -i -E "0,/conf\[1\]=1/s/conf\[1\]=1/conf\[1\]=0/" "$0"
				conf[1]=0
			fi

			clear

		;;
		
		8) # Install Build Essential Packages
		
			sudo apt-get update
			packages=( build-essential subversion g++ libqtwebkit-dev libphonon-dev libxmu-dev rsync libfontconfig-dev libsdl2* libqt5* qt5* )
			for i in "${packages[@]}"; do
				sudo apt-get build-dep -y -q $i
				sudo apt-get install -y -q --install-suggests $i
			done
			
			sed -i -E "0,/conf\[0\]=0/s/conf\[0\]=0/conf\[0\]=1/" "$0"
			conf[0]=1
			
			printf "\nPress any key to continue\n"
			read something
			clear
			
		;;
		
		0) # Exit
			
			exit 0
			
		;;
		
		*)
			
		esac

  done
  
}


## launch terminal

function oneup_launch() {

	terminal=( konsole gnome-terminal x-terminal-emulator xdg-terminal terminator urxvt rxvt Eterm aterm roxterm xfce4-terminal termite lxterminal xterm )
	for i in ${terminal[@]}; do
		if command -v $i > /dev/null 2>&1; then
			exec $i -e "$0"
			# break
		else
			printf "\nUnable to automatically determine the correct terminal program to run e.g Console or Konsole. Please run this program from the command line.\n"
			read something
			exit 1
		fi
	done
}

## Boot

oneup_run "$@"

# Exit is at end of oneup_run()

# FOR DEBUGGING

# declare -p
