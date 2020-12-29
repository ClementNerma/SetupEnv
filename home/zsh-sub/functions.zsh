#
# This file defines global functions and aliases
#

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

# Backup a project
function bakproj() {
	cp_proj_nodeps "$1" "$2.bak"
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
		return 1
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

# Create a directory and go into it
mkcd() {
	if [[ ! -d "$1" ]]; then
		mkdir -p "$1"
	fi

	cd "$1"
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

# Software: Github
function ghdl() {
	if [[ $1 != "https://github.com/"* ]]; then
		echoerr "Invalid GitHub repository URL: \e[93m$1"
	fi

	local repoauthor=$(echo "$1" | cut -d'/' -f4)
	local reponame=$(echo "$1" | cut -d'/' -f5)

	echosuccess "Cloning from repository: \e[93m$repoauthor/$reponame\e[92m..."

	if [[ -d "$reponame" ]]; then
		echoerr "> Directory \e[95m$reponame\e[91m already exists!"
		return 1
	fi

	echo -e "\e[34m> Fetching default branch..."
	local branch=$(curl -s "https://api.github.com/repos/$repoauthor/$reponame" | jq -r ".default_branch")

	if [[ $branch == "null" ]]; then
		echoerr "> Failed to determine default branch!"
		return 1
	fi

	local filename="$reponame.zip"
	echo -e "\e[34m> Fetching archive for branch \e[93m$branch\e[34m to \e[95m$filename\e[34m..."
	
	local zipurl="https://codeload.github.com/$repoauthor/$reponame/zip/$branch"

	if ! wget -q --show-progress "$zipurl" -O "$filename"; then
		echoerr "> Failed to fetch archive from URL: \e[93m$zipurl\e[91m!"
		return 1
	fi

	echo -e "\e[34m> Extracting archive to directory \e[93m$reponame\e[34m..."
	unzip -q "$filename"
	mv "$reponame-$branch" "$reponame"

	echosuccess "Done!"
}

# Software: Youtube-DL
function ytdlbase() {
	youtube-dl -f bestvideo+bestaudio/best --add-metadata "$@"
}

function ytdl() {
	if [[ $1 == "https://www.youtube.com/"* ]]; then
		ytdlbase "$@"
	else
		ytdlbase --embed-thumbnail "$@"
	fi
}

# Download a YouTube video with separate french and english subtitle files (if available)
function ytdlsubs() {
	ytdl "$@" --write-sub --sub-lang "fr,en"
}

# Set the default editor
export EDITOR="micro"

# Allow to sign Git commits with GPG
export GPG_TTY=$(tty)

# Integration for Pueued
(nohup pueued >/dev/null 2>&1 &)
alias pu="pueued"

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

# Integration for Deno
export DENO_INSTALL="$HOME/.deno"
export PATH="$DENO_INSTALL/bin:$PATH"
