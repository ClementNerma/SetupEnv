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

# ZSH custom library
source $HOME/.zshrc.lib.zsh

# Integration for Powerlevel10k
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# .zshrc profiling
if (( ${+ZSH_PROFILING} )); then
	PROFILING_PATH="$TEMPDIR/zshrc-profiling.txt"
	zprof > "$PROFILING_PATH"
	echo Profiling informations written to: "$PROFILING_PATH"
fi
