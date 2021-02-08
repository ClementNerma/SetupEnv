
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

# Software: Exa
alias ls="exa --all --long --group-directories-first --color-scale"
alias tree="ls --tree"

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

# Set the default editor
export EDITOR="micro"
alias nano="$EDITOR"

# Allow to sign Git commits with GPG
export GPG_TTY=$(tty)

# Integration for Pueue
(nohup pueued >/dev/null 2>&1 &)
alias pu="pueue"

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
export PATH="$HOME/.local/bin:$PATH"

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
