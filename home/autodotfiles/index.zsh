#
# This file is the main loader of AutoDotFiles
# It is loaded during the execution of ~/.zshrc
# The goal is to use a separate file for custom definitions and thus be able to reload just that, instead of
#  reloading the whole configuration each time ; as well as to keep the ~/.zshrc file as clean and simple as possible.
#

# Determine if current environment is WSL
if grep -q microsoft /proc/version; then
	command rm -rf "$ADF_DIR/linux"
	export IS_WSL_ENV=1
	export ENV_NAME_STR="wsl"
else
	command rm -rf "$ADF_DIR/wsl"
	export IS_WSL_ENV=0
	export ENV_NAME_STR="linux"
fi

if [[ -f "$HOME/.autodotfiles-just-installed" ]]; then
	export ADF_JUST_INSTALLED=1
	command rm "$HOME/.autodotfiles-just-installed"
else
	export ADF_JUST_INSTALLED=0
fi

# Set path to the main script of AutoDotFiles
export ADF_ENTRYPOINT="${(%):-%x}"

# Set path to AutoDotFiles files
export ADF_DIR=$(dirname "$ADF_ENTRYPOINT")

# Set path to local directory
export ADF_LOCAL_DIR="$ADF_DIR-local"

# Set path to data directory
export ADF_DATA_DIR="$ADF_LOCAL_DIR/data"

# Set path to binaries directory
export ADF_BIN_DIR="$ADF_DATA_DIR/binaries"

# Create base directories
if [[ ! -d "$ADF_DATA_DIR" ]]; then mkdir "$ADF_DATA_DIR"; fi
if [[ ! -d "$ADF_BIN_DIR" ]]; then mkdir "$ADF_BIN_DIR"; fi

# Set path to the files list
export ADF_FILES_LIST="$HOME/.autodotfiles-files-list.txt"

# Ensure this directory exists
mkdir -p "$ADF_DATA_DIR"

# Load the default configuration file
source "$ADF_DIR/config.zsh"

# Load the local configuration file
source "$ADF_LOCAL_DIR/config.zsh"

# Load display functions
source "$ADF_DIR/display.zsh"

# Load common utilities usable by the installer
source "$ADF_DIR/preutils.zsh"

# Load the updater
source "$ADF_DIR/updater.zsh"

# Ensure the restoration script is in place
if [[ ! -f "$ADF_CONF_RESTORATION_SCRIPT" || $ADF_JUST_INSTALLED = 1 ]]; then
	zerupdate_restoration_script
fi

# Load the backuper
source "$ADF_DIR/backuper.zsh"

# Load the obfuscator
source "$ADF_DIR/obfuscator.zsh"

# Set path to the installer
export ADF_INSTALLER_DIR="$ADF_DIR/installer"

# Run the installer
export ADF_INSTALLER_ABORTED=0
source "$ADF_INSTALLER_DIR/index.zsh"

# Exit if the installer aborted
if [[ $ADF_INSTALLER_ABORTED = 1 ]]; then
	return
fi

# Register the local binaries directory in PATH
export PATH="$ADF_BIN_DIR:$PATH"

# Load platform-specific configuration
source "$ADF_DIR/$ENV_NAME_STR/env.zsh"

# Load the local configuration
source "$ADF_LOCAL_DIR/env.zsh"

# Allow fast reloading of this file after changes
alias reload="source ${(%):-%x}"

# Load the script for the main computer (if applies)
if [ $ADF_CONF_MAIN_PERSONAL_COMPUTER = 1 ]; then
	source "$ADF_DIR/main-pc.zsh"
fi

# Ensure main directories are defined
if [[ -z $HOMEDIR ]]; then echoerr "Directory variable \z[green]°\$HOMEDIR\z[]° is not defined!"; fi
if [[ ! -z "$HOMEDIR" && ! -d "$HOMEDIR" ]]; then echoerr "Home directory at location \z[yellow]°$HOMEDIR\z[]° does not exist!"; fi
if [[ -z $TEMPDIR ]]; then echoerr "Directory variable \z[green]°\$TEMPDIR\z[]° is not defined!"; fi
if [[ -z $TRASHDIR ]]; then echoerr "Directory variable \z[green]°\$TRASHDIR\z[]° is not defined!"; fi
if [[ -z $DLDIR ]]; then echoerr "Directory variable \z[green]°\$DLDIR\z[]° is not defined!"; fi
if [[ -z $SOFTWAREDIR ]]; then echoerr "Directory variable \z[green]°\$SOFTWAREDIR\z[]° is not defined!"; fi
if [[ -z $PROJDIR ]]; then echoerr "Directory variable \z[green]°\$PROJDIR\z[]° is not defined!"; fi
if [[ -z $WORKDIR ]]; then echoerr "Directory variable \z[green]°\$WORKDIR\z[]° is not defined!"; fi
if [[ -z $LOCBAKDIR ]]; then echoerr "Directory variable \z[green]°\$LOCBAKDIR\z[]° is not defined!"; fi

if [[ -z $HOMEDIR || ! -d $HOMEDIR || -z $DLDIR || -z $PROJDIR || -z $WORKDIR || -z $TEMPDIR || -z $SOFTWAREDIR || -z $TRASHDIR || -z $LOCBAKDIR ]]; then
	read "?Press <Enter> to exit, or <Ctrl+C> to get a without-AutoDotFiles ZSH prompt ('zerupdate' command will be available) "
	exit
fi

# Ensure these directories exist
if [[ ! -d $TEMPDIR ]]; then mkdir -p "$TEMPDIR"; fi
if [[ ! -d $DLDIR ]]; then mkdir -p "$DLDIR"; fi
if [[ ! -d $TRASHDIR ]]; then mkdir -p "$TRASHDIR"; fi
if [[ ! -d $PROJDIR ]]; then mkdir -p "$PROJDIR"; fi
if [[ ! -d $WORKDIR ]]; then mkdir -p "$WORKDIR"; fi
if [[ ! -d $SOFTWAREDIR ]]; then mkdir -p "$SOFTWAREDIR"; fi
if [[ ! -d $LOCBAKDIR ]]; then mkdir -p "$LOCBAKDIR"; fi

# Ensure the 'open' function is defined
if ! typeset -f open > /dev/null; then echoinfo "WARNING: 'open' command is not defined. 'open'-related functions won't work correctly."; fi

# Load software configuration and aliases
source "$ADF_DIR/config-aliases.zsh"

# Set path to the functions directory
export ADF_FUNCTIONS_DIR="$ADF_DIR/functions"

# Load functions
source "$ADF_FUNCTIONS_DIR/main.zsh"

# Dir hashes
hash -d Home=$HOMEDIR
hash -d Projects=$PROJDIR
hash -d Work=$WORKDIR
hash -d Downloads=$DLDIR
hash -d Temp=$TEMPDIR
hash -d Software=$SOFTWAREDIR

# Go to the a specific folder on startup, except if the shell has been started in a custom directory
if [[ $ADF_CONF_DISABLE_DIR_HOME_SWITCHING != 1 ]]; then
	if [[ "$(pwd)" = "$HOME" || "$(pwd)" = "$HOMEDIR" ]]; then
		if [ $ADF_CONF_MAIN_PERSONAL_COMPUTER = 1 ]; then
			goproj
		else
			godl
		fi
	fi
fi

# Load platform-specific scripts
source "$ADF_DIR/$ENV_NAME_STR/script.zsh"

# Filter the commands to put in the history
function zshaddhistory() {
  emulate -L zsh
  if ! [[ "$1" == "open"* || "$1" == "z "* ]] ; then
      print -sr -- "${1%%$'\n'}"
      fc -p
  else
      return 1
  fi
}

# Load the local script
source "$ADF_LOCAL_DIR/script.zsh"
