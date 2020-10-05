#!/bin/bash
#
# This script allows to update all files located in the "home" folder for an already setup computer
# Programmatic usage to skip inputs: bash updater.bash <remote ip> <username> --yes
#

# Make the script exit on error
set -oeE pipefail
trap "printf '\nerror: Script failed: see failed command above.\n'" ERR

# Show current step
_step() {
	echo
	echo -e "\e[34m>>> $@\e[39m"
	echo
}

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

echo "========================="
echo "=                       ="
echo "=  REMOTE SETUP UPDATER ="
echo "=                       ="
echo "========================="
echo
echo This updater will upload all files from the \'home\' directory to an already setup computer.
echo
echo First, please indicate the remote computer\'s IP address:
echo

if [ -z "$1" ]; then
	read -p "Computer IP: " computer_ip
else
	echo "Computer IP: $1 (from command line argument)"
	computer_ip="$1"
fi

echo
echo Now please choose the remote user to update the files for.
echo

if [ -z "$2" ]; then
	read -p "User name: " user_name
else
	echo "User name: $2 (from command line argument)"
	user_name="$2"
fi

echo
echo Files will be updated for user \"$user_name\" on computer at address \"$computer_ip\".
echo

if [[ "$3" != "-y" && "$3" != "--yes" ]]; then
	read -p "Please press <Enter> to continue or <Ctrl+C> to cancel installation."
	read -p "Are you sure? Press <Enter> to confirm or <Ctrl+C> to abort."
else
	echo Got confirmation from command line flag "('--y' or '--yes' flag was supplied)".
fi

echo
echo Here we go\!

_step Step 1/1: Copying files
sftp $user_name@$computer_ip

_step Done\!

echo You may now enjoy your setup computer ":)"
