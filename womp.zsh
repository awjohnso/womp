#!/bin/zsh --no-rcs
# set -x

##########################################################################################
################################ SET VARIABLES ###########################################

vers="1.30"
myHost=$( /usr/sbin/scutil --get ComputerName )
scriptName=$( /usr/bin/basename ${0} )
myPID=$$
myLog="/Library/Logs/$(/usr/bin/basename ${0} | /usr/bin/cut -d "." -f 1 ).log"
function myTimeStamp()
{
	/bin/date | /usr/bin/awk  '{ printf "%02s %02s %02s %02s\n", $1,$2,$3,$4 }'
}
Numb_Arguments=$#
argument_1="${1}"

##########################################################################################
############################### SETUP FUNCTIONS ##########################################

function logging()
{
	/bin/echo "$(myTimeStamp) ${myHost} ${scriptName}[${myPID}]: ${1}" | /usr/bin/tee -a "${myLog}"
}
function START_SCRIPT()
{
	/bin/echo "" | /usr/bin/tee -a "${myLog}"
	logging "Starting ${scriptName}, Version: ${vers}."
}
function EXIT_SCRIPT()
{
	logging "Ending ${scriptName}, Version: ${vers}."
	/bin/echo "" | /usr/bin/tee -a "${myLog}"
	exit ${1}
}
function MAKE_TEMP_DIR()
{
		# Make a temp directory to store downloaded files and such.
	myTmpDir=$( /usr/bin/mktemp -d )
	logging "MAKE_TEMP_DIR: Making temp directory: ${myTmpDir}"
}
function REMOVE_TEMP_DIR()
{
		# Remove the temp directory.
	logging "REMOVE_TEMP_DIR: Removing temp directory: ${myTmpDir}"
	/bin/rm -Rf "${myTmpDir}"
}
function TOGGLE_SSH()
{
	logging "TOGGLE_SSH: Starting TOGGLE_SSH."
		# Check to see if SSH is on. If it is on, then turn it off.
	SSH_STATUS=$( /usr/sbin/systemsetup -getremotelogin | /usr/bin/awk -F ' ' '{print $3}' )
	if [ "${SSH_STATUS}" != "${SSH_SET}" ]; then
			# Turn off SSH Access.
		logging "TOGGLE_SSH: SSH Service is ${SSH_STATUS}. Changing to ${SSH_SET}..."
		/usr/sbin/systemsetup -f -setremotelogin ${SSH_SET}
	else
			# SSH Access is already off, nothing to do.
		logging "TOGGLE_SSH: SSH is already set to ${SSH_SET}."
	fi
	logging "TOGGLE_SSH: Ending TOGGLE_SSH."
}
function TOGGLE_WOMP()
{
	logging "TOGGLE_WOMP: Starting TOGGLE_WOMP."
	WOMP_STATUS=$( /usr/bin/pmset -g custom | /usr/bin/awk '/womp/ { sum+=$2 } END {print sum}' )
	if [ ${WOMP_STATUS} -ge 1 ]; then
		WOMP_STATUS=1
	fi
	if [ ${WOMP_STATUS} -ne ${WOMP_SET} ]; then
		logging "TOGGLE_WOMP: Wake on Lan is set to ${WOMP_STATUS}. Chaning it to ${WOMP_SET}..."
		/usr/bin/pmset -a womp ${WOMP_SET}
	else
		logging "TOGGLE_WOMP: Wake on Lan is already set to ${WOMP_SET}...."
	fi
	logging "TOGGLE_WOMP: Ending TOGGLE_WOMP."
}
function NETWORK()
{
	logging "NETWORK: Starting NETWORK."
		# Check to see if we have a campus LAN IP.
	myResult=$( /sbin/ifconfig | /usr/bin/egrep -c "129.49.|130." )
	
		# If those IP ranges are not true then turn off Wake On Lan and SSH, esle
		# ensure Wake On Lan and SSH are on.
	if [ ${myResult} -eq 0 ]; then
		logging "NETWORK: This comuputer is not on SBU LAN."
		SSH_SET="Off"
		WOMP_SET=0
	else
		logging "NETWORK: This comuputer is on SBU LAN."
		SSH_SET="On"
		WOMP_SET=1
	fi
	logging "NETWORK: Ending NETWORK."
}
function MY_VERSION()
{
	if [[ "$1" -eq 1 ]]; then
		case $2 in
			(-v|--version)
				/bin/echo "${vers}"
				exit 0
				;;
			(*)
				exit 0
				;;
		esac
	fi
}

##########################################################################################
####################################### MAIN #############################################

MY_VERSION ${Numb_Arguments} ${argument_1}

START_SCRIPT

NETWORK
TOGGLE_SSH
TOGGLE_WOMP

EXIT_SCRIPT 0