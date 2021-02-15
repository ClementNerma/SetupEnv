ZSH_DISABLE_COMPFIX=true 

# .zshrc profiling (closes at the end of the file)
if (( ${+ZSH_PROFILING} )); then
	zmodload zsh/zprof
fi

# Profiles performances of the .zshrc configuration
function zerperf() {
	ZSH_PROFILING=true zsh -c "source ~/.zshrc && exit"
}

# Increase history capacity
export HISTSIZE=10000000
export SAVEHIST=10000000

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Which plugins would you like to load?
plugins=(git zsh-syntax-highlighting zsh-autosuggestions)

# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="powerlevel10k/powerlevel10k"

# Load Powerlevel10k
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Load Oh My ZSH!
source $ZSH/oh-my-zsh.sh

# ZSH custom library
source $HOME/autodotfiles/index.zsh

# .zshrc profiling
if (( ${+ZSH_PROFILING} )); then
	PROFILING_PATH="$TEMPDIR/zshrc-profiling.txt"
	zprof > "$PROFILING_PATH"
	cat "$PROFILING_PATH"
	echo Profiling informations written to: "$PROFILING_PATH"
fi
