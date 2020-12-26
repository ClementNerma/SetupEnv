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
else
	command rm -rf "$ZSH_SUB_DIR/wsl"
	export IS_WSL_ENV=0
fi

# Set path to SetupEnv files
export ZSH_SUB_DIR=$(dirname "${(%):-%x}")

# Set path to data directory
export ZSH_DATA_DIR="$ZSH_SUB_DIR/local/data"

# Ensure this directory exists
mkdir -p "$ZSH_DATA_DIR"

# Load the configuration file
source "$ZSH_SUB_DIR/config.zsh"

# Set path to the installer
export ZSH_INSTALLER_DIR="$ZSH_SUB_DIR/installer"

# Load the installer
export ZSH_INSTALLER_ABORTED=0

source "$ZSH_INSTALLER_DIR/index.zsh"

if [[ $ZSH_INSTALLER_ABORTED = 1 ]]; then
	return
fi

# Allow fast reloading of this file after changes
alias reload="source ${(%):-%x}"

# Allow fast editing of this file, with automatic reloading
alias zer="nano ${(%):-%x} && reload"

# Load platform-specific configuration
if [[ $IS_WSL_ENV = 1 ]]; then
	source "$ZSH_SUB_DIR/wsl/env.zsh"
else
	source "$ZSH_SUB_DIR/linux/env.zsh"
fi

# Load the local configuration
source "$ZSH_SUB_DIR/local/env.zsh"

# Load the updater
source "$ZSH_SUB_DIR/updater.zsh"

# Load the script for the main computer (if applies)
if [ $ZSH_MAIN_PERSONAL_COMPUTER = 1 ]; then
	source "$ZSH_SUB_DIR/main-pc.zsh"
fi

# Ensure main directories are defined
if [[ -z $HOMEDIR ]]; then echo -e "\e[91mERROR: Directory variable \e[92m\$HOMEDIR\e[91m is not defined!\e[0m"; fi
if [[ ! -z "$HOMEDIR" && ! -d "$HOMEDIR" ]]; then echo -e "\e[91mERROR: Home directory at location \e[93m$HOMEDIR\e[91m does not exist!\e[0m"; fi

if [[ -z $TEMPDIR ]]; then echo -e "\e[91mERROR: Directory variable \e[92m\$TEMPDIR\e[91m is not defined!\e[0m"; fi
if [[ -z $TRASHDIR ]]; then echo -e "\e[91mERROR: Directory variable \e[92m\$TRASHDIR\e[91m is not defined!\e[0m"; fi
if [[ -z $DLDIR ]]; then echo -e "\e[91mERROR: Directory variable \e[92m\$DLDIR\e[91m is not defined!\e[0m"; fi
if [[ -z $SOFTWAREDIR ]]; then echo -e "\e[91mERROR: Directory variable \e[92m\$SOFTWAREDIR\e[91m is not defined!\e[0m"; fi
if [[ -z $PROJDIR ]]; then echo -e "\e[91mERROR: Directory variable \e[92m\$PROJDIR\e[91m is not defined!\e[0m"; fi
if [[ -z $WORKDIR ]]; then echo -e "\e[91mERROR: Directory variable \e[92m\$WORKDIR\e[91m is not defined!\e[0m"; fi

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

# Load functions and aliases
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
if [[ $IS_WSL_ENV = 1 ]]; then
	source "$ZSH_SUB_DIR/wsl/script.zsh"
else
	source "$ZSH_SUB_DIR/linux/script.zsh"
fi

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