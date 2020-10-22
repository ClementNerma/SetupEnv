#
# This file contains the configuration used by all other ZSH files
# It is overriden by updates, so this configuration should be overriden in .zshrc.this.zsh instead
#

# Is this my main computer?
# Set to '1' if it is
export ZSH_MAIN_PERSONAL_COMPUTER=0

# Should the project directories be put in WSL's filesystem?
# Set to '1' if yes
export PROJECT_DIRS_IN_WSL_FS=0

# Allow fast editing of this file
alias zerc="nano ${(%):-%x} && source ${(%):-%x}"