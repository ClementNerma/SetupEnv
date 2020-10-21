#!/usr/bin/zsh

#
# This file is a script run during shell startup only on WSL
#

# Run a Windows command through PowerShell
# e.g. "win echo Hello!" will display "Hello!" by running PowerShell transparently
function win() {
  powershell.exe -command "$@"
}

# Run a Windows command through CMD.EXE
function wincmd() {
  cmd.exe /C "$@"
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

# Get Windows username
export WINUSER=$(win2text '$env:UserName')

# Set up path to main directories
export HOMEDIR="/mnt/c/Users/$WINUSER"
export TEMPDIR="/mnt/c/Temp/__wsltemp"
export DLDIR="$HOMEDIR/Downloads"
export SOFTWAREDIR="$HOMEDIR/$USER/Logiciels"

if [[ $PROJECT_DIRS_IN_WSL_FS != 1 ]]; then
  export PROJDIR="$HOMEDIR/Projets"
  export WORKDIR="$HOMEDIR/Work"
  export TRASHDIR="$HOMEDIR/.trasher"

else
  export PROJDIR="/home/$USER/Projets"
  export WORKDIR="/home/$USER/Work"
  export TRASHDIR="/home/$USER/.trasher"

  # Check if projects directory are available from Windows
  # Arguments: _checkdir <variable name> <display name> <wsl directory name> <symlink name>
  _checkdir() {
    export $1="$HOMEDIR/$4"

    if [[ ! -L "$HOMEDIR/$4" ]]; then
      echo -e "\e[93mNOTICE: Windows $2 Projects directory was not found in user directory under name \e[95m$4\e[93m."
      _twsccl+=("\e[94mmklink /D \"C:\\\\Users\\\\$WINUSER\\\\_$4WSLSymlink\" \"\\\\\\\\wsl$\\Debian\\\\home\\\\$USER\\\\$3\"\e[0m")
      _twsccl+=("\e[94mmklink /J /D \"C:\\\\Users\\\\$WINUSER\\\\$4\" \"C:\\\\Users\\\\$WINUSER\\\\_$4WSLSymlink\"\e[0m")
    fi
  }

  # Temporary Windows Symlinks Creation Commands List
  _twsccl=()

  _checkdir WIN_PROJDIR Home Projets Projets
  _checkdir WIN_PROJDIR Work Work Work

  if [ ${#_twsccl[@]} -ne 0 ]; then
    echo ""
    echo -e "\e[93mTo create missing directories, run the following commands in \e[95mCMD.EXE\e[93m:"
    echo ""

    for value in ${_twsccl[@]}; do
      echo $value
    done

    echo ""
  fi
fi

# Ensure temporary directory exists
if [ ! -d "$TEMPDIR" ]; then
  mkdir -p "$TEMPDIR"
fi

# Get IP of host Windows system (can be used to access its ports)
export WSL_HOST_IP=$(awk '/nameserver/ { print $2 }' /etc/resolv.conf)

# Go to windows' home directory
alias gowin="cd $HOMEDIR"

# Integration of some Windows tools
function code() {
  if [[ -z "$1" ]]; then
    code
  else
    local from=$(pwd)
    cd "$1"
    code .
    cd "$from"
  fi
}

# Mount drives in WSL, including removable ones
function mount_wsl_drives() {
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
function open() {
  local topath="$1"

  if [[ -z "$topath" ]]; then
    local topath=$(pwd)
  fi

  if [[ ! -f "$topath" && ! -d "$topath" && ! -L "$topath" ]]; then
    echo -e "\e[91mERROR: target path \e[93m$topath\e[91m was not found!\e[0m"
    return
  fi

  # Convert path to display symlink path in Windows Explorer, unless disabled explicitly
  if [[ $PROJECT_DIRS_IN_WSL_FS = 1 && -z "$2" ]]; then
    local topath=$(realpath "$topath")
    local origtopath="$topath"

    if [[ $topath = "/home/$USER/Projets/Home" ]]; then
      explorer.exe "C:\\Users\\${WINUSER}\\Projets"
      return
    fi

    if [[ $topath = "/home/$USER/Projets/Work" ]]; then
      explorer.exe "C:\\Users\\${WINUSER}\\Work"
      return
    fi

    local topath="${topath/\/home\/$USER\/Projets\/Home\//C:\\Users\\${WINUSER}\\Projets\\}"
    local topath="${topath/\/home\/$USER\/Projets\/Work\//C:\\Users\\${WINUSER}\\Work\\}"

    if [[ "$topath" != "$origtopath" ]]; then
      explorer.exe "${topath/\//\\}"
      return
    fi
  fi

  local current_dir=$(pwd)
  local file_dir_path=$(dirname "$topath")
  local file_name=$(basename "$topath")

  cd "$file_dir_path"
  explorer.exe "$file_name"
  cd "$current_dir"
}

# Link a WSL port with a Windows port
function wslport() {
  if [[ -z "$1" ]]; then
    echo -e "\e[91mERROR: please specify a port (syntax: wslport <wsl port> [<windows port>]\e[0m"
    return
  fi

  if [[ ! -z "$2" ]]; then
    local linked="$2"
  else
    local linked="$1"
  fi

  win "Start-Process powershell -ArgumentList '-Command netsh interface portproxy add v4tov4 listenport=$linked listenaddress=0.0.0.0 connectport=$1 connectaddress=172.18.28.x ; pause' -Verb RunAs"
}

# Copy a file to clipboard
function clip() {
  cat "$1" | clip.exe
}

# Run Git from Windows...
alias git="git.exe"

# ...except Git Push, to avoid problems with Git Credentials Manager
alias gp="command git push"
alias gpf="command git push --force-with-lease"

# ...as well as Git Diff, to avoid problems with the terminal itself
alias gd="command git diff"

# Run Node.js tools from Windows
winalias node npm yarn pnpm ts-node

# Run Rust tools from Windows
winalias rustup rustc cargo

# Mount storage devices on startup (this typically takes 50~100 ms)
mount_wsl_drives

# Allow fast editing of this file
alias zert="nano ~/.zshrc.wsl.zsh && source ~/.zshrc.wsl.zsh"