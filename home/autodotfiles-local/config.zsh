#
# This file is run during startup on all platforms and is not overriden during updates
# Its role is to declare all the configuration used by other ZSH files
#

# Edit this file and reload it
alias zerc="nano ${(%):-%x} && source ${(%):-%x}"

# NOTE: All configuration variables start with 'ADF_CONF_'

# Is this my main computer?
#export ADF_CONF_MAIN_PERSONAL_COMPUTER=1

# Should WSL projects be put in WSL's filesystem?
#export ADF_CONF_PROJECT_DIRS_IN_WSL_FS=1
