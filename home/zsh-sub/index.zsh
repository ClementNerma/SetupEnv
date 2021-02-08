#
# This file is the main loader of SetupEnv
# It is loaded during the execution of ~/.zshrc
# The goal is to use a separate file for custom definitions and thus be able to reload just that, instead of
#  reloading the whole configuration each time ; as well as to keep the ~/.zshrc file as clean and simple as possible.
#

# Determine if current environment is WSL
if grep -q microsoft /proc/version; then
	command rm -rf "$ZSH_SUB_DIR/linux"
	export IS_WSL_ENV=1
	export ENV_NAME_STR="wsl"
else
	command rm -rf "$ZSH_SUB_DIR/wsl"
	export IS_WSL_ENV=0
	export ENV_NAME_STR="linux"
fi

if [[ -f "$HOME/.setupenv-just-installed" ]]; then
	export SETUPENV_JUST_INSTALLED=1
	rm "$HOME/.setupenv-just-installed"
else
	export SETUPENV_JUST_INSTALLED=0
fi

# Set path to SetupEnv files
export ZSH_SUB_DIR=$(dirname "${(%):-%x}")

# Set path to data directory
export ZSH_DATA_DIR="$ZSH_SUB_DIR/local/data"

# Set path to the files list
export ZSH_FILES_LIST="$HOME/.setupenv-files-list.txt"

# Ensure this directory exists
mkdir -p "$ZSH_DATA_DIR"

# Load the default configuration file
source "$ZSH_SUB_DIR/config.zsh"

# Load the local configuration file
source "$ZSH_SUB_DIR/local/config.zsh"

# Load common utilities usable by the installer
source "$ZSH_SUB_DIR/preutils.zsh"

# Load the updater
source "$ZSH_SUB_DIR/updater.zsh"

# Ensure the restoration script is in place
if [[ ! -f "$SETUPENV_RESTORATION_SCRIPT" || $SETUPENV_JUST_INSTALLED = 1 ]]; then
	zerupdate_restoration_script
fi

# Set path to the installer
export ZSH_INSTALLER_DIR="$ZSH_SUB_DIR/installer"

# Run the installer
export ZSH_INSTALLER_ABORTED=0
source "$ZSH_INSTALLER_DIR/index.zsh"

# Exit if the installer aborted
if [[ $ZSH_INSTALLER_ABORTED = 1 ]]; then
	return
fi

# Load platform-specific configuration
source "$ZSH_SUB_DIR/$ENV_NAME_STR/env.zsh"

# Load the local configuration
source "$ZSH_SUB_DIR/local/env.zsh"

# Allow fast reloading of this file after changes
alias reload="source ${(%):-%x}"

# Load the script for the main computer (if applies)
if [ $ZSH_MAIN_PERSONAL_COMPUTER = 1 ]; then
	source "$ZSH_SUB_DIR/main-pc.zsh"
fi

# Ensure main directories are defined
if [[ -z $HOMEDIR ]]; then echoerr "Directory variable \e[92m\$HOMEDIR\e[91m is not defined!"; fi
if [[ ! -z "$HOMEDIR" && ! -d "$HOMEDIR" ]]; then echoerr "Home directory at location \e[93m$HOMEDIR\e[91m does not exist!"; fi

if [[ -z $TEMPDIR ]]; then echoerr "Directory variable \e[92m\$TEMPDIR\e[91m is not defined!"; fi
if [[ -z $TRASHDIR ]]; then echoerr "Directory variable \e[92m\$TRASHDIR\e[91m is not defined!"; fi
if [[ -z $DLDIR ]]; then echoerr "Directory variable \e[92m\$DLDIR\e[91m is not defined!"; fi
if [[ -z $SOFTWAREDIR ]]; then echoerr "Directory variable \e[92m\$SOFTWAREDIR\e[91m is not defined!"; fi
if [[ -z $PROJDIR ]]; then echoerr "Directory variable \e[92m\$PROJDIR\e[91m is not defined!"; fi
if [[ -z $WORKDIR ]]; then echoerr "Directory variable \e[92m\$WORKDIR\e[91m is not defined!"; fi

if [[ -z $HOMEDIR || ! -d $HOMEDIR || -z $DLDIR || -z $PROJDIR || -z $WORKDIR || -z $TEMPDIR || -z $SOFTWAREDIR || -z $TRASHDIR ]]; then
	read "?Press <Enter> to exit, or <Ctrl+C> to get a without-setupenv ZSH prompt ('zerupdate' command will be available) "
	exit
fi

# Ensure these directories exist
if [[ ! -d $TEMPDIR ]]; then mkdir -p "$TEMPDIR"; fi
if [[ ! -d $DLDIR ]]; then mkdir -p "$DLDIR"; fi
if [[ ! -d $TRASHDIR ]]; then mkdir -p "$TRASHDIR"; fi
if [[ ! -d $PROJDIR ]]; then mkdir -p "$PROJDIR"; fi
if [[ ! -d $WORKDIR ]]; then mkdir -p "$WORKDIR"; fi
if [[ ! -d $SOFTWAREDIR ]]; then mkdir -p "$SOFTWAREDIR"; fi

# Ensure the 'open' function is defined
if ! typeset -f open > /dev/null; then echoinfo "WARNING: 'open' command is not defined. 'open'-related functions won't work correctly."; fi

# Load software configuration and aliases
source "$ZSH_SUB_DIR/config-aliases.zsh"

# Load functions
source "$ZSH_SUB_DIR/functions.zsh"

# Dir hashes
hash -d Home=$HOMEDIR
hash -d Projects=$PROJDIR
hash -d Work=$WORKDIR
hash -d Downloads=$DLDIR
hash -d Temp=$TEMPDIR
hash -d Software=$SOFTWAREDIR

# Go to the a specific folder on startup, except if the shell has been started in a custom directory
if [[ $DISABLE_DIR_HOME_SWITCHING != 1 ]]; then
	if [[ "$(pwd)" = "$HOME" || "$(pwd)" = "$HOMEDIR" ]]; then
		if [ $ZSH_MAIN_PERSONAL_COMPUTER = 1 ]; then
			goproj
		else
			godl
		fi
	fi
fi

# Load platform-specific scripts
source "$ZSH_SUB_DIR/$ENV_NAME_STR/script.zsh"

# Filter the commands to put in the history
function zshaddhistory() {
  emulate -L zsh
  if ! [[ "$1" == "open"* ]] ; then
      print -sr -- "${1%%$'\n'}"
      fc -p
  else
      return 1
  fi
}

# Load the local script
source "$ZSH_SUB_DIR/local/script.zsh"
