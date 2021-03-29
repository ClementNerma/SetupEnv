
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
alias gc="git checkout"
alias gp="git push"
alias gpb="git push --set-upstream origin \$(git rev-parse --abbrev-ref HEAD)"
alias gop="git reflog expire --expire=now --all && git gc --prune=now && git repack -a -d --depth=250 --window=250"

function gitcommit() {
    if (( ${#1} > 72 )); then
        echowarn "Maximum recommanded message length is \z[cyan]°72\z[]° characters but provided one is \z[cyan]°${#1}\z[]° long."

        if [[ $1 != *"\n"* ]]; then
            echoerr "Rejecting the commit message, you can use a newline symbol to skip this limitation."
            return 1
        fi
    fi

    git commit -m "$1" "${@:2}"
}

alias gm="gitcommit"

# Set the default editor
export EDITOR="nano"
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
ZOXIDE_LOAD_FILE="$(dirname "$ADF_SUB_DIR")/zoxide.zsh"

if [[ ! -f "$ZOXIDE_LOAD_FILE" ]]; then
	zoxide init zsh > "$ZOXIDE_LOAD_FILE"
fi

# NOTE: Forced to "source" as a simple "eval" isn't enough to declare aliases
source "$ZOXIDE_LOAD_FILE"
