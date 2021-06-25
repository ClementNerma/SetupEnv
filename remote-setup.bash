#!/bin/bash
#
# This script allows to run the automated installed on a remote computer/server.
# Programmatic usage to skip inputs: bash remote-setup.bash <remote ip> <username> --yes
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

echo "=========================="
echo "=                        ="
echo "= REMOTE SETUP INSTALLER ="
echo "=                        ="
echo "=========================="
echo
echo "This installer will setup a fresh computer or server remotely."
echo
echo "First, please indicate the remote computer\'s IP address:"
echo

if [ -z "$2" ]; then
	read -p "Computer IP: " computer_ip
else
	echo "Computer IP: $2 (from command line argument)"
	computer_ip="$2"
fi

echo
echo "Now please choose the remote user to setup the server for."
echo "Note that many packages will be installed for all users, but most of the customization will only"
echo " be applied to the user you choose."
echo

if [ -z "$1" ]; then
	read -p "User name: " user_name
else
	echo "User name: $1 (from command line argument)"
	user_name="$1"
fi

echo
echo "Everything will be installed for user \"$user_name\" on computer at address \"$computer_ip\"."
echo

if [[ "$3" != "-y" && "$3" != "--yes" ]]; then
	read -p "Please press <Enter> to continue or <Ctrl+C> to cancel installation."
	read -p "Are you sure? Press <Enter> to confirm or <Ctrl+C> to abort."
else
	echo "Got confirmation from command line flag ('--y' or '--yes' flag was supplied)".
fi

echo
echo "Here we go!"

_step "Step 1/3: Checking if the remote hots can be reached correctly..."
ssh $user_name@$computer_ip echo Connected successfully.

_step "Step 2/3: Copying files..."
ssh $user_name@$computer_ip rm -rf .___remote_setup
ssh $user_name@$computer_ip mkdir .___remote_setup
scp -r "$SCRIPT_DIR/home" $user_name@$computer_ip:./.___remote_setup
scp "$SCRIPT_DIR/auto-install.bash" $user_name@$computer_ip:./.___remote_setup

_step "Step 3/3: Running installer..."
ssh $user_name@$computer_ip bash .___remote_setup/auto-install.bash

_step "Done!"

echo "You may now enjoy your setup computer :)"
