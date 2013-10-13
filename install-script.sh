#!/bin/bash
#
# This code is copyright Stefan Möstel, 2010. <stefan@moestel.org>  To the
# extent that it is released, it is released under the GNU General Public License
# v3 or greater. The author retains all rights with respect to this code.

#  This script is intended to install additional PACKAGES via your prefered packeage manager after a default linux installation. 

#  You can run this script as root or as user (you need to be privileged (sudo)).
#  to be able to install PACKAGES. 

### actual script directory ###
SCRIPTDIR="`dirname \"$0\"`"
SCRIPTDIR="`( cd \"$SCRIPTDIR\" && pwd )`"

### configuration file ###
#  Path to the conifg file.
#  If the path is empty ("") or commented the config file is expected in the current script directory. 
#CONFIGFILEDIR=""
#  Name of the config file.
CONFIGFILE="install.conf"

### Timestamp in log messages ###
LOGTIMESTAMP="date +'%F_%T'"

### log file ###
#  Analog to the CONFIGFILEDIR entry.
#  If the path is empty ("") or commented the config file is expected in the current script directory.
#LOGFILEDIR=""
#  Name of the log file.
LOGFILE="install.log"

#  reading config file
if [ -z $CONFIGFILEDIR ]; then	# config file in same directory as script
        . "$SCRIPTDIR/${CONFIGFILE}"
else
        if [ -d $CONFIGFILEDIR ]; then	# CONFIGFILEDIR is set, therewith configuration will be searched in given directory
                . "${CONFIGFILEDIR}/${CONFIGFILE}"
        else
                echo "$CONFIGFILEDIR does not exist or is not readable."
        fi
fi

#  checking base conditions to run script
conditions() {
	typeset -i CHECKIFONECATEGORYISTRUE=0

	# check if package manager is specified
	if [ -z $PKGMNG ] || [ "$PKGMNG" == "" ]; then
		PKGMNG="aptitude"
		echo "No package manager is specified, \"$PKGMNG\" will be used."
	fi	
	
	# check if categories array is filed
	if [ ${#categories[*]} -eq 0 ]; then
		echo 'No categories found in $categories.'
		if [ "$CONFIGFILEDIR" == "" ] || [ -z $CONFIGFILEDIR ]; then
			echo "Check $SCRIPTDIR/$CONFIGFILE to correct this."
		else
			echo "Check $CONFIGFILEDIR/$CONFIGFILE to correct this."
		fi
		exit 1
	fi
	
	for i in ${categories[@]}; do
		# search if min. one category is set to true
		if [ "${!i}" == "true" ]; then
			CHECKIFONECATEGORYISTRUE=$(expr $CHECKIFONECATEGORYISTRUE + 1)
			# check if package array per active category is not empty
			PACKAGES=$i"_pkg[@]"
			if [ ${#PACKAGES} -eq 0 ]; then
				echo "No packages specified for category $i."
				exit 1
			fi
		fi
	done

	# check if minimal one active category is found.
	if [ $CHECKIFONECATEGORYISTRUE -eq 0 ]; then
		echo "No category is set to true."
		echo "Installation is stopped, nothing changed."
		exit 1
	fi
}

#  start installation of PACKAGES
installPkgs() {
	UPDATEMSG="$($LOGTIMESTAMP): Update package manager repository..."
	INSTALLMSG="$($LOGTIMESTAMP): Install packages ..."
	INSTALLFINMSG="$($LOGTIMESTAMP): Installation finished"
	PKGMNGUPDATE="$($LOGTIMESTAMP): Updating package manager repository..."
	NOLOGDIRMSG="INFO: Log file directory (\$LOGFILEDIR) is not defined, script directory will be used to save log file"
	UNSUPPORTEDPKGMNG="The chosen package manager ($PKGMNG) is not supported today. You can add your package manager easily by defining two variables (PKGMNGUPDATECMD and PKGMNGINSTALLCMD) in function installPkgs(). It would be great if you share your script extention with us by a pull request (github) or just a mail :)"

	for i in ${categories[@]}; do
		# adding PACKAGES from active categories to the list of PACKAGES to install
		if [ "${!i}" == "true" ]; then
			NEWPACKAGES=$i"_pkg[@]"
			PACKAGESTOINSTALL="$PACKAGESTOINSTALL ${!NEWPACKAGES}"
		fi
	done
	
	case $PKGMNG in
		"aptitude")
			PKGMNGUPDATECMD="$PKGMNG update "
			PKGMNGINSTALLCMD="$PKGMNG -y install "
			;;
		"apt-get")
			PKGMNGUPDATECMD="$PKGMNG update "
			PKGMNGINSTALLCMD="$PKGMNG -y install "
			;;
		*)
			echo "$UNSUPPORTEDPKGMNG"
			exit 1
			;;
	esac

	# check if script runs with root permissions.
	if [ $(id -u) -eq 0 ]; then
		
		# script runs already with root permissions
		if [ "$LOGFILEDIR" == "" ] || [ -z $LOGFILEDIR ]; then	# log file directory is not defined, script directory will be used to save log file
			echo "$NOLOGDIRMSG"			
			echo "$UPDATEMSG" | tee "$SCRIPTDIR/$LOGFILE"
			"$PKGMNGUPDATECMD" | tee "$SCRIPTDIR/$LOGFILE"
			echo "$INSTALLMSG" | tee "$SCRIPTDIR/$LOGFILE"
			"$PKGMNGINSTALLCMD" $PACKAGESTOINSTALL | tee "$SCRIPTDIR/$LOGFILE"
			echo "$INSTALLFINMSG" | tee "$SCRIPTDIR/$LOGFILE"
		else
			echo "$UPDATEMSG" | tee "$LOGFILEDIR/$LOGFILE"
			"$PKGMNGUPDATECMD" | tee "$LOGFILEDIR/$LOGFILE" 
			echo "$INSTALLMSG" | tee "$LOGFILEDIR/$LOGFILE"
			"$PKGMNGINSTALLCMD" $PACKAGESTOINSTALL | tee "$LOGFILEDIR/$LOGFILE"
			echo "$INSTALLFINMSG" | tee "$LOGFILEDIR/$LOGFILE"
		fi
	else
	# script runs with user priviliges, sudo will be used
		echo "Script runs with priviliges of user $USER."
		echo "sudo will be used..."
		
		if [ "$LOGFILEDIR" == "" ] || [ -z $LOGFILEDIR ]; then	# log file directory is not defined, script directory will be used to save log file
			echo "$NOLOGDIRMSG"
			echo "$PKGMNGUPDATE" | tee "$SCRIPTDIR/$LOGFILE"
			sudo "$PKGMNGUPDATECMD" | tee "$SCRIPTDIR/$LOGFILE"
			echo "$INSTALLMSG" | tee "$SCRIPTDIR/$LOGFILE"
			sudo "$PKGMNGINSTALLCMD" $PACKAGESTOINSTALL | tee "$SCRIPTDIR/$LOGFILE" 2>&1
			echo "$INSTALLFINMSG" | tee "$SCRIPTDIR/$LOGFILE"
		else
			echo "$PKGMNGUPDATE" | tee "$LOGFILEDIR/$LOGFILE"
			sudo "$PKGMNGUPDATECMD" | tee "$LOGFILEDIR/$LOGFILE" 2>&1
			echo "$INSTALLMSG" | tee "$LOGFILEDIR/$LOGFILE"
            		sudo "$PKGMNGINSTALLCMD" $PACKAGESTOINSTALL | tee "$LOGFILEDIR/$LOGFILE" 2>&1
           		echo "$INSTALLFINMSG" | tee "$LOGFILEDIR/$LOGFILE"
		fi
	fi
}

#clear

#  check if $LOGFILEDIR is set correctly 
if [ "$LOGFILEDIR" == "" ] || [ -z $LOGFILEDIR ] || [ ! -d "$LOGFILEDIR" ]; then
	echo "Editional informations can be found in $SCRIPTDIR/$LOGFILE."
	echo "### Starting script (`$LOGTIMESTAMP`) ###" | tee "$SCRIPTDIR/$LOGFILE"
else
	echo "Editional informations can be found in $LOGFILEDIR/$LOGFILE."
	echo "### Starting script (`$LOGTIMESTAMP`) ###" | tee "$LOGFILEDIR/$LOGFILE"
fi

# checking base conditions
conditions
# starting package installation
installPkgs
