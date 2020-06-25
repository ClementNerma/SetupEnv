#!/usr/bin/zsh

# Run a Windows through PowerShell
# e.g. "win echo Hello!" will display "Hello!" by running PowerShell transparently
function win() {
  powershell.exe -command "$@"
}

# Run a Windows through PowerShell and use its content in WSL
# This uses "dos2unix" because Window's newline symbols are different than Linux's ones, thus resulting in weird string behaviours
# The downside is that some commands won't work correctly with dos2unix so this function should only be used when the output of a
#  windows command is meant to be used later on.
function win2text() {
  win "$@" | dos2unix
}

# Make an alias to a Windows command
# e.g. "winalias mycmd" will allow to use "mycmd" by running PowerShell transparently
function winalias() {
  for name in "$@"; do
    alias "${name}=win ${name}";
  done
}

# Create project using hand-made template
function create-project () {
  cp -R "$PROJDIR/_Done/Templates/$1" "$2"
  cd "$2"
  bash TEMPLATE_INIT.sh
  rm TEMPLATE_INIT.sh
}

# Run a Cargo project located in the projects directory, on Windows
function cargextw() {
    PROJ_NAME=$1
    shift
	win cargo run "--manifest-path=C:\\Users\\cleme\\Projets\\$PROJ_NAME\\Cargo.toml" -- $*
}

# Run a Cargo project located in the projects directory in release mode, on Windows
function cargextwr() {
    PROJ_NAME=$1
    shift
	win cargo run "--manifest-path=C:\\Users\\cleme\\Projets\\$PROJ_NAME\\Cargo.toml" --release -- $*
}

# Remount a drive in WSL
function remount() {
	sudo umount /mnt/${1:l} 2> /dev/null
	sudo mkdir /mnt/${1:l} 2> /dev/null
	sudo mount -t drvfs "${1:u}:" /mnt/${1:l}
}

# Get Windows username
export WINUSER=$(win2text '$env:UserName')

# Set up path to main directories
export HOMEDIR="/mnt/c/Users/$WINUSER"
export TEMPDIR="/mnt/c/Temp/__wsltemp"

# Ensure temporary directory exists
if [ ! -d "$TEMPDIR" ]; then
  mkdir -p "$TEMPDIR"
fi

# Go to windows' home directory
alias gowin="cd $HOMEDIR"

# Integration of some Windows tools
winalias code

# Open a file using the Windows association system
open() {
	explorer.exe "$1"
	echo # Fix error status code from "explorer.exe"
}

alias here="open ."

# Copy a file to clipboard
clip() {
  cat "$1" | clip.exe
}

# Software: Docker
alias docker="win docker"
alias docker-compose="win docker-compose"

# Software: Android's Platform Tools
function _android() {
  local tool_path="$SFWDIR/PlatformTools"

  if [[ ! -f "$tool_path/$1" ]]; then
    echo -e "\e[91mERROR: Could not find Platform Tools binary \e[93m$1\e[91m at path \e[93m$tool_path\e[0m"
  else
    "$tool_path/$1" ${@:2}
  fi
}

alias adb="_android adb.exe"
alias fastboot="_android fastboot.exe"

# Allow fast editing of this file
alias zert="nano ~/.zshrc.wsl.zsh && source ~/.zshrc.wsl.zsh"