#
# This file is run during startup on WSL platform only
# Its role is to configure all required environment variables and options
#

# Get Windows username (cached for better performance)
export ADF_WSL_USERNAME_CACHE_FILE="$ADF_THISCOMP_DIR/.wsl-username"

if [[ ! -f "$ADF_WSL_USERNAME_CACHE_FILE" ]]; then
  export WINUSER=$(powershell.exe -command '$env:UserName' | tr -d "\r")
  printf "$WINUSER" > "$ADF_WSL_USERNAME_CACHE_FILE"
else
  export WINUSER=$(command cat "$ADF_WSL_USERNAME_CACHE_FILE")
fi

# Fail if username couldn't be get
if [[ -z "$WINUSER" ]]
then
  echoerr "Failed to get username from command-line (see error above)"
  return
fi

# Set up path to main directories
export HOMEDIR="/mnt/c/Users/$WINUSER"
export TEMPDIR="$HOME/.tempdata"
export DLDIR="$HOMEDIR/Downloads"
export SOFTWAREDIR="$HOMEDIR/Logiciels"
export LOCBAKDIR="$HOMEDIR/Sauvegardes/ADF"

if [[ $ADF_CONF_PROJECT_DIRS_IN_WSL_FS != 1 ]]; then
  export PROJDIR="$HOMEDIR/Projets"
  export WORKDIR="$HOMEDIR/Work"
  export TRASHDIR="$HOMEDIR/.trasher"
else
  export PROJDIR="$HOME/Projets"
  export WORKDIR="$HOME/Work"
  export TRASHDIR="$HOME/.trasher"
fi

# Open a file or directory in Windows
function open() {
  local topath="$1"

  if [[ -z "$topath" ]]; then
    local topath=$(pwd)
  fi

  if [[ ! -f "$topath" && ! -d "$topath" && ! -L "$topath" ]]; then
    echoerr "target path \z[yellow]°$topath\z[]° was not found!"
    return 1
  fi

  local current_dir=$(pwd)
  local file_dir_path=$(dirname "$topath")
  local file_name=$(basename "$topath")

  cd "$file_dir_path"
  explorer.exe "$file_name"
  cd "$current_dir"
}