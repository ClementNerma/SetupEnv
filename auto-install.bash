#!/bin/bash
#
# WARNING:
# This installer should **NOT** contain **ANY** private information, as it is meant to be used on
#  distant servers, computers at work, etc.
#
#
# Make the script exit on error
set -oeE pipefail
trap "printf '\nerror: Script failed: see failed command above.\n'" ERR

# Display a number of seconds in a human-readable format
function print_seconds {
	local T=$1
	local D=$((T/60/60/24))
	local H=$((T/60/60%24))
	local M=$((T/60%60))
	local S=$((T%60))
	(( $D > 0 )) && printf '%d days ' $D
	(( $H > 0 )) && printf '%d hours ' $H
	(( $M > 0 )) && printf '%d minutes ' $M
	(( $D > 0 || $H > 0 || $M > 0 )) && printf 'and '
	printf '%d seconds\n' $S
}

# Show current step
function _step() {
	CURRENT_STEP=$((CURRENT_STEP + 1))
	echo
	echo -e "\e[92m>>> Step ${CURRENT_STEP}/${TOTAL_STEPS}: $@\e[0m"
	echo
}

# Indicate the current step is skipped for whatever reason
function _skip() {
	echo -e "\e[95m>>> Skipping this step: $@"
}

# Get the total number of steps
REALPATH=$(realpath "$0")
TOTAL_STEPS=$(grep -c "^[\s\t]*_step" "$REALPATH")
CURRENT_STEP=0

# Get current timestamp
AUTO_INSTALLER_STARTED_AT=$(date +%s)

# Choose a temporary directory
TMPDIR="/tmp/_setupenv_autoinstaller_$AUTO_INSTALLER_STARTED_AT"

# Beginning of the installer!
echo
echo -e "\e[92m=================================\e[0m"
echo -e "\e[92m====== AUTOMATED INSTALLER ======\e[0m"
echo -e "\e[92m=================================\e[0m"

_step "Checking compatibility..."
arch="$(dpkg --print-architecture)"
if [[ $arch != "amd64" && $arch != "arm64" ]]; then
	echo "ERROR: Unsupported CPU architecture detected: ${arch}"
	echo "ERROR: Exiting now."
	exit 1
fi

_step "Creating temporary directory..."
rm -rf "$TMPDIR"
mkdir -p "$TMPDIR"

_step "Ensuring the 'sudo' command is available..."

if [ ! -x /usr/bin/sudo ]; then
	echo -e "\e[33m\!/ WARNING: 'sudo' command was not found, installing it for compatibility reasons.\e[0m"
	su -s /bin/bash -c "apt install sudo" root
fi

_step "Backing up important files before overriding them..."

if [ -d ~/zsh-sub ]; then
	echo -e "\e[33m\!/ A previous version of \e[32mSetup Env \e[33mwas detected ==> backing it up to \e[32m~/zsh-sub.$AUTO_INSTALLER_STARTED_AT\e[33m...\e[0m"
	mv ~/zsh-sub ~/zsh-sub.$AUTO_INSTALLER_STARTED_AT
fi

if [ -f ~/.zshrc ]; then
	mv ~/.zshrc ~/.zshrc.bak
fi

if [ -f ~/.bashrc ]; then
	mv ~/.bashrc ~/.bashrc.bak
fi

_step "Updating repositories..."
sudo apt update

_step "Installing required packages..."
sudo apt install -y zsh git curl

_step "Installing Oh-My-ZSH!..."

if [ -d ~/.oh-my-zsh ]; then
	echo -e "\e[33m\!/ A previous version of \e[32mOh-My-ZSH! \e[33mwas detected ==> backing it up to \e[32m~/.oh-my-zsh.bak\e[33m...\e[0m"
	rm -rf ~/.oh-my-zsh.bak
	mv ~/.oh-my-zsh ~/.oh-my-zsh.bak
fi

sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" -- --unattended

_step "Installing plugins for Oh-My-ZSH!..."
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/themes/powerlevel10k

_step "Copying configuration files..."
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cp -a "$SCRIPT_DIR/home/." ~/

_step "Cleaning up temporary directory..."
rm -rf "$TMPDIR"

echo Done\!

# Unset 'sudo' alias if it was set up at the beginning of the script
if [ ! -x /usr/bin/sudo ]; then
	unset -f sudo
fi

printf "Automated installer completed in "
print_seconds "$(($(date +%s) - ${AUTO_INSTALLER_STARTED_AT}))"

echo ""
echo "> Please restart your shell !"
echo ""