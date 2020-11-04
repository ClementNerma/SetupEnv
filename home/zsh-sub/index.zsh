#
# This file contains custom functions, aliases and configurations.
# It is loaded during the execution of ~/.zshrc
# The goal is to use a separate file for custom definitions and thus be able to reload just that, instead of
#  reloading the whole configuration each time ; as well as to keep the ~/.zshrc file as clean and simple as possible.
#

# Set path to ZSH sub-files
export ZSH_SUB_DIR=$(dirname "${(%):-%x}")

# Load the configuration file
source "$ZSH_SUB_DIR/config.zsh"

# Synchronize a directory
function rsync_dir() {
	if [[ $SUDO_RSYNC = "true" ]]; then
		echo WARNING: Using rsync in SUDO mode.
	fi

	local started=0
	local failed=0

	echo Starting transfer...
	while [[ $started -eq 0 || $failed -eq 1 ]]
	do
	    started=1
	    failed=0

		if [[ $SUDO_RSYNC = "true" ]]; then
			sudo rsync --archive --verbose --partial --progress "$1" "$2" ${@:3}
		else
			rsync --archive --verbose --partial --progress "$1" "$2" ${@:3}
		fi
	
		if [[ $? -ne 0 ]]
		then
			echo Transfer failed. Retrying in 5 seconds...
			sleep 5s
			failed=1
		fi
	done
	echo Done.
}

# Copy a project to another directory without its dependencies and temporary files
function cp_proj_nodeps() {
	if [[ -d "$2" ]]; then
		if [[ $3 != "-f" && $3 != "--force" ]]; then
			echo "Target directory exists. To overwrite it, provide '-f' or '--force' as a third argument."
			return 1
		fi
	fi

	rsync --exclude '*.tmp' --exclude '.rustc_info.json' \
		  --exclude 'node_modules/' --exclude 'pnpm-store/' --exclude 'common/temp/' --exclude '.rush/temp/' \
		  --exclude 'build/' --exclude 'dist/' \
		  --exclude 'target/debug/' --exclude 'target/release/' --exclude 'target/wasm32-unknown-unknown/' \
		  --archive --partial --progress \
		  --delete --delete-excluded "$1/" "$2" "${@:3}"
}

# Run a Cargo project located in the projects directory
function cargext() {
	cargo run "--manifest-path=$PROJDIR/$1/Cargo.toml" -- ${@:2}
}

# Run a Cargo project located in the projects directory in release mode
function cargextr() {
	cargo run "--manifest-path=$PROJDIR/$1/Cargo.toml" --release -- ${@:2}
}

# Rename a Git branch
function gitrename() {
    local old_branch=$(git rev-parse --abbrev-ref HEAD)
	echo Renaming branch "$old_branch" to "$1"...
	git branch -m "$1"
	git push origin -u "$1"
	git push origin --delete "$old_branch"
}

# A simple 'rm' with progress
function rmprogress() {
	if [ -z "$1" ]; then
		return
	fi
	
	command rm -rv "$1" | pv -l -s $( du -a "$1" | wc -l ) > /dev/null
}

# Archive a directory into a .tar file
function tarprogress() {
	tar cf - "$1" -P | pv -s $(du -sb "$1" | awk '{print $1}') > "$1.tar"
}

# Archive a directory into a .tar.gz file
function targzprogress() {
	tar czf - "$1" -P | pv -s $(du -sb "$1" | awk '{print $1}') > "$1.tar"
}

# Measure time a command takes to complete
function howlong() {
	local started=$(($(date +%s%N)))
	"$@"
	local finished=$(($(date +%s%N)))
	local elapsed=$(((finished - started) / 1000000))

	printf 'Command "'
	printf '%s' "${@[1]}"
	if [[ ! -z $2 ]]; then printf ' %s' "${@:2}"; fi
	printf '" completed in ' "$@"

	local elapsed_s=$((elapsed / 1000))
	local D=$((elapsed_s/60/60/24))
	local H=$((elapsed_s/60/60%24))
	local M=$((elapsed_s/60%60))
	local S=$((elapsed_s%60))
	if [ $D != 0 ]; then printf "${D}d "; fi
	if [ $H != 0 ]; then printf "${H}h "; fi
	if [ $M != 0 ]; then printf "${M}m "; fi
	
	local elapsed_ms=$((elapsed % 1000))
	printf "${S}.%03ds" $elapsed_ms

	printf "\n"
}

# Allow fast reloading of this file after changes
alias reload="source ${(%):-%x}"

# Allow fast editing of this file, with automatic reloading
alias zer="nano ${(%):-%x} && reload"

# Load the local configuration
source "$ZSH_SUB_DIR/local/env.zsh"

# Load platform-specific configuration
if grep -q microsoft /proc/version; then
	if [[ -d "$ZSH_SUB_DIR/linux" ]]; then
		command rm -rf "$ZSH_SUB_DIR/__linux"
		mv "$ZSH_SUB_DIR/linux" "$ZSH_SUB_DIR/__linux"
	fi

	source "$ZSH_SUB_DIR/wsl/env.zsh"
else
	if [[ -d "$ZSH_SUB_DIR/wsl" ]]; then
		command rm -rf "$ZSH_SUB_DIR/__wsl"
		mv "$ZSH_SUB_DIR/wsl" "$ZSH_SUB_DIR/__wsl"
	fi

	source "$ZSH_SUB_DIR/linux/env.zsh"
fi

# Load the updater
source "$ZSH_SUB_DIR/updater.zsh"

# Load the script for the main computer (if applies)
if [ $ZSH_MAIN_PERSONAL_COMPUTER = 1 ]; then
	source "$ZSH_SUB_DIR/main-pc.zsh"
fi

# Ensure main directories are defined
if [[ -z $HOMEDIR ]]; then echo -e "\e[91mERROR: Directory variable \e[92m\$HOMEDIR\e[91m is not defined!\e[0m"; fi
if [[ ! -d "$HOMEDIR" ]]; then echo -e "\e[91mERROR: Home directory at location \e[93m$HOMEDIR\e[91m does not exist!\e[0m"; fi

if [[ -z $TEMPDIR ]]; then echo -e "\e[91mERROR: Directory variable \e[92m\$TEMPDIR\e[91m is not defined!\e[0m"; fi
if [[ -z $TRASHDIR ]]; then echo -e "\e[91mERROR: Directory variable \e[92m\$TRASHDIR\e[91m is not defined!\e[0m"; fi
if [[ -z $DLDIR ]]; then echo -e "\e[91mERROR: Directory variable \e[92m\$DLDIR\e[91m is not defined!\e[0m"; fi
if [[ -z $SOFTWAREDIR ]]; then echo -e "\e[91mERROR: Directory variable \e[92m\$SOFTWAREDIR\e[91m is not defined!\e[0m"; fi
if [[ -z $PROJDIR ]]; then echo -e "\e[91mERROR: Directory variable \e[92m\$PROJDIR\e[91m is not defined!\e[0m"; fi
if [[ -z $WORKDIR ]]; then echo -e "\e[91mERROR: Directory variable \e[92m\$WORKDIR\e[91m is not defined!\e[0m"; fi

if [[ -z $HOMEDIR || ! -d $HOMEDIR || -z $DLDIR || -z $PROJDIR || -z $WORKDIR || -z $TEMPDIR || -z $SOFTWAREDIR || -z $TRASHDIR ]]; then
	read "?Press <Enter> to exit, or <Ctrl+C> to get a without-setupenv ZSH prompt ('zerupdate' command will be available) "
	exit
fi

# Ensure these directories exist
if [[ ! -d $TEMPDIR ]]; then mkdir -p "$TEMPDIR"; fi
if [[ ! -d $DLDIR ]]; then mkdir -p "$DLDIR"; fi
if [[ ! -d $TRASHDIR ]]; then mkdir -p "$TRASHDIR"; fi
if [[ ! -d $PROJDIR ]]; then mkdir -p "$PROJDIR"; fi
if [[ ! -d $WORKDIR ]]; then mkdir -p "$WORKDIR"; fi
if [[ ! -d $SOFTWAREDIR ]]; then mkdir -p "$SOFTWAREDIR"; fi

# Shortcuts for main directories in paths
alias gohome="cd $HOMEDIR"
alias gotemp="cd $TEMPDIR"
alias godl="cd $DLDIR"
alias gotrash="cd $TRASHDIR"
alias goproj="cd $PROJDIR"
alias gowork="cd $WORKDIR"
alias gosoft="cd $SOFTWAREDIR"

# Run Bash
alias bash="BASH_NO_ZSH=true bash"

# Go to a directory located in the projects directory
p() {
	if [[ -z "$1" ]]; then
		echo Please provide a project to go to.
	else
		cd "$PROJDIR/$1"
	fi
}

# Software: Trasher
trasher() { sudo trasher --create-trash-dir --trash-dir "$TRASHDIR" "$@" }
rm() { trasher rm --move-ext-filesystems "$@" }
rmperma() { trasher rm --permanently "$@" }
unrm() { trasher unrm --move-ext-filesystems "$@" }

# Software: Exa
alias ls="exa --all --long --group-directories-first --color-scale"
alias tree="ls --tree"

# Software: Micro
alias nano="micro"
alias e="micro"

# Software: Bat
alias cat="bat --theme=base16"

# Software: Git
alias ga="git add"
alias gb="git checkout -b"
alias gd="git diff"
alias gs="git status"
alias gr="git reset"
alias gl="git log"
alias gm="git commit -m"
alias gc="git checkout"
alias gp="git push"
alias gpb="git push --set-upstream origin \$(git rev-parse --abbrev-ref HEAD)"
alias gop="git reflog expire --expire=now --all && git gc --prune=now && git gc --aggressive --prune=now"

# Software: Youtube-DL
alias ytdlt="youtube-dl -f bestvideo+bestaudio/best --embed-thumbnail"
alias ytdlnt="youtube-dl -f bestvideo+bestaudio/best"

function ytdl() {
	if [[ $1 == "https://www.youtube.com/"* ]]; then
		ytdlnt "$1" "$@"
	else
		ytdlt "$1" "$@"
	fi
}

# Set the default editor
export EDITOR="micro"

# Allow to sign Git commits with GPG
export GPG_TTY=$(tty)

# Integration for Rust (if installed)
if [[ -f ~/.cargo/env ]]; then
	source ~/.cargo/env
fi

# Integration for Go
if [[ -d ~/go ]]; then
    export GOPATH=$HOME/go
    export PATH=$PATH:/usr/local/go/bin:$GOPATH/bin
fi

# Integration for Python
export PATH="/home/clement/.local/bin:$PATH"

# Integration for Volta
export VOLTA_HOME="$HOME/.volta"
export PATH="$VOLTA_HOME/bin:$PATH"

# Integration for FZF
source ~/.fzf.zsh

# Integration for Zoxide
ZOXIDE_LOAD_FILE="$(dirname "$ZSH_SUB_DIR")/zoxide.zsh"

if [[ ! -f "$ZOXIDE_LOAD_FILE" ]]; then
	zoxide init zsh > "$ZOXIDE_LOAD_FILE"
fi

# NOTE: Forced to "source" as a simple "eval" isn't enough to declare aliases
source "$ZOXIDE_LOAD_FILE"

alias cd="z"

# Integration for Deno
export DENO_INSTALL="$HOME/.deno"
export PATH="$DENO_INSTALL/bin:$PATH"

# Dir hashes
hash -d Home=$HOMEDIR
hash -d Projects=$PROJDIR
hash -d Work=$WORKDIR
hash -d Downloads=$DLDIR
hash -d Temp=$TEMPDIR
hash -d Software=$SOFTWAREDIR

# Go to the a specific folder on startup, except if the shell has been started in a custom directory
if [[ $DISABLE_DIR_HOME_SWITCHING != 1 ]]; then
	if [ "$(pwd)" = "$HOME" ]; then
		if [ $ZSH_MAIN_PERSONAL_COMPUTER = 1 ]; then
			goproj
		else
			godl
		fi
	fi
fi

# Load platform-specific scripts
if grep -q microsoft /proc/version; then
	source "$ZSH_SUB_DIR/wsl/script.zsh"
else
	source "$ZSH_SUB_DIR/linux/script.zsh"
fi

# Load the local script
source "$ZSH_SUB_DIR/local/script.zsh"