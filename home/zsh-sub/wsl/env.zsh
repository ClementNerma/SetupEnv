#
# This file is run during startup on WSL platform only
# Its role is to configure all required environment variables and options
#

# Get Windows username
export WINUSER=$(powershell.exe -command '$env:UserName' | tr -d "\r")

# Fail if username couldn't be get
if [[ -z "$WINUSER" ]]
then
  echoerr "Failed to get username from command-line (see error above)"
  return
fi

# Set up path to main directories
export HOMEDIR="/mnt/c/Users/$WINUSER"
export TEMPDIR="/mnt/c/Temp/__wsltemp"
export DLDIR="$HOMEDIR/Downloads"
export SOFTWAREDIR="$HOMEDIR/Logiciels"

if [[ $PROJECT_DIRS_IN_WSL_FS != 1 ]]; then
  export PROJDIR="$HOMEDIR/Projets"
  export WORKDIR="$HOMEDIR/Work"
  export TRASHDIR="$HOMEDIR/.trasher"
else
  export PROJDIR="/home/$USER/Projets"
  export WORKDIR="/home/$USER/Work"
  export TRASHDIR="/home/$USER/.trasher"
fi
