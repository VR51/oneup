#!/bin/bash
clear
# set -x
###
#
#	OneUP! 1.0.3
#
#	MAME and QMC2 installer & updater.
#	Compiles both from source and installs the binaries and files to their expected locations.
#
#	For OS: Linux
#	Tested With: Ubuntu flavours
#
#	Lead Author: Lee Hodson
#	Donate: https://paypal.me/vr51
#	Website: https://journalxtra.com/gaming/mame-qmc2-installer/
#	This Release: 2nd April. 2018
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
#	1) Install/Update MAME from source (includes tools)
#	2) Install/Update QMC2 from source (includes QMC2, QMC2 Arcade, QCHDMAN and the man help pages)
#	3) Update MAME default data files: artwork, bgfx, ctrlr, hash, keymaps, language, plugins, roms and samples.
#	4) Create default output data directories: cfg, nvram, memcard, inp, sta, snap, diff and comments
#	5) Delete, or not, stale files before new files are downloaded. Option set affects only actions committed.
#	6) Set the number of parallel jobs make should use during build process.
#	7) Install packages required to successfully build MAME and QMC2. This option shows until used.
#
#	TO RUN:
#
#	Ensure the script is executable.
#
#	Right-click > properties > Executable
#	OR
#	chmod u+x oneup.sh
#
#	Launch by clicking the script file or by typing bash oneup.sh at the command line.
#
#	MAME will be compiled in /home/USER/src/mame
#	QMC2 will be compiled in /home/USER/src/qmc2
#	MAME and QMC2 will install to their default locations
#	MAME default data files will be installed to /home/USER/.mame/
#	MAME default output data directories will be installed to /home/USER/.mame/
#	This installer assumes SDL2 and QT5 can be installed into the active system without conflicts.
#	Files that exist in $HOME/src/mame and $HOME/src/qmc2 will be overwritten or updated by this program.
#
#	OneUp! uses sudo privileges to install compiled binaries and during file updates.
#
#	OneUp! asks for sudo permissions when installing software and/or when it is about to remove stale directories.
#	Directories are not removed with sudo privileges.
#	OneUp! uses sudo to change the user and owner of the directories and files to be removed or overwritten
#	so that they can be removed or overwritten under the active user's credentials.
#
#	LIMITATIONS
#
#	You will need game and arcade ROMs to use MAME enjoyably.
#	Visit https://journalxtra.com/gaming/download-complete-sets-of-mess-and-mame-roms/ to find some.
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
declare -a menu # Menu options are set within oneup_prompt()
declare -a message # Index indicates related conf, mode or menu item
declare -a mode # Used for notices

conf[0]=0 # Essentials # Install build essential software. 0 = Not done, 1 = Done
conf[1]=2 # Clean Stale # Do no cleaning or run make clean or delete source files? 0/1/2. 0 = No, 1 = Soft, 2 = Hard.
conf[2]=0 # Parallel jobs to run during build # Number of CPU cores + 1 is safe. Can be as high as 2*CPU cores. More jobs can shorten build time but not always and risks system stability. 0 = Auto.
conf[3]=$(nproc) # Number of CPU cores the computer has.
conf[4]=$(mame -? | grep 'MAME v') # Installed MAME Version
conf[5]=$(grep 'INDEX - v' "/usr/local/share/qmc2/doc/html/us/index.html" | sed -E "s#[ ]{0,10}</?font.{0,10}>(INDEX - v)?##g") # Installed QMC2 Version


## END User Options

let safeproc=${conf[3]}+${conf[3]} # Safe number of parallel jobs, possibly.

# Other settings

bold=$(tput bold)
normal=$(tput sgr0)

# Locate Where We Are
filepath="$( echo $PWD )"
# A Little precaution
cd "$filepath"

# Make SRC directory if it does not already exist

if test ! -d "$HOME/src"; then
	mkdir "$HOME/src"
fi

# Functions

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

		# Set Menu Options

		case ${conf[1]} in
		
			0)
				message[1]='No cleaning'
				menu[1]='Update MAME'
				menu[2]='Update QMC2'
				mode[1]='MODE: Update. Press 6 to change mode.'
			;;

			1)
				message[1]='Clean Compiler Cache'
				menu[1]='Update MAME'
				menu[2]='Update QMC2'
				mode[1]='MODE: Update. Press 6 to change mode.'
			;;

			2)
				message[1]='Delete Source Files'
				menu[1]='Install MAME'
				menu[2]='Install QMC2'
				mode[1]='MODE: Install. Press 6 to change mode.'
			;;

		esac

		menu[3]=''
		menu[4]='Update MAME Data Files'
		menu[5]='Create MAME Data Directories'
		menu[6]=''
		
		case "${conf[2]}" in
		
			0)
				menu[7]="Number of parallel jobs the installer should run. ${conf[3]} is Safe. $safeproc Max: Auto"
			;;
			
			*)
				menu[7]="Number of parallel jobs the installer should run ( Auto, Safe(${conf[3]}) or Max($safeproc) ): ${conf[2]}"
			;;
			
		esac
		
		menu[8]="Clean Level: ${message[1]}"
		menu[9]=''
		
		case "${conf[0]}" in
		
			0)
				menu[10]='Install Essential Build Packages'
				message[1]='\nIf installation fails Install Essential Build Packages then try again.'
			;;
			
		esac

		printf $bold
		printf "${mode[1]}\n"
		printf $normal
		
		printf "\nMENU\n\n"

		n=1
		for i in "${menu[@]}"; do
			if [ "$i" == '' ]; then
				printf "\n"
			else
				printf "$n) $i\n"
				let n=n+1
			fi
		done

		printf "\n0) Exit\n"

		# Notices

			printf $bold

			printf "${message[1]}"
			printf "\nIf the computer crashes during installation lower the number of parallel jobs used by the installer then try again.\n"

			printf "\nGENERAL INFO\n"
				
			printf $normal

			printf "\n System MAME: ${conf[4]}"
			printf "\n System QMC2: ${conf[5]}\n"
			
			printf "\nClean the QMC2 software caches after any updates have been committed otherwise the QMC2 playable software lists and playable ROM lists will be out-of-date.\n"
			printf "\nUse QMC2 > Tools > Clean Up > Clear All Emulator Caches OR launch QMC2 from the command line with$bold qmc2 -cc$normal\n"

		printf $bold
			printf "\nChoose Wisely: "
		printf $normal
		read REPLY

		case $REPLY in

		1) # Install / Update MAME

			printf "\nInstalling MAME. This may take a few moments to a long time. Go get a coffee.\n"

			cd "$HOME/src"

			# Test the mame source files exist. Download them if not.
			if test -d "$HOME/src/mame" ; then
				# Make sure we own the source files
				sudo chown -R $user:$group "$HOME/src/mame"
				
				# Decide whether to update or install
				case ${conf[1]} in
				
					0) # Update - No spring clean. Update source files
						cd "$HOME/src/mame"
						git pull -p
					;;
				
					1) # Update - spring clean first. Update source files
						cd "$HOME/src/mame"
						make clean
						make distclean
						git pull -p
					;;
					
					2) # Clean install. Delete source files. Download fresh source files.
						rm -r -f "$HOME/src/mame"
						git clone "$mameloc"
						cd "$HOME/src/mame"
					;;
					
				esac

			else
				# Clean install necessary - Source files not present yet
				git clone "$mameloc"
				cd "$HOME/src/mame"

			fi

			case "${conf[2]}" in
				0)
					jobs=''
				;;
				
				*)
					jobs="-j${conf[2]}"
				;;
			esac
			
			# Build MAME
			cd "$HOME/src/mame"
			make $jobs TOOLS=1

			# Install MAME
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
			
			conf[4]=$(mame -? | grep 'MAME v') # Newly installed MAME Version

			printf "\nMAME is ready to use.\n"
			printf "\nPress ANY key"
			read something
			clear

		;;

		2) # Install / Update QMC2

			printf "\nInstalling QMC2. This may take a few moments.\n"

			cd "$HOME/src"

			# Check whether QMC2 source files already exist. Download them if not.
			if test -d "$HOME/src/qmc2" ; then
				# Make sure we own the source files
				sudo chown -R $user:$group "$HOME/src/qmc2"
				
				# Decide whether to update or install
				case ${conf[1]} in
				
					0) # Update. No spring clean. Update source files
						cd "$HOME/src/qmc2"
						svn update
					;;

					1) # Update. Do spring clean. Update source files
						cd "$HOME/src/qmc2"
						make clean
						make distclean DISTCFG=1
						svn update
					;;
					
					2) # Install. Delete existing source files. Download fresh source files.
						rm -r -f "$HOME/src/qmc2"
						svn co "$qmc2loc" qmc2
					;;
					
				esac
				
			else
				# Download fresh source files. Files do not not present yet.
				svn co "$qmc2loc" qmc2

			fi

			case "${conf[2]}" in
				0)
					jobs=''
				;;
				
				*)
					jobs="-j${conf[2]}"
				;;
			esac
			
			# Build & install QMC2, QMC2 Arcade and QCHDMAN and man pages.
			cd "$HOME/src/qmc2"

			make $jobs DISTCFG=1
			sudo make install DISTCFG=1
			make $jobs arcade DISTCFG=1
			sudo make arcade-install DISTCFG=1
			make $jobs qchdman DISTCFG=1
			sudo make qchdman-install DISTCFG=1
			make $jobs man
			sudo make man-install
			sudo ldconfig

			conf[5]=$(grep 'INDEX - v' "/usr/local/share/qmc2/doc/html/us/index.html" | sed -E "s#[ ]{0,10}</?font.{0,10}>(INDEX - v)?##g") # Newly installed QMC2 Version

			printf "\nQMC2 is ready to use.\n"
			printf "\nPress ANY key"
			read something
			clear

		;;

		3) # Update MAME data files

			printf "\nUpdating MAME data files. This shouldn't take long.\n"

			cd "$HOME/src"

			# Reset permissions & maybe start with a clean slate OR just download them
			if test -d "$HOME/src/mame" ; then

				sudo chown -R $user:$group "$HOME/src/mame"

				if [ ${conf[1]} == 1 ]; then

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
			printf "\nPress ANY key\n"
			read something
			clear

		;;


		4) # Create MAME data output directories

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
		
		5) # Parallel jobs to run during build
		
			case "${conf[2]}" in
			
				$safeproc)

					let conf[2]=0
					sed -i -E "0,/conf\[2\]=[0-9]{1,2}/s/conf\[2\]=[0-9]{1,2}/conf\[2\]=${conf[2]}/" "$0"

				;;

				*)

					let conf[2]=${conf[2]}+1
					sed -i -E "0,/conf\[2\]=[0-9]{1,2}/s/conf\[2\]=[0-9]{1,2}/conf\[2\]=${conf[2]}/" "$0"
					
				;;

			esac

			clear

		;;

		6) # Set update, install, clean flag
		
			case ${conf[1]} in
			
				0)
					sed -i -E "0,/conf\[1\]=0/s/conf\[1\]=0/conf\[1\]=1/" "$0"
					conf[1]=1
				;;

				1)
					sed -i -E "0,/conf\[1\]=1/s/conf\[1\]=1/conf\[1\]=2/" "$0"
					conf[1]=2
				;;

				2)
					sed -i -E "0,/conf\[1\]=2/s/conf\[1\]=2/conf\[1\]=0/" "$0"
					conf[1]=0
				;;

			esac

			clear
			
		;;

		7) # Install software packages necessary to build MAME and QMC2

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
