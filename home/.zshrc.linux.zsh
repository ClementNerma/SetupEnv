#!/usr/bin/zsh

#
# This file is a script run during shell startup only on Linux platforms
#

# Set up path to main directories
export HOMEDIR="$HOME"
export TEMPDIR="/tmp"
export TRASHDIR="$HOMEDIR/.trasher"
export DLDIR="$HOMEDIR/Downloads"
export SOFTWAREDIR="$HOMEDIR/Logiciels"
export HOMEPROJDIR="$HOMEDIR/Projets/Home"
export WORKPROJDIR="$HOMEDIR/Projets/Work"

# Allow fast editing of this file
alias zert="nano ~/.zshrc.linux.zsh && source ~/.zshrc.linux.zsh"