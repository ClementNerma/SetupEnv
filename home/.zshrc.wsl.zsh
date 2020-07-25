#!/usr/bin/zsh

# Run a Windows command through PowerShell
# e.g. "win echo Hello!" will display "Hello!" by running PowerShell transparently
function win() {
  powershell.exe -command "$@"
}

# Run a Windows command through PowerShell and use its content in WSL
# This uses "tr" because Window's newline symbols are different than Linux's ones, thus resulting in weird string behaviours
function win2text() {
  win "$@" | tr -d "\r"
}

# Run a Windows command through CMD.EXE and use its content in WSL
# This uses "tr" because Window's newline symbols are different than Linux's ones, thus resulting in weird string behaviours
function wincmd2text() {
  cmd.exe /C "$@" | tr -d "\r"
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
  zsh TEMPLATE_INIT.zsh
  rm TEMPLATE_INIT.zsh
}

# Run a Cargo project located in the projects directory, on Windows
function cargextw() {
	win cargo run "--manifest-path=C:\\Users\\cleme\\Projets\\$1\\Cargo.toml" -- ${@:2}
}

# Run a Cargo project located in the projects directory in release mode, on Windows
function cargextwr() {
	win cargo run "--manifest-path=C:\\Users\\cleme\\Projets\\$1\\Cargo.toml" --release -- ${@:2}
}

# Remount a drive in WSL
function remount() {
	sudo umount /mnt/${1:l} 2> /dev/null
	sudo mkdir /mnt/${1:l} 2> /dev/null
	sudo mount -t drvfs "${1:u}:" /mnt/${1:l}
}

# Backup
function backupy() {
  local backupy_path="$PROJDIR/_Done/Backupy/backupy.bash"

	if [[ ! -f "$backupy_path" ]]; then
		echo -e "\e[91mERROR: Could not find \e[92mBackupy\e[91m files at path \e[93m$backupy_path\e[0m"
		return
	fi

	bash "$backupy_path" $@
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

# Get IP of host Windows system (can be used to access its ports)
export WSL_HOST_IP=$(awk '/nameserver/ { print $2 }' /etc/resolv.conf)

# Go to windows' home directory
alias gowin="cd $HOMEDIR"

# Integration of some Windows tools
winalias code

# Mount drives in WSL, including removable ones
mount_wsl_drives() {
  local found_c=0
  local init_cwd="$(pwd)"

  # Go to a path CMD.EXE can access to avoid errors
  cd /mnt/c

  for drive in /mnt/*
  do
    local letter=${drive:s/\/mnt\//}
    local chrlen=${#letter}

    if [[ $chrlen == 1 ]]; then
      local drive_status="$(wincmd2text "vol ${letter}: >nul 2>nul & if errorlevel 1 (echo|set /p=NOPE) else (echo|set /p=OK)")"

      if [[ $letter == "c" ]]; then
        found_c=1
      elif mountpoint -q "/mnt/$letter"; then
        if [[ $1 == "--debug" ]]; then
          echo Already mounted: $letter
        fi
      elif [[ $drive_status == "OK" ]]; then
        if [[ $1 == "--debug" ]]; then
          echo Mounting: $letter
        fi

        remount "$letter"
      elif [[ $drive_status != "NOPE" ]]; then
        echo -e "\e[91mAssertion error: drive status command for \e[95m${letter:u}: \e[91mdrive returned an invalid content: \e[95m$drive_status\e[91m (${#drive_status} characters)\e[0m"
      elif [[ $1 == "--debug" ]]; then
        echo Ignoring: $letter
      fi
    fi
  done

  if [[ $c == 0 ]]; then
    echo -e "\e[91mAssertion error: \e[95mC:\e[91m drive was not found while mounting WSL drives!\e[0m"
  fi

  cd "$init_cwd"
}

# Open a file or directory in Windows
open() {
  # By default, open the current directory
  if [[ -z "$1" ]]; then
    explorer.exe .

  # Directories are opened through Windows' Explorer
  elif [[ -d "$1" ]]; then
    local current_dir=$(pwd)

    cd "$1"
    explorer.exe .
    cd "$current_dir"

  # Files are handled by the Windows File Association system
  elif [[ -f "$1" ]]; then
    local current_dir=$(pwd)
    local file_dir_path=$(dirname "$1")
    local file_name=$(basename "$1")

    cd "$file_dir_path"
    explorer.exe "$file_name"
    cd "$current_dir"

  # Handle non-existant paths
  else
    echo -e "\e[91mERROR: target path \e[93m$1\e[0m was not found!\e[0m"
  fi
}

# Copy a file to clipboard
clip() {
  cat "$1" | clip.exe
}

# Software: Android's Platform Tools
function _android() {
  local tool_path="$SFWDIR/PlatformTools"

  if [[ ! -f "$tool_path/$1" ]]; then
    echo -e "\e[91mERROR: Could not find Platform Tools binary \e[93m$1\e[91m at path \e[93m$tool_path\e[0m"
    return
  fi

  "$tool_path/$1" ${@:2}
}

alias adb="_android adb.exe"
alias fastboot="_android fastboot.exe"

# Mount storage devices on startup (this typically takes 50~100 ms)
mount_wsl_drives

# Allow fast editing of this file
alias zert="nano ~/.zshrc.wsl.zsh && source ~/.zshrc.wsl.zsh"