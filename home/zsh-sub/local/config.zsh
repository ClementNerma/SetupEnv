#
# This file is run during startup on all platforms and is not overriden during updates
# Its role is to declare all the configuration used by other ZSH files
#

# Edit this file and reload it
alias zerc="nano ${(%):-%x} && source ${(%):-%x}"

# Is this my main computer?
# Set to '1' if it is
#export ZSH_MAIN_PERSONAL_COMPUTER=0