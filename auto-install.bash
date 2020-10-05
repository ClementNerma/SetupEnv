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
export TMPDIR="/tmp/_auto_installer"

# Beginning of the installer!
echo
echo -e "\e[92m=================================\e[0m"
echo -e "\e[92m====== AUTOMATED INSTALLER ======\e[0m"
echo -e "\e[92m=================================\e[0m"

_step "Checking compatibility..."
arch="$(dpkg --print-architecture)"
if [[ $arch != "amd64" ]] && [[ $arch != "armhf" ]]; then
	echo "ERROR: Unsupported CPU architecture detected: ${arch}"
	echo "ERROR: Exiting now."
	exit 1
fi

if [[ $arch = "armhf" ]]; then
	echo -e "\e[33m\!/ WARNING: ARM v7 architecture detected, installation process may be slower as it is optimized for x86 platforms.\e[0m"
fi

_step "Creating temporary directory..."
rm -rf "$TMPDIR"
mkdir -p "$TMPDIR"

_step "Ensuring the 'sudo' command is available..."

if [ ! -x /usr/bin/sudo ]; then
	echo -e "\e[33m\!/ WARNING: 'sudo' command was not found, installing it for compatibility reasons.\e[0m"
	su -s /bin/bash -c "apt install sudo" root
fi

_step "Updating repositories..."
sudo apt update

_step "Installing required packages..."
sudo apt install -y zsh git wget curl sed grep unzip apt-transport-https dos2unix

_step "Installing Rust & Cargo..."

if [ -d ~/.rustup ]; then
	echo -e "\e[33m\!/ A previous version of \e[32mRust \e[33mwas detected ==> backing it up to \e[32m~/.rustup.bak\e[33m...\e[0m"
	rm -rf ~/.rustup.bak
	mv ~/.rustup ~/.rustup.bak
fi

if [ -d ~/.cargo ]; then
	echo -e "\e[33m\!/ A previous version of \e[32mCargo \e[33mwas detected ==> backing it up to \e[32m~/.cargo.bak\e[33m...\e[0m"
	rm -rf ~/.cargo.bak
	mv ~/.cargo ~/.cargo.bak
fi

curl https://sh.rustup.rs -sSf | sh -s -- --default-toolchain stable -y
source $HOME/.cargo/env # Just for this session

_step "Installing tools for Rust..."
sudo apt install -y llvm libclang-dev

_step "Installing NVM..."
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash

# Load NVM for the current session
export NVM_DIR="$HOME/.nvm"
\. "$NVM_DIR/nvm.sh"

_step "Installing Node.js & NPM..."
nvm install node --latest-npm

_step "Installing Yarn..."
npm i -g yarn
yarn -v # Just to be sure Yarn was installed correctly

_step "Installing pnpm..."
npm i -g pnpm
pnpm -v # Just to be sure pnpm was installed correctly

_step "Installing compilation tools..."
sudo apt install -y build-essential gcc g++ make perl

_step "Installing required tools for some Rust libraries..."
sudo apt install -y pkg-config libssl-dev

_step "Installing Micro..."
curl https://getmic.ro | bash
sudo mv ./micro /usr/bin/micro

_step "Installing Tokei..."
if [[ $arch != "armhf" ]]; then
	curl -s https://api.github.com/repos/XAMPPRocky/tokei/releases/latest \
	| grep "browser_download_url.*tokei-x86_64-unknown-linux-gnu.tar.gz" \
	| cut -d : -f 2,3 \
	| tr -d \" \
	| wget -qi - --show-progress -O "$TMPDIR/tokei.tar.gz"
	tar zxf "$TMPDIR/tokei.tar.gz"
	sudo mv tokei /usr/local/bin
else
	curl -s https://api.github.com/repos/XAMPPRocky/tokei/releases/latest \
	| grep "browser_download_url.*tokei-armv7-unknown-linux-gnueabihf.tar.gz" \
	| cut -d : -f 2,3 \
	| tr -d \" \
	| wget -qi - --show-progress -O "$TMPDIR/tokei.tar.gz"
	tar zxf "$TMPDIR/tokei.tar.gz"
	sudo mv tokei /usr/local/bin
fi

_step "Installing Bat..."
if [[ $arch != "armhf" ]]; then
	curl -s https://api.github.com/repos/sharkdp/bat/releases/latest \
	| grep "browser_download_url.*bat_.*_amd64.deb" \
	| cut -d : -f 2,3 \
	| tr -d \" \
	| wget -qi - --show-progress -O "$TMPDIR/bat.deb"
	sudo dpkg -i "$TMPDIR/bat.deb"
else
	curl -s https://api.github.com/repos/sharkdp/bat/releases/latest \
	| grep "browser_download_url.*bat_.*_armhf.deb" \
	| cut -d : -f 2,3 \
	| tr -d \" \
	| wget -qi - --show-progress -O "$TMPDIR/bat.deb"
	sudo dpkg -i "$TMPDIR/bat.deb"
fi

_step "Installing Exa..."
if [[ $arch != "armhf" ]]; then
	curl -s https://api.github.com/repos/ogham/exa/releases/latest \
	| grep "browser_download_url.*exa-linux-x86_64-.*.zip" \
	| cut -d : -f 2,3 \
	| tr -d \" \
	| wget -qi - --show-progress -O "$TMPDIR/exa.zip"
	unzip "$TMPDIR/exa.zip" -d "$TMPDIR/exa"
	sudo mv "$TMPDIR/exa/"exa-* /usr/local/bin/exa
else
	cargo install exa
fi

_step "Installing Fd..."
if [[ $arch != "armhf" ]]; then
	curl -s https://api.github.com/repos/sharkdp/fd/releases/latest \
	| grep "browser_download_url.*fd-musl_.*_amd64.deb" \
	| cut -d : -f 2,3 \
	| tr -d \" \
	| wget -qi - --show-progress -O "$TMPDIR/fd.deb"
	sudo dpkg -i "$TMPDIR/fd.deb"
else
	curl -s https://api.github.com/repos/sharkdp/fd/releases/latest \
	| grep "browser_download_url.*fd-musl_.*_armhf.deb" \
	| cut -d : -f 2,3 \
	| tr -d \" \
	| wget -qi - --show-progress -O "$TMPDIR/fd.deb"
	sudo dpkg -i "$TMPDIR/fd.deb"
fi

_step "Installing Fuzzy Finder..."
if [[ -d ~/.fzf ]]; then
	echo -e "\e[33m\!/ A previous version of \e[32mFuzzy Finder \e[33mwas detected ==> backing it up to \e[32m~/.fzf.bak\e[33m...\e[0m"
	mv ~/.fzf ~/.fzf.bak
else
	git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
	~/.fzf/install --all
fi

_step "Installing Trasher..."
if [[ $arch != "armhf" ]]; then
	curl -s https://api.github.com/repos/ClementNerma/Trasher/releases/latest \
	| grep "browser_download_url.*trasher-linux-x86_64" \
	| cut -d : -f 2,3 \
	| tr -d \" \
	| wget -qi - --show-progress -O "$TMPDIR/trasher.zip"
	unzip "$TMPDIR/trasher.zip" -d "$TMPDIR/trasher"
	sudo mv "$TMPDIR/trasher/"trasher-* /usr/local/bin/trasher
	sudo chmod +x /usr/local/bin/trasher
else
	cargo install trasher

	TRASHER_SUPPOSED_PATH="/home/$USER/.cargo/bin/trasher"

	if [[ ! -f "$TRASHER_SUPPOSED_PATH" ]]; then
		echo -e "\e[33m\!/ WARNING: Symbolic link for \e[32mTrasher \e[33mpoints to invalid location\e[32m$TRASHER_SUPPOSED_PATH\e[33m! \e[0m"
	fi

	sudo ln -s "$TRASHER_SUPPOSED_PATH" /usr/local/bin/trasher
fi

_step "Installing Youtube-DL..."
sudo curl -L https://yt-dl.org/downloads/latest/youtube-dl -o /usr/local/bin/youtube-dl
sudo chmod a+rx /usr/local/bin/youtube-dl

_step "Installing AtomicParsley for Youtube-DL..."
sudo apt install atomicparsley

_step "Installing utilities..."
sudo apt install -y pv htop ncdu net-tools rsync

_step "Backing up important files before overriding them..."
mv ~/.zshrc ~/.zshrc.bak

if [ -f ~/.bashrc ]; then
	mv ~/.bashrc ~/.bashrc.bak
fi

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

echo
echo You may want to reboot now.
if [ -x /sbin/rboot ]; then
	echo
	echo
	if [ ! -x /usr/bin/sudo ]; then
		echo \> reboot
	else
		echo \> sudo reboot
	fi
fi
echo
echo
