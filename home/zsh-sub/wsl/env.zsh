#
# This file is run during startup on WSL platform only
# Its role is to configure all required environment variables and options
#

# Get Windows username
export WINUSER=$(powershell.exe -command '$env:UserName' | tr -d "\r")

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