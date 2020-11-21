#
# This file is a run during shell startup only on WSL
# Its role is to setup aliases and make the environment ready to go
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

# Get IP of host Windows system (can be used to access its ports)
export WSL_HOST_IP=$(awk '/nameserver/ { print $2 }' /etc/resolv.conf)

# Integration of some Windows tools
function code() {
  if [[ -z "$1" ]]; then
    code
  else
    local from=$(pwd)
    cd "$1"
    win code .
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

# Run *some* Git commands from Windows
alias ga="git.exe add"
alias gb="git.exe checkout -b"
alias gd="git.exe diff"
alias gms="git commit -m" # For signing commits, from WSL
alias gs="git.exe status"
alias gr="git.exe reset"
alias gc="git.exe checkout"
alias gm="git.exe commit -m"

# Run Node.js tools from Windows
winalias volta node npm yarn pnpm ts-node

# Run Rust tools from Windows
alias cargo="cargo.exe" # Faster
winalias rustup rustc mdbook

# Mount storage devices on startup (this typically takes 50~100 ms)
mount_wsl_drives
