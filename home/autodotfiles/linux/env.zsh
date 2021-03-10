#
# This file is run during startup on Linux platforms only
# Its role is to configure all required environment variables and options
#

# Set up path to main directories
export HOMEDIR="$HOME"
export TEMPDIR="/tmp"
export TRASHDIR="$HOMEDIR/.trasher"
export DLDIR="$HOMEDIR/Downloads"
export SOFTWAREDIR="$HOMEDIR/Logiciels"
export PROJDIR="$HOMEDIR/Projets"
export WORKDIR="$HOMEDIR/Work"
export LOCBAKDIR="$HOMEDIR/Sauvegardes/ADF"

# Set up opening function
function open() {
    echoc "Opening is not currently supported"
    false
}
