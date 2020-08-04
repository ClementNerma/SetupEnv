#!/usr/bin/zsh

#
# This file is a script run during shell startup only on Linux platforms
#

# Set up path to main directories
export HOMEDIR="$HOME"
export TEMPDIR="/tmp"

# Allow fast editing of this file
alias zert="nano ~/.zshrc.wsl.zsh && source ~/.zshrc.wsl.zsh"