ZSH_DISABLE_COMPFIX=true 

# .zshrc profiling (closes at the end of the file)
if (( ${+ZSH_PROFILING} )); then
	zmodload zsh/zprof
fi

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="powerlevel10k/powerlevel10k"

# Which plugins would you like to load?
plugins=(git zsh-syntax-highlighting zsh-autosuggestions)

# Load Oh My ZSH!
source $ZSH/oh-my-zsh.sh

# Profiles performances of this .zshrc
function profile_zshrc() {
	ZSH_PROFILING=true zsh -c "exit"
}

# Synchronize a directory
function rsync_dir() {
	STARTED=0
	FAILED=0
	echo Starting transfer...
	while [[ $STARTED -eq 0 || $FAILED -eq 1 ]]
	do
	    STARTED=1
	    FAILED=0
		rsync --archive --verbose --partial --progress "$1" "$2"
	
		if [[ $? -ne 0 ]]
		then
			echo Transfer failed. Retrying in 5 seconds...
			sleep 5s
			FAILED=1
		fi
	done
	echo Done.
}

# Run a Cargo project located in the projects directory
function cargext() {
	PROJ_NAME=$1
	shift
	cargo run "--manifest-path=$PROJDIR/$PROJ_NAME/Cargo.toml" -- $*
}

# Run a Cargo project located in the projects directory in release mode
function cargextr() {
	PROJ_NAME=$1
	shift
	cargo run "--manifest-path=$PROJDIR/$PROJ_NAME/Cargo.toml" --release -- $*
}

# Rename a Git branch
function gitrename() {
    OLD_BRANCH=$(git rev-parse --abbrev-ref HEAD)
	echo Renaming branch "$OLD_BRANCH" to "$1"...
	git branch -m "$1"
	git push origin -u "$1"
	git push origin --delete "$OLD_BRANCH"
}

# A simple 'rm' with progress
function rmprogress() {
	if [ -z "$1" ]; then
		return
	fi
	
	rm -rv "$1" | pv -l -s $( du -a "$1" | wc -l ) > /dev/null
}

# Allow fast reloading of .zshrc file after changes
alias reload="source ~/.zshrc"

# Allow fast editing of .zshrc
alias zeditrc="nano ~/.zshrc && reload"
alias zer="zeditrc"

# Determine path to main directories
if grep -q microsoft /proc/version; then
	source ~/.zshrc.wsl.zsh
else
	source ~/.zshrc.linux.zsh
fi

export PROJDIR="$HOMEDIR/Projets"
export DWDIR="$HOMEDIR/Downloads"
export SFWDIR="$HOMEDIR/Logiciels"

# Ensure these directories exist
if [[ ! -d $DWDIR ]]; then mkdir "$DWDIR"; fi
if [[ ! -d $PROJDIR ]]; then mkdir "$PROJDIR"; fi
if [[ ! -d $TEMPDIR ]]; then mkdir "$TEMPDIR"; fi
if [[ ! -d $SFWDIR ]]; then mkdir "$SFWDIR"; fi

# Shortcuts for main directories in paths
alias goproj="cd $PROJDIR"
alias godw="cd $DWDIR"
alias gotemp="cd $TEMPDIR"

# Go to a directory located in the projects directory
p() { cd "$PROJDIR/$1" }

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
alias gs="git status"
alias gr="git reset"
alias gl="git log"
alias gm="git commit -m"
alias gc="git checkout"
alias gp="git push"
alias gpb="git push --set-upstream origin \$(git rev-parse --abbrev-ref HEAD)"

# Software: Youtube-DL
alias ytdl="youtube-dl -f bestvideo+bestaudio/best"

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

# Integration for Node.js
# NVM is used here to be able to easily switch between multiple Node.js versions
# But as it's awfully slow to load, it is lazy-loaded: when a Node.js-related command is called, NVM is loaded if it's not already
function load_nvm() {
	export NVM_DIR="$HOME/.nvm"
	[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
	[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
}

# Mark a command as requiring Node.js to be loaded first
# This will create an alias that removes itself, loads NVM, then runs the requested command
# On future calls, the alias won't be there anymore and so there will be no performance overhead
function nvm_alias() {
	for name in "$@"; do
		# The 'eval' is here to allow
		alias ${name}="unalias $* && load_nvm && eval $name"
	done
}

nvm_alias node npm yarn rush

# Integration for FZF
source ~/.fzf.zsh

# Integration for Deno
export DENO_INSTALL="$HOME/.deno"
export PATH="$DENO_INSTALL/bin:$PATH"

# Dir hashes
hash -d Home=$HOMEDIR
hash -d Projects=$PROJDIR
hash -d Downloads=$DWDIR
hash -d Temp=$TEMPDIR
hash -d Software=$SFWDIR

# Go to projects folder on startup, except if the shell has been started in a custom directory
#if [ "$(pwd)" = "$HOME" ]; then
#  goproj
#fi

# Integration for Powerlevel10k
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# .zshrc profiling
if (( ${+ZSH_PROFILING} )); then
	PROFILING_PATH="$TEMPDIR/zshrc-profiling.txt"
	zprof > "$PROFILING_PATH"
	echo Profiling informations written to: "$PROFILING_PATH"
fi
